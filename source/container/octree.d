module container.octree;

import math.matrix;
import math.geo.frustum;
import math.geo.AABox;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.range;
import std.traits;
import container.clist;

// Use free list to avoid reallocating nodes alot
private enum useFreeList = true;

/**
 * A simple ref-counted Loose Octree
 * The octree is fixed size on the scale -1 to 1
 * All incomeing sizes and locations must then be scaled down
 * this just simplifies things a bit, the user of the octree can worry about their bounds
 *
 * Also as an optimization, we store unused nodes into a free list to minimize allocations
 * Helps alot because octrees shift nodes around alot when things move
 */
struct Octree(T, uint MaxDepth, A=Mallocator, bool GC_SCAN=true) {
	static assert(MaxDepth != 0, "Depth must be grater than 0");
	private alias CL = CList!(ListValue, A, GC_SCAN);

	alias DATA_T = T;

	private struct octree_data
	{ 
		private Node* head     = null;
		private uint ref_count = 1;
		private uint nodeCount = 0;

		static if(useFreeList) {
			private Node* freeList = null;
		}
	}

	struct ListValue {
		T data;
		vec3 center;
		vec3 size;

		// Used for the ranges, when you make one of the ranges it iterates and constructs a simple linked list of the results
		private ListValue* next; 
	}

	struct Node
	{
		Node* parent = null;
		Node*[8] children;
		CL list;
		float size; // Dont need a full vec3, all nodes are cubes
		vec3 center;
	}

	/// Can be used to move/reagange/remove items in the tree
	struct ItemRef
	{
		private Node* cell;
		private CL.Node* listNode;
		ref ListValue data() @property 
		{
			pragma(inline, true);
			return listNode.data;
		}
	}


	static if(__traits(compiles, () { alias a = A.instance; })) {
		alias alloc = A.instance;
	} else {
		A alloc; // Will need to be set manually before anything is allocated
	}

	private octree_data* list;

	this(this) {
		if(list != null) list.ref_count ++;
	}

	~this() {
		deInit();
	}

	void opAssign(typeof(null) n) {
		deInit();
	}

	bool opEquals(typeof(null) rhs) {
		return list == null || list.nodeCount == 0;
	}

	bool opEquals(Octree!(T,MaxDepth,A,GC_SCAN) rhs) {
		return this.list == rhs.list;
	}

	void clear() {
		if(list == null) return;
		recClear(list.head);
	}

	private void recClear(ref Node* root) {
		if(root == null) return;
		foreach(ref n; root.children) recClear(n);
		root.list.clear();
		freeNode(root);
		root = null;
	}

	ItemRef insert(T t, vec3 center, vec3 size) {
		auto cell = getNode(center, size);
		ListValue v;
		v.data = t;
		v.center = center;
		v.size = size;
		auto n = cell.list.insert(v);
		return ItemRef(cell, n);
	}

	Node* getHead() {
		pragma(inline, true); // simple getters should always be inlined
		if(list != null) return list.head;
		else return null;
	}

	void removeItem(ItemRef item) {
		auto node = item.cell;
		node.list.removeNode(item.listNode);
		cleanUpToTop(node);
	}

	void moveItem(ref ItemRef item, vec3 center, vec3 size) {
		import std.array;
		import std.math:abs;
		auto cell_size = item.cell.size;
		auto norm_loc = 2*(center-item.cell.center)/cell_size;
		if(
			size.x < cell_size && 
			size.y < cell_size && 
			size.z < cell_size &&
			abs(norm_loc.x) <= 1 &&
			abs(norm_loc.y) <= 1 &&
			abs(norm_loc.z) <= 1 
			) {
			// Doesnt need to be moved 
			return;
		}

		auto src = item.cell;
		auto dest = getNode(center, size); // The place we will put the item
		transferNode(src.list, dest.list, item.listNode);
		item.listNode.data.center = center;
		item.listNode.data.size = size;
		item.cell = dest;
		cleanUpToTop(src);
	}




	// Ranges to iterate over subsections of the octree
	private static bool onPoint(vec3 center, vec3 size, vec3 point) {
		if(center == point) return true;
		import std.math : abs;
		point = point - center;
		size = size/2;
		return abs(point.x) < size.x && abs(point.y) < size.y && abs(point.z) < size.z;
	}

