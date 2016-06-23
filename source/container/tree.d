module container.tree;
import container.clist;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.stdio;

alias alloc = Mallocator.instance;

// TODO Redo this with CList... 

/// Used to init a Tree!(T)
/// example: Tree!int(node(1, node(2), node(3)));
/// results in the tree: 
///     1
///   2   3 
public auto node(T, ARGS...)(T v, ARGS args) {
	struct Result
	{
		private T root;
		private ARGS children;
		private void insertIntoTree(TreeNode!(T)* tree) {
			auto n = tree.insertBack(root);
			foreach(c; children) {
				c.insertIntoTree(n);
			}
		}
	}
	return Result(v, args);
}

// Used to make sure the nodes are gc scaned
private auto makeNode(T)() {
	import core.memory;
	auto n = alloc.make!(TreeNode!(T))();
	GC.addRange(n, TreeNode!(T).sizeof, typeid(TreeNode!(T)));
	return n;
}

private void freeNode(T)(TreeNode!(T)* n) {
	import core.memory;
	GC.removeRange(n);
	alloc.dispose(n);
}

/**
 * Simple refcounted tree
 */
public struct Tree(T) {
	public TreeNode!(T)* root;
	alias root this;
	alias Node = TreeNode!(T);
	alias Data = T;
	private uint* ref_count;

	@disable this();

	//public this(T v, IAllocator node_allocator)
	public this(T v) {
		ref_count = alloc.make!uint();
		(*ref_count) = 1;

		TreeNode!(T)* n = makeNode!T();
		//n.alloc = node_allocator;
		n.data = v;
		n.parent = null;
		n.next = n;
		n.prev = n;
		root = n;
	}

	//public this(T v)
	//{
	//	this(v, allocatorObject(Mallocator.instance));
	//}

	//public this(N)(N nodes, IAllocator node_allocator)
	public this(N)(N nodes) {
		this(nodes.root);
		foreach(c; nodes.children) {
			c.insertIntoTree(root);
		}
	}

	//public this(N)(N nodes)
	//{
	//	this(nodes, allocatorObject(Mallocator.instance));
	//}
	
	this(this) {
		(*ref_count) ++;
	}

	~this() {
		(*ref_count) --;
		if((*ref_count) == 0) {
			root.clear();
			alloc.dispose(ref_count);
			freeNode(root);
		}
	}
}

private struct TreeNode(T) {
	public T data; 
	private TreeNode!(T)* next = null;
	private TreeNode!(T)* prev = null;
	private TreeNode!(T)* children = null;
	private TreeNode!(T)* parent = null;
	private uint count = 0;
	//private IAllocator alloc = new CAllocatorImpl!(Mallocator)();

	private void destroy() {
		clear();
	}

	public uint childrenCount() { 
		return count; 
	}

	public TreeNode!(T)* getParent() {
		pragma(inline, true);
		return parent;
	}
	
	/**
	* Allocates a node and inserts it to the front of the children list
	*/
	public TreeNode!(T)* insert(T v) {
		return insertFront(v);
	}

	/**
	* Allocates a node and inserts it to the front of the children list
	*/
	public TreeNode!(T)* insertFront(T v) {
		TreeNode!(T)* n = makeNode!T();
		n.data = v;
		//n.alloc = alloc;
		n.parent = &this;

		if(children == null) {
			children = n;
			children.prev = n;
		}

		n.next = children;
		n.prev = children.prev;
		children.prev.next = n;
		children.prev = n;
		children = n;

		count++;
		return n;
	}

	/**
	* Allocates a node and inserts it to the back of the children list
	*/
	public TreeNode!(T)* insertBack(T v) {
		auto r = insertFront(v);
		rotateBackward();
		return r;
	}

	public TreeNode!(T)* insert(N)(N nodes) {
		return insertFront(nodes);
	}

	/**
	* Allocates a node and inserts it to the front of the children list
	*/
	public TreeNode!(T)* insertFront(N)(N nodes) {
		auto root = insertFront(nodes.root);
		foreach(c; nodes.children) {
			c.insertIntoTree(root);
		}
		return root;
	}

	/**
	* Allocates a node and inserts it to the back of the children list
	*/
	public TreeNode!(T)* insertBack(N)(N nodes) {
		auto r = insertFront(nodes);
		rotateBackward();
		return r;
	}

