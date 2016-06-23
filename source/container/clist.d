module container.clist;

import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.experimental.allocator.gc_allocator;
import std.range;

import core.memory;

/**
 * Refcounted circular linked list
 *
 * Will assert in debug if certain operations are performed while a range is active.
 * Removals, moves, transfers, pops, and clear are not allowed while range locked.
 * Insertions, rotations, peeks, and additinal ranges are ok. 
 */
struct CList(T, A=Mallocator, bool GC_SCAN=true) {
	static if(__traits(compiles, () { alias a = A.instance; })) {
		alias alloc = A.instance;
	} else {
		A alloc; // Will need to be set manually before anything is allocated
	}

	/**
	* The structure of the nodes that are malloced 
	*/
	struct Node{
		T data; 
		private Node* next = null;
		private Node* prev = null;

		/// Get the node after this one O(1)
		Node* getNext() {
			pragma(inline, true); // simple getters should always be inlined
			return next;
		}

		/// Get the node before this one O(1)
		Node* getPrev() {
			pragma(inline, true); // simple getters should always be inlined
			return prev;
		}
		
		// Removed because can not maintaion range lock whith this and I was not using it... 
		///// Range to iterate over the values in the list that this node is in with this node as the start
		//auto Range()
		//{
		//    import std.algorithm;
		//    return NodeRange().map!(range_get);
		//}
		//
		///// Range to iterate over the nodes in the list that this node is in with this node as the start
		//auto NodeRange()
		//{
		//    import std.algorithm;
		//    return nodeRangeStruct(&this, prev, false);
		//}

		// does not work because we are always interacting with nodes by pointer and pointers have there own [] 
		/*auto opIndex() {
			return Range();
		}*/
	}

	private struct list_value
	{
		private Node* head = null;
		private uint count = 0;
		private uint ref_count = 1;

		// Used to make sure certain operations are not performed while the range is being iterated
		// Removals, moves, transfers, pops, and clear are not allowed while range locked... 
		// insertions, rotations, peeks, and additinal ranges are ok. 
		debug private uint rangeLock = 0; 
	}

	private list_value* list;

	this(this) {
		if(list != null) list.ref_count ++;
	}

	~this() {
		if(list == null) return; 

		list.ref_count--;
		if(list.ref_count == 0) {
			clear();
			alloc.dispose(list);
		}
	}

	void opAssign(typeof(null) n) {
		if(list == null) return; 

		list.ref_count--;
		if(list.ref_count == 0) {
			clear();
			alloc.dispose(list);
		}
		list = null;
	}

	bool opEquals(typeof(null) rhs) {
		return list == null || list.count == 0;
	}

	bool opEquals(CList!(T,A,GC_SCAN) rhs) {
		return this.list == rhs.list;
	}

	private void init() {
		list = alloc.make!list_value();
	}

	/// The number of nodes in the list O(1)
	uint length() {
		if(list == null) return 0;
		return list.count; 
	}
	
	/**
	* Allocates a node and inserts it to the front of the list O(1)
	*/
	Node* insert(T v) {
		return insertFront(v);
	}

	/**
	* Allocates a node and inserts it to the front of the list O(1)
	*/
	Node* insertFront(T v) {
		if(list == null) init();
		Node* n = makeNode();
		n.data = v;

		if(list.head == null) {
			list.head = n;
			list.head.prev = n;
		}

		n.next = list.head;
		n.prev = list.head.prev;
		list.head.prev.next = n;
		list.head.prev = n;
		list.head = n;

		list.count++;
		return n;
	}

	/**
	* Allocates a node and inserts it to the back of the list O(1)
	*/
	Node* insertBack(T v) {
		auto r = insertFront(v);
		rotateBackward();
		return r;
	}

	/// Allocates a node and inserts it before loc O(1)
	Node* insertBefore(T v, Node* loc) {
		if(list == null || loc == null) return null; // This is just a fuck up really
		Node* n = makeNode();

		n.data = v;

		// stick it before loc
		n.next = loc;
		n.prev = loc.prev;
		loc.prev.next = n;
		loc.prev = n;

		// If you are trying to move before head, should make n the new head
		if(loc == list.head) rotateForward();

		return n;
	}