	auto ItemsOnPoint(vec3 point) {
		if(list == null) return rangeStruct(null, true);
		ListValue* head = null;
		itemsOnRec!onPoint(head, list.head, point);
		return rangeStruct(head, head == null);
	}

	private static bool onRay(vec3 center, vec3 size, vec3 start, vec3 dir) {
		import math.geo.box_ray_intersect;
		auto sd2 = size/2;
		vec3 hit;
		return Box_Ray_Intersect(center-sd2, center + sd2, start, dir, hit);
	}

	auto ItemsOnRay(vec3 start, vec3 dir) {
		if(list == null) return rangeStruct(null, true);
		ListValue* head = null;
		dir = normalize(dir);
		itemsOnRec!onRay(head, list.head, start, dir);
		return rangeStruct(head, head == null);
	}

	private static bool onSphere(vec3 center, vec3 size, vec3 sphere_center, float r) {
		import math.geo.box_sphere_intersect;
		auto sd2 = size/2;
		return Box_Sphere_Intersect(center-sd2, center+sd2, sphere_center, r);
	}

	auto ItemsOnSpere(vec3 sphere_center, float r) {
		if(list == null) return rangeStruct(null, true);
		ListValue* head = null;
		itemsOnRec!onSphere(head, list.head, sphere_center, r);
		return rangeStruct(head, head == null);
	}

	private static bool onBox(vec3 center, vec3 size, vec3 center2, vec3 size2) {
		auto a_s = size/2;
		auto a_lo = center - a_s;
		auto a_hi = center + a_s;
		auto b_s = size2/2;
		auto b_lo = center2 - b_s;
		auto b_hi = center2 + b_s;
		return 
			a_lo.x < b_hi.x &&
			a_lo.y < b_hi.y &&
			a_lo.z < b_hi.z &&
			a_hi.x > b_lo.x &&
			a_hi.y > b_lo.y &&
			a_hi.z > b_lo.z ;
	}

	auto ItemsOnBox(vec3 center, vec3 size) {
		if(list == null) return rangeStruct(null, true);
		ListValue* head = null;
		itemsOnRec!onBox(head, list.head, center, size);
		return rangeStruct(head, head == null);
	}

	private static bool onFrustum(vec3 center, vec3 size, frustum f, float scale) {
		return f.intersect(AABox(center*scale, size*scale)) <= 0;
	}

	auto ItemsOnFrustum(frustum f, float scale) {
		if(list == null) return rangeStruct(null, true);
		ListValue* head = null;
		itemsOnRec!onFrustum(head, list.head, f, scale);
		return rangeStruct(head, head == null);
	}

	auto ItemsOnFrustumLoose(frustum f, float scale) {
		if(list == null) return rangeStruct(null, true);
		ListValue* head = null;
		itemsOnRec!(onFrustum, false)(head, list.head, f, scale);
		return rangeStruct(head, head == null);
	}






	/**
	 * Clean up the nodes above this one
	 * Call this after an item has been removed from node's list
	 */
	private void cleanUpToTop(Node* node) {
		
		Node* a = node;
		Node* b = null;
		while(a != null) {
			uint c = 0;
			foreach(ref n; a.children) {
				if(n == b) n = null;
				else if(n != null) c++;
			}

			if(a.list.length != 0 || c != 0) return;

			b = a;
			a = b.parent;
			freeNode(b);
			if(list.head == b) list.head = null; // that was an anoying bug... 
		}
	}

	/**
	* Finds/Creates the smallest node that will hold an object with center and size
	* Things centered right in the center of a cell will get placed in the left cell
	* All items in a cell will have a size smaller than the cell size
	* Item centers can go right up to the cell border and actually lie on a cell boarder, as long as its not larger than its cell
	*/
	private Node* getNode(ref vec3 center, ref vec3 size) {
		import std.algorithm;
		if(list == null) init();

		// Assumed that center is on the range -1 to 1, but we will fix it incase its not
		center.x = min(1,max(center.x,-1));
		center.y = min(1,max(center.y,-1));
		center.z = min(1,max(center.z,-1));

		// It is also assumed the size is on the scale 0 to 2, but we will fix it just incase
		size.x = min(2,max(size.x,0));
		size.y = min(2,max(size.y,0));
		size.z = min(2,max(size.z,0));

		if(list.head == null) {
			list.head = makeNode();
			list.head.parent = null;
			list.head.size = 2; // [-1,1] = 2
			list.head.center = vec3(0,0,0);
		}

		return recGetNode(center, size, list.head, 1);
	}