	public void rotateForward() {
		if(children != null) children = children.prev;
	}

	public void rotateBackward() {
		if(children != null) children = children.next;
	}
	
	public void clear() {
		auto temp = children;
		while(temp != null) {
			auto n = temp.next;
			temp.destroy();
			freeNode(temp);
			temp = n;
			if(temp == children) temp = null;
		}
		
		children = null;
		count = 0;
	}

	public void removeChild(TreeNode!(T)* n) {
		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(children == n) children = children.next;
		if(children == n) children = null;
		n.clear();
		count--;
		freeNode(n);
	}

	public void remove(T v) {
		auto h = children;
		while(h) {
			auto t = h.next;
			if(t == children) t = null;
			if(h.data is v)
				removeChild(h);
			h = t;
		}
	}
	
	public auto Children() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			private TreeNode!(T)* m_tail;
			public bool empty;
			// Forward iteration
			public TreeNode!(T)* front()	{ return m_head; }
			public void popFront() { 
				m_head = m_head.next;
				if(m_head.prev == m_tail) empty = true;
			} 
			// Backwards iteration
			public TreeNode!(T)* back() { return m_tail; }
			public void popBack() { 
				m_tail = m_tail.prev;
				if(m_head.prev == m_tail) empty = true; 
			}
			// Save for forward range
			public auto save() { return this; }

		}

		//static assert(isBidirectionalRange!Result);
		
		return Result(
			children,
			(children != null) ? children.prev : null,
			children == null
			);
	}

	public alias depthfirst = depthfirst_preorder;

	public auto depthfirst_postorder() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			public bool empty = false;
			public ref T front()	{ return m_head.data; }

			private this(TreeNode!(T)* head) {
				m_head = head;
				gotoBotLeft(m_head);
			}

			public void popFront() { 
				if(atEnd(m_head)) moveUp(m_head);
				else {
					moveRight(m_head);
					gotoBotLeft(m_head);
				}

				if(m_head == null) empty = true;
			}
		}

		static assert(isInputRange!Result);
		return Result(&this);
	}

	public auto depthfirst_postorder_reverse() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			public bool empty = false;
			public ref T front()	{ return m_head.data; }

			private this(TreeNode!(T)* head) {
				m_head = head;
				gotoBotRight(m_head);
			}

			public void popFront() { 
				if(atStart(m_head)) moveUp(m_head);
				else {
					moveLeft(m_head);
					gotoBotRight(m_head);
				}

				if(m_head == null) empty = true;
			}
		}

		static assert(isInputRange!Result);
		return Result(&this);
	}

	public auto depthfirst_preorder() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			public bool empty = false;
			public ref T front()	{ return m_head.data; }

			private this(TreeNode!(T)* head) {
				m_head = head;
			}

			public void popFront() { 
				if(m_head.count != 0) {
					moveDownLeft(m_head);
				} else {
					if(atEnd(m_head)) {
						while(atEnd(m_head)) {
							moveUp(m_head);
							if(m_head == null) {
								empty = true;
								return;
							}
						}
						moveRight(m_head);
					} else {
						moveRight(m_head);
					}
				}
			}
		}

		static assert(isInputRange!Result);
		return Result(&this);
	}

	public auto depthfirst_preorder_reverse() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			public bool empty = false;
			public ref T front()	{ return m_head.data; }

			private this(TreeNode!(T)* head) {
				m_head = head;
			}

			public void popFront() { 
				if(m_head.count != 0) {
					moveDownRight(m_head);
				} else {
					if(atStart(m_head)) {
						while(atStart(m_head)) {
							moveUp(m_head);
							if(m_head == null) {
								empty = true;
								return;
							}
						}
						moveLeft(m_head);
					} else {
						moveLeft(m_head);
					}
				}
			}
		}

		static assert(isInputRange!Result);
		return Result(&this);
	}

	public auto breadthfirst() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			private int depth = 0;
			public bool empty = false;
			public ref T front()	{ return m_head.data; }

			private this(TreeNode!(T)* head) {
				m_head = head;
			}

			public void popFront() { 
				auto b = moveRightAcross();
				if(!b) {
					depth ++;
					m_head = getFirstDepth(m_head, depth, 0);
					if(m_head == null) empty = true;
				}
			}

			private bool moveRightAcross() {
				if(atEnd(m_head)) {
					if(m_head.parent == null) return false;
					moveUp(m_head);
					while(true) {
						if(!moveRightAcross()) return false;
						if(m_head.count != 0) break;
					}
					moveDownLeft(m_head);
				} else moveRight(m_head);
				return true;
			}

			private TreeNode!(T)* getFirstDepth(TreeNode!(T)* root, int depth, int currentdepth) {
				if(depth == currentdepth) return root;
				foreach(c; root.Children) {
					auto n = getFirstDepth(c, depth, currentdepth+1);
					if(n != null) return n;
				}
				return null;
			}
		}

		static assert(isInputRange!Result);
		return Result(&this);
	}

	public auto breadthfirst_reverse() {
		import std.range;
		struct Result{
			private TreeNode!(T)* m_head;
			private int depth = 0;
			public bool empty = false;
			public ref T front()	{ return m_head.data; }

			private this(TreeNode!(T)* head) {
				m_head = head;
			}

			public void popFront() { 
				auto b = moveLeftAcross();
				if(!b) {
					depth ++;
					m_head = getFirstDepth(m_head, depth, 0);
					if(m_head == null) empty = true;
				}
			}

			private bool moveLeftAcross() {
				if(atStart(m_head)) {
					if(m_head.parent == null) return false;
					moveUp(m_head);
					while(true) {
						if(!moveLeftAcross()) return false;
						if(m_head.count != 0) break;
					}
					moveDownRight(m_head);
				} else moveLeft(m_head);
				return true;
			}

			private TreeNode!(T)* getFirstDepth(TreeNode!(T)* root, int depth, int currentdepth) {
				if(depth == currentdepth) return root;
				foreach_reverse(c; root.Children) {
					auto n = getFirstDepth(c, depth, currentdepth+1);
					if(n != null) return n;
				}
				return null;
			}
		}

		static assert(isInputRange!Result);
		return Result(&this);
	}

	public auto opIndex() {
		return depthfirst();
	}
}