	/// Allocates a node and inserts it after loc O(1)
	Node* insertAfter(T v, Node* loc) {
		if(list == null || loc == null) return null; // This is just a fuck up really
		Node* n = makeNode();
		n.data = v;

		// stick it after loc
		n.next = loc.next;
		n.prev = loc;
		loc.next.prev = n;
		loc.next = n;
		
		return n;
	}

	/// Moves the back of the list to the front O(1)
	void rotateForward() {
		if(list != null && list.head != null) list.head = list.head.prev;
	}

	/// Moves the front of the list to the back O(1)
	void rotateBackward() {
		if(list != null && list.head != null) list.head = list.head.next;
	}

	/// Rotate list such that node n is in the front, maintains order O(1)
	void rotateToNode(Node* n) {
		if(list != null && list.head != null) list.head = n;
	}
	
	/// Deletes all the nodes in the list O(n)
	void clear() {
		if(list == null) return; 
		debug assert(list.rangeLock == 0, "Can not clear while range is active");

		auto temp = list.head;
		while(temp != null) {
			auto n = temp.next;
			freeNode(temp);
			temp = n;
			if(temp == list.head) temp = null;
		}
		
		list.head = null;
		list.count = 0;
	}

	/// Removes a specific node O(1)
	void removeNode(Node* n) {
		if(list == null) return;
		debug assert(list.rangeLock == 0, "Can not remove while range is active");

		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(list.head == n) list.head = list.head.next;
		if(list.head == n) list.head = null;
		list.count--;
		freeNode(n);
	}

	/// Removes a specific value even if it occures more than once O(n)
	void remove(T v) {
		if(list == null) return;
		debug assert(list.rangeLock == 0, "Can not remove while range is active");
		auto h = list.head;
		while(h) {
			auto t = h.next;
			if(t == list.head) t = null;
			if(h.data is v)
				removeNode(h);
			h = t;
		}
	}

	/// Removes the font of the list and returns it O(1)
	T popFront() {
		assert(list != null && list.head != null, "Empty list");
		T r = list.head.data;
		removeNode(list.head);
		return r;
	}

	/// Removes the back of the list and returns it O(1)
	T popBack() {
		rotateForward();
		return popFront();
	}

	/// Returns the value in the front of the list O(1)
	ref T peekFront() {
		assert(list != null && list.head != null, "Empty list");
		return list.head.data;
	}

	/// Returns the value in the back of the list O(1)
	ref T peekBack() {
		assert(list != null && list.head != null, "Empty list");
		return list.head.prev.data;
	}

	/// Move a node to the front of the list O(1)
	void moveFront(Node* n) {
		if(list == null) return;
		if(list.head == n) return; // Already the front... 
		debug assert(list.rangeLock == 0, "Can not move while range is active");

		n.prev.next = n.next;
		n.next.prev = n.prev;
		n.next = list.head;
		n.prev = list.head.prev;
		list.head.prev.next = n;
		list.head.prev = n;
		list.head = n;
	}

	/// Move a node to the back of the list O(1)
	void moveBack(Node* n) {
		moveFront(n);
		rotateBackward();
	}

	/// Move a node before another O(1)
	void moveBefore(Node* n, Node* loc) {
		if(list == null || loc == null) return; // This is just a fuck up really
		if(loc.prev == n) {	
			if(n == list.head) rotateBackward(); 
			return; // Already where we need it...  
		}
		if(loc == n) return; // makes no sense
		debug assert(list.rangeLock == 0, "Can not move while range is active");

		// cut the node out
		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(list.head == n) list.head = list.head.next;

		// stick it before loc
		n.next = loc;
		n.prev = loc.prev;
		loc.prev.next = n;
		loc.prev = n;

		// If you are trying to move before head, should make n the new head
		if(loc == list.head) rotateForward();
	}

	/// Move a node after another O(1)
	void moveAfter(Node* n, Node* loc) {
		if(list == null || loc == null) return; // This is just a fuck up really
		if(loc.next == n) {
			if(n == list.head) rotateBackward(); 
			return; // Already where we need it... 
		}
		if(loc == n) return; // makes no sense
		debug assert(list.rangeLock == 0, "Can not move while range is active");

		// cut the node out
		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(list.head == n) list.head = list.head.next;

		// stick it after loc
		n.next = loc.next;
		n.prev = loc;
		loc.next.prev = n;
		loc.next = n;
	}