	private Node* recGetNode(vec3 center, vec3 size, Node* root, uint currentDepth) {
		if(size.x >= 1 || size.y >= 1 || size.z >= 1 || currentDepth == MaxDepth) {
			// This is the smallest node that will hold something of size

			// needs to be size >= 1, not size > 1
			// not size > 1 because then an object at the very edge of this cell could rub up against a cell 2 cells away if it was
			// this is a lose octree remeber 
			// the relaxed range of a cell is twice its size so 4, with the size of a cell being 2 (this is all relitive to the current cell)
			// that means that there is a size 1 border around the cell that the object in this cell can extend into while still be ok
			// so an item at the edge of a cell could extend half its size outside the cell
			// half because the center must still be in the cell, not the in the extended range 
			// so an item with size 2 would extend 1 outside if it was on the edge
			// and that means the item would be rubing up to a 3rd cell(we already know the item can rub against 2 because its a loose octree)
			// so size >= 1 to prevent the next rec from getting a size 2
			// 
			// Just wrote this out cus it kinda confused me and this helps...

			return root;
		} else {
			// Need to send it on to a child
			int i = (center.x>0)?1:0; // 0 gets put in left node... 
			int j = (center.y>0)?1:0;
			int k = (center.z>0)?1:0;
			int index = i + j*2 + k*4;
			auto cell = vec3(i*2-1,j*2-1,k*2-1)*0.5f;
			center = (center - cell)*2;

			if(root.children[index] == null) {
				auto c = makeNode();
				c.parent = root;
				c.size = root.size/2;
				c.center = root.center + cell*c.size;
				root.children[index] = c;
			}

			return recGetNode(center, size*2, root.children[index], currentDepth+1);
		}
	}

	/// Range struct to iterate over the the result of serches
	private struct rangeStruct{
		private ListValue* head;
		public bool empty;

		// Forward iteration
		public ListValue* front()	{ return head; }
		public void popFront() { 
			head = head.next;
			if(head == null) empty = true;
		} 

		// Save for forward range
		public auto save() { return this; }
	}

	static assert(isInputRange!rangeStruct);


	// Allocate the parts of the octree
	private void init() {
		list = alloc.make!octree_data();
	}

	private void deInit() {
		if(list == null) return; 

		list.ref_count--;
		if(list.ref_count == 0) {
			clear();

			static if(useFreeList) {
				// Clean up all the nodes in the free list
				Node* h = list.freeList;
				while(h != null) {
					auto temp = h.parent;
					alloc.dispose(h);
					h = temp;
				}
			}

			alloc.dispose(list);
		}
	}

	private auto makeNode() {
		static if(useFreeList) {
			if(list.freeList != null) {
				Node* n = list.freeList;
				list.freeList = n.parent;
				n.parent = null;
				return n;
			}

			Node* n = alloc.make!Node();
			return n;
		} else {
			Node* n = alloc.make!Node();
			return n;
		}
	}

	private void freeNode(Node* n) {
		static if(useFreeList) {
			n.list.clear();
			n.children[]	= null;
			n.parent		= list.freeList;
			list.freeList	= n;
		} else {
			alloc.dispose(n);
		}
	}

}

private void itemsOnRec(alias fun, bool checkItems = true, L, N, ARGS...)(ref L* head, N* root, ARGS args) {
	if(root == null) return;
	if(fun(root.center, vec3(root.size*2), args)) {
		foreach(ref n; root.list[]) {
			static if(checkItems) {
				if(fun(n.center, n.size, args)) {
					// Stick it onto the list
					n.next = head;
					head = &n;
				}
			} else {
				// Stick it onto the list
				n.next = head;
				head = &n;
			}
		}

		foreach(c; root.children) {
			itemsOnRec!(fun, checkItems)(head, c, args);
		}
	}
}