unittest
{
	import std.algorithm;
	import std.range;

	Tree!int root = Tree!int(
		node(1, 
			node(2, 
				node(5), 
				node(6,
					node(9),
					node(10),
					), 
				node(7)
				), 
			node(3,
				node(8,
					node(11)
					)
				), 
			node(4)
			)
		);

	assert(equal(
		root.depthfirst_preorder,
		[1,2,5,6,9,10,7,3,8,11,4]));

	assert(equal(
		root.depthfirst_preorder_reverse,
		[1,4,3,8,11,2,7,6,10,9,5]));

	assert(equal(
		root.depthfirst_postorder,
		[5,9,10,6,7,2,11,8,3,4,1]));

	assert(equal(
		root.depthfirst_postorder_reverse,
		[4,11,8,3,7,10,9,6,5,2,1]));

	assert(equal(
		root.breadthfirst,
		[1,2,3,4,5,6,7,8,9,10,11]));

	assert(equal(
		root.breadthfirst_reverse,
		[1,4,3,2,8,7,6,5,11,10,9]));
}


// TreeNode Movement
private void gotoBotLeft(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	while(m_head.count != 0) // We are at leaf if no children, bot left is a leaf
	{
		m_head = m_head.children;
	}
}

private void gotoBotRight(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	while(m_head.count != 0) // We are at leaf if no children, bot left is a leaf
	{
		m_head = m_head.children.prev;
	}
}

private void moveDownLeft(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	m_head = m_head.children;
}

private void moveDownRight(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	m_head = m_head.children.prev;
}

private void moveRight(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	m_head = m_head.next;
}

private void moveLeft(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	m_head = m_head.prev;
}

private void moveUp(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	m_head = m_head.parent;
}

private bool atStart(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	if(m_head.parent == null) return true;
	return (m_head.parent.children == m_head);
}

private bool atEnd(T)(ref TreeNode!(T)* m_head) {
	//writeln(__FUNCTION__);
	if(m_head.parent == null) return true;
	return (m_head.parent.children.prev == m_head);
}