	void moveTowardsFront(Node* n) {
		if(list == null || n == list.head) return;
		moveBefore(n, n.prev);
	}

	void moveTowardsBack(Node* n) {
		if(list == null || n == list.head.prev) return;
		moveAfter(n, n.next);
	}

	/// Get the node at the front of the list O(1)
	Node* getFront() {
		pragma(inline, true); // simple getters should always be inlined
		if(list != null) return list.head;
		else return null;
	}

	/// Get the node at the back of the list O(1)
	Node* getBack() {
		pragma(inline, true); // simple getters should always be inlined
		if(list != null && list.head != null) return list.head.prev;
		else return null;
	}
	
	/// A range to iterate over the values in the list 
	auto Range() {
		import std.algorithm;
		return NodeRange().map!(range_get);
	}


	/// A range to iterate over the nodes in the list
	auto NodeRange() {
		if(list == null) return nodeRangeStruct(null, null, true);
		else {
			debug{
				auto r = nodeRangeStruct(
					list.head, 
					(list.head != null) ? list.head.prev : null,
					list.head == null, 
					this
					);
				list.rangeLock++;
				return r;
			} else {
				return nodeRangeStruct(
					list.head, 
					(list.head != null) ? list.head.prev : null,
					list.head == null, 
					this
					);
			}
		}
	}
	
	/// Shortcut to Range() 
	auto opIndex() {
		return Range();
	}

	/// Range struct to iterate over the list
	private struct nodeRangeStruct{
		private Node* m_head;
		private Node* m_tail;
		bool empty;
		private CList!(T, A, GC_SCAN) sourceList; // Used to maintain the refcount while range is active... 

		// Forward iteration
		Node* front()	{ return m_head; }
		void popFront() { 
			m_head = m_head.next;
			if(m_head.prev == m_tail) {
				empty = true;
				debug sourceList.list.rangeLock--;
				sourceList = null;
				m_head = null;
				m_tail = null;
			}
		} 
		// Backwards iteration
		Node* back() { return m_tail; }
		void popBack() {
			m_tail = m_tail.prev;
			if(m_head.prev == m_tail) {
				empty = true; 
				debug sourceList.list.rangeLock--;
				sourceList = null;
				m_head = null;
				m_tail = null;
			}
		}
		// Save for forward range
		auto save() { return this; }
	
		debug{
			this(this) {
				if(sourceList.list != null) sourceList.list.rangeLock++;
			}

			~this() {
				if(sourceList.list != null) 
					sourceList.list.rangeLock--;
			}
		}
	}

	static assert(isBidirectionalRange!nodeRangeStruct);

	// used to make sure the nodes are GC scaned
	private auto makeNode() {
		Node* n = alloc.make!Node();
		static if(GC_SCAN) GC.addRange(n, Node.sizeof, typeid(Node));
		return n;
	}

	private void freeNode(Node* n) {
		static if(GC_SCAN) GC.removeRange(n);
		alloc.dispose(n);
	}
}

// Had to move out of CList because of bug 5710, what bs 
void removePred(alias pred, T, A, bool G, ARGS ...)(CList!(T,A,G) l, ARGS args) {
	import std.functional;
	//alias fun = unaryFun!pred;

	if(l.list == null) return;

	auto h = l.list.head;
	while(h) {
		auto t = h.next;
		if(t == l.list.head) t = null;
		if(pred(h.data, args))
			l.removeNode(h);
		h = t;
	}
}

/**
* Moves a node from one CList to another O(1)
* The node will end up in the front of the dest list
*/
auto transferNode(T, A, bool G)(ref CList!(T,A,G) src, ref CList!(T,A,G) dest, CList!(T,A,G).Node* n) {
	// Remove it from src
	{
		assert(src.list != null);
		debug assert(src.list.rangeLock == 0, "Can not transfer while range is active");

		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(src.list.head == n) src.list.head = src.list.head.next;
		if(src.list.head == n) src.list.head = null;
		src.list.count--;
	}

	// Insert it into dest
	{
		if(dest.list == null) dest.init();
		debug assert(dest.list.rangeLock == 0, "Can not transfer while range is active");
		if(dest.list.head == null) {
			dest.list.head = n;
			dest.list.head.prev = n;
		}

		n.next = dest.list.head;
		n.prev = dest.list.head.prev;
		dest.list.head.prev.next = n;
		dest.list.head.prev = n;
		dest.list.head = n;

		dest.list.count++;
	}
	
	return n;
}