auto ItemsOnPred(alias fun,bool checkItems = true, T, uint MaxDepth, A, bool GC_SCAN, ARGS...)(Octree!(T, MaxDepth, A, GC_SCAN) tree, ARGS args) {
	if(tree.list == null) return tree.rangeStruct(null, true);
	tree.ListValue* head = null;
	itemsOnRec!(fun, checkItems)(head, tree.list.head, args);
	return rangeStruct(head, head == null);
}




import std.traits : isInstanceOf;
void OctreeMap(alias checkFunction, alias findFunction, OCT_T, ARGS...)(OCT_T tree, auto ref ARGS args) 
//if(
//   isInstanceOf!(Octree, OCT_T) && 
//   __traits(compiles, (){
//        vec3 center;
//        vec3 size;
//        OCT_T.DATA_T value;
//        bool b = checkFunction(center, size, args);
//        findFunction(value, args);
//   })
//   ) 
{

	void OctreeMap_rec(NODE)(NODE* root, auto ref ARGS args) {
		if(root == null) return;
		if(checkFunction(root.center, vec3(root.size*2), args)) {
			foreach(ref n; root.list[]) {
				if(checkFunction(n.center, n.size, args)) {
					findFunction(n.data, args);
				}
			}
			foreach(c; root.children) {
				OctreeMap_rec!()(c, args);
			}
		}
	}


	if(tree.list == null) return;
	OctreeMap_rec!()(tree.list.head, args);
}





unittest{
	import std.algorithm;
	Octree!(int,8) tree;

	// Size of the region
	float size = 64;
	size /= 2;

	//void recPrint(tree.Node* root, uint depth = 1)
	//{
	//	if(root == null) return;
	//	writeln("Depth: ", depth);
	//	writeln("\tCenter: \t", root.center*size);
	//	writeln("\tSize: \t", root.size*size);
	//	write("\tData:\t[");
	//	foreach(tree.ListValue i; root.list[]) write(i.data,",");
	//	write("]\n");

	//	foreach(n; root.children) recPrint(n, depth+1);
	//}

	vec4 getCellCenterSize(int i, tree.Node* root) {
		if(root == null) return vec4(-1,-1,-1,-1);
		if(root.list[].map!(a=>a.data).canFind(i)) return (root.center ~ root.size)*size;
		foreach(n; root.children) {
			auto v = getCellCenterSize(i,n);
			if(v != vec4(-1,-1,-1,-1)) return v;
		}

		return vec4(-1,-1,-1,-1);
	}


	auto item1 = tree.insert(1, vec3(5,5,5)/size, vec3(1,1,1)/size);
	auto item2 = tree.insert(2, vec3(10,5,5)/size, vec3(11,1,1)/size);
	auto item3 = tree.insert(3, vec3(5,-3, 5)/size, vec3(1,17,1)/size);
	auto item4 = tree.insert(4, vec3(-9,-9,-9)/size, vec3(1,1,1)/size);
	auto item5 = tree.insert(5, vec3(0,-3,0)/size, vec3(11,1,11)/size);
	auto item6 = tree.insert(-1, vec3(5,20,5)/size, vec3(0,0,0)); // Make sure zero sized inserts work... 

	assert(getCellCenterSize(1, tree.getHead) == vec4(5,5,5,2));
	assert(getCellCenterSize(4, tree.getHead) == vec4(-9,-9,-9,2));

	{
		auto result = tree.ItemsOnPoint(vec3(5,5,5)/size).map!(a => a.data).array;
		assert(result.canFind(1));
		assert(result.canFind(2));
		assert(result.canFind(3));
		assert(result.length == 3); 
	}

	tree.moveItem(item1, vec3(-8,-8,-8)/size, vec3(1,1,1)/size );

	{
		auto result = tree.ItemsOnPoint(vec3(5,5,5)/size).map!(a => a.data).array;
		assert(!result.canFind(1));
		assert(result.canFind(2));
		assert(result.canFind(3));
		assert(result.length == 2); 
	}

	{
		auto result = tree.ItemsOnPoint(vec3(-8,-8,-8)/size).map!(a => a.data).array;
		assert(result.canFind(1));
		assert(result.length == 1); 
	}

	{
		auto result = tree.ItemsOnPoint(vec3(5,20,5)/size).map!(a => a.data).array;
		assert(result.canFind(-1));
		assert(result.length == 1); 
	}
	

	{
		auto result = tree.ItemsOnRay(vec3(5,-10, 5)/size, vec3(0,1,0)).map!(a => a.data).array;
		assert(result.canFind(2));
		assert(result.canFind(3));
		assert(result.canFind(5));
		assert(result.canFind(-1));
		assert(result.length == 4); 
	}

	{
		auto result = tree.ItemsOnSpere(vec3(0,0,0), 10/size).map!(a => a.data).array;
		assert(result.canFind(2));
		assert(result.canFind(3));
		assert(result.canFind(5));
		assert(result.length == 3); 
	}

	{
		auto result = tree.ItemsOnSpere(vec3(5,20,5)/size, 1/size).map!(a => a.data).array;
		assert(result.canFind(-1));
		assert(result.length == 1); 
	}

	{
		auto result = tree.ItemsOnBox(vec3(0,0,0), vec3(41,41,41)/size).map!(a => a.data).array;
		assert(result.canFind(1));
		assert(result.canFind(2));
		assert(result.canFind(3));
		assert(result.canFind(4));
		assert(result.canFind(5));
		assert(result.canFind(-1));
		assert(result.length == 6); 
	}

	{
		auto result = tree.ItemsOnBox(vec3(5,5,5)/size, vec3(1,40,1)/size).map!(a => a.data).array;
		assert(result.canFind(2));
		assert(result.canFind(3));
		assert(result.canFind(5));
		assert(result.canFind(-1));
		assert(result.length == 4); 
	}

	{
		auto result = tree.ItemsOnBox(vec3(-8,-8,-8)/size, vec3(0.5f,0.5f,0.5f)/size).map!(a => a.data).array;
		assert(result.canFind(1));
		assert(result.length == 1); 
	}

	// Make sure things are being placed into the right cells
	tree.insert(6, vec3(0,0,0)/size, vec3(64,64,64)/size);
	assert(getCellCenterSize(6, tree.getHead) == vec4(0,0,0,64));

	tree.insert(7, vec3(0,0,0)/size, vec3(32,32,32)/size);
	assert(getCellCenterSize(7, tree.getHead) == vec4(0,0,0,64));

	tree.insert(8, vec3(0,0,0)/size, vec3(16,16,16)/size);
	assert(getCellCenterSize(8, tree.getHead) == vec4(-16,-16,-16,32));

	tree.insert(9, vec3(0,0,0)/size, vec3(8,8,8)/size);
	assert(getCellCenterSize(9, tree.getHead) == vec4(-8,-8,-8,16));

	tree.insert(10, vec3(0,0,0)/size, vec3(4,4,4)/size);
	assert(getCellCenterSize(10, tree.getHead) == vec4(-4,-4,-4,8));

	tree.insert(11, vec3(0,0,0)/size, vec3(2,2,2)/size);
	assert(getCellCenterSize(11, tree.getHead) == vec4(-2,-2,-2,4));

	tree.insert(12, vec3(0,0,0)/size, vec3(1,1,1)/size);
	assert(getCellCenterSize(12, tree.getHead) == vec4(-1,-1,-1,2));

	tree.insert(13, vec3(0,0,0)/size, vec3(0.5f,0.5f,0.5f)/size);
	assert(getCellCenterSize(13, tree.getHead) == vec4(-0.5f,-0.5f,-0.5f,1));

	tree.insert(14, vec3(0,0,0)/size, vec3(0.25f,0.25f,0.25f)/size);
	assert(getCellCenterSize(14, tree.getHead) == vec4(-0.25f,-0.25f,-0.25f,0.5f));

	tree.insert(15, vec3(0,0,0)/size, vec3(0.125f,0.125f,0.125f)/size);
	assert(getCellCenterSize(15, tree.getHead) == vec4(-0.25f,-0.25f,-0.25f,0.5f)); // Same cell as before because we hit max depth





	//tree.insert(6, vec3(0,0,0)/size, vec3(1,1,1)/size);
	//assert(getCellCenterSize(6, tree.getHead) == vec4(-1,-1,-1,2));
}