/**
* Moves all nodes from one CList to another 
*/
auto transferAllFront(T, A, bool G)(ref CList!(T,A,G) src, ref CList!(T,A,G) dest) {
	if(src.list == null) return;
	if(src.list.head == null) return; 

	auto head = src.list.head.prev;
	auto n = head;
	while(n) {
		auto t = n.prev;
		if(t == head) t = null;

		// Insert it into dest at front
		if(dest.list == null) dest.init();
		if(dest.list.head == null) {
			dest.list.head = n;
			dest.list.head.prev = n;
		}

		n.next = dest.list.head;
		n.prev = dest.list.head.prev;
		dest.list.head.prev.next = n;
		dest.list.head.prev = n;
		dest.list.head = n;

		dest.list.count++;
		n = t;
	}

	src.list.count = 0;
	src.list.head = null;
}

/**
* Moves all nodes from one CList to another 
*/
auto transferAllBack(T, A, bool G)(ref CList!(T,A,G) src, ref CList!(T,A,G) dest) {
	if(src.list == null) return;
	if(src.list.head == null) return; 

	auto head = src.list.head;
	auto n = head;
	while(n) {
		auto t = n.next;
		if(t == head) t = null;

		// Insert it into dest at front
		if(dest.list == null) dest.init();
		if(dest.list.head == null) {
			dest.list.head = n;
			dest.list.head.prev = n;
		}

		n.next = dest.list.head;
		n.prev = dest.list.head.prev;
		dest.list.head.prev.next = n;
		dest.list.head.prev = n;
		dest.list.head = n.next;

		dest.list.count++;
		n = t;
	}

	src.list.count = 0;
	src.list.head = null;
}



auto ref range_get(N)(N* p) { return p.data; }


unittest
{
	import std.algorithm;
	import std.range;

	CList!int l;

	string listPrint(CList!int someList) {
		import std.conv;
		string s = "[";
		foreach(v; someList[]) s ~= v.to!string;
		return s ~ "]";
	}

	l.insert(5);
	l.insert(6);
	l.insert(7);

	{
		// Make sure ref counting working... 
		assert(l.list.ref_count == 1);
		{
			void foo(CList!int x) {
				assert(l.list.ref_count == 3);
			}

			auto o = l;
			assert(l.list.ref_count == 2);
			foo(l);
			assert(l.list.ref_count == 2);
			foo(o);
			assert(l.list.ref_count == 2);
		}
		assert(l.list.ref_count == 1);

		{
			auto o = l;
			assert(l.list.ref_count == 2);
			o = null;
			assert(l.list.ref_count == 1);
		}
		assert(l.list.ref_count == 1);

		{
			struct test
			{
				CList!int x;
			}

			test t;
			t.x = l;
			assert(l.list.ref_count == 2);
			test t2 = t;
			assert(l.list.ref_count == 3);
		}
		assert(l.list.ref_count == 1);
	}




	assert(l.length == 3);
	assert(equal(l.Range,[7,6,5]));
	assert(equal(l[], [7,6,5]));
	assert(equal(l.Range.retro,[5,6,7]));

	l.clear();
	int[] b;
	assert(equal(l.Range,b));
	assert(l.length == 0);
	assert(l.list.rangeLock == 0);

	l.insert(6);
	assert(equal(l.Range,[6]));
	assert(l.length == 1);

	l.clear();
	l.insertBack(5);
	l.insertBack(6);
	l.insertBack(7);
	assert(equal(l.Range,[5,6,7]));

	l.clear();
	l.insertFront(5);
	l.insertFront(6);
	l.insertBack(7);
	assert(equal(l.Range,[6,5,7]));

	l.clear();
	l.insert(5);
	l.insert(6);
	l.insert(7);
	l.rotateBackward();
	assert(equal(l.Range,[6,5,7]));
	l.rotateBackward();
	assert(equal(l.Range,[5,7,6]));
	l.rotateForward();
	assert(equal(l.Range,[6,5,7]));

	l.clear();
	l.insert(5);
	auto n = l.insert(6);
	l.insert(7);
	l.removeNode(n);
	assert(equal(l.Range,[7,5]));

	l.clear();
	l.insert(5);
	l.insert(6);
	n = l.insert(7);
	l.removeNode(n);
	assert(equal(l.Range,[6,5]));

	l.clear();
	n = l.insert(5);
	l.insert(6);
	l.insert(7);
	l.removeNode(n);
	assert(equal(l.Range,[7,6]));

	l.clear();
	l.insert(1);
	l.insert(2);
	l.insert(2);
	l.insert(3);
	l.remove(2);
	assert(equal(l.Range,[3,1]));

	l.clear();
	l.insert(1);
	l.insert(2);
	l.insert(3);
	l.remove(2);
	assert(equal(l.Range,[3,1]));

	l.clear();
	l.insert(2);
	l.insert(2);
	l.remove(2);
	assert(equal(l.Range,b));
	assert(l.length == 0);

	CList!int other_list;
	int[] empty_int_array;
	assert(equal(other_list.Range, empty_int_array));

	{
		l.clear();
		auto n1 = l.insertBack(5);
		auto n2 = l.insertBack(6);
		auto n3 = l.insertBack(7);
		assert(equal(l.Range,[5,6,7]));

		l.moveFront(n2);
		assert(equal(l.Range,[6,5,7]));

		l.moveFront(n2); // should do nothing, the node should be already at the front
		assert(equal(l.Range,[6,5,7]));

		l.moveBack(n2);
		assert(equal(l.Range,[5,7,6]));

		l.moveAfter(n3,n2);
		assert(equal(l.Range,[5,6,7]));

		l.moveAfter(n3,n2); // should do nothing
		assert(equal(l.Range,[5,6,7]));

		l.moveAfter(n1,n3);
		assert(equal(l.Range,[6,7,5]));

		l.moveBefore(n1,n3); 
		assert(equal(l.Range,[6,5,7])); 

		l.moveBefore(n2,n3); 
		assert(equal(l.Range,[5,6,7])); 

		l.moveBefore(n2,n3); // should do nothing
		assert(equal(l.Range,[5,6,7])); 

		// test the range on nodes 
		//assert(equal(n1.Range,[5,6,7])); 
		//assert(equal(n2.Range,[6,7,5])); 
		//assert(equal(n3.Range,[7,5,6])); 
	}

	{
		auto o = l;
		assert(o == l);
		o = null;
		assert(o != l);
		assert(l != null);
		assert(o == null);
	} 

	{
		CList!int list1;
		CList!int list2;
		auto node = list1.insert(5);

		transferNode(list1, list2, node);

		assert(list1.Range.empty); 
		assert(equal(list2.Range,[5]));
	}

	{
		CList!int list;
		list.insertBack(1);
		list.insertBack(2);
		list.insertBack(3);
		list.insertBack(4);
		list.insertBack(5);

		assert(equal(list[] ,[1,2,3,4,5]));
		list.removePred!((a) => a%2 == 0)();
		assert(equal(list[] ,[1,3,5]));
	}


	{
		CList!int list1;

		list1.insertBack(1);
		list1.insertBack(2);
		list1.insertBack(3);
		list1.insertBack(4);
		list1.insertBack(5);
		

		CList!int list2;
		list2.insertBack(6);
		list2.insertBack(7);
		list2.insertBack(8);
		list2.insertBack(9);
		list2.insertBack(10);

		transferAllFront(list1, list2);
		assert(equal(list2[] ,[1,2,3,4,5,6,7,8,9,10]));
		assert(list1[].empty);
	}

	{
		CList!int list1;

		list1.insertBack(1);
		list1.insertBack(2);
		list1.insertBack(3);
		list1.insertBack(4);
		list1.insertBack(5);


		CList!int list2;
		list2.insertBack(6);
		list2.insertBack(7);
		list2.insertBack(8);
		list2.insertBack(9);
		list2.insertBack(10);

		transferAllBack(list1, list2);
		assert(equal(list2[] ,[6,7,8,9,10,1,2,3,4,5]));
		assert(list1[].empty);
	}

	// TODO test pop and peek
	// TODO test NodeRange
}


