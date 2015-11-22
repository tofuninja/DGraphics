module container.clist;

import std.experimental.allocator;
import std.experimental.allocator.mallocator;

private IAllocator malloc;
static this()
{
	malloc = allocatorObject(Mallocator.instance);
}

/**
 * Refcounted circular linked list
 */
public struct CList(T)
{
	public struct Node{
		public T data; 
		alias data this;
		private Node* next = null;
		private Node* prev = null;
	}

	private struct list_value
	{
		private Node* head = null;
		private uint count = 0;
		private IAllocator alloc;
		private uint ref_count = 1;
	}

	private list_value* list;

	public this(IAllocator node_allocator)
	{
		list = node_allocator.make!list_value();
		list.alloc = node_allocator;
	}
	
	this(this)
	{
		if(list != null) list.ref_count ++;
	}

	~this()
	{
		if(list == null) return; 

		list.ref_count--;
		if(list.ref_count == 0) 
		{
			clear();
			list.alloc.dispose(list);
		}
	}

	public void opAssign(typeof(null) n)
	{
		if(list == null) return; 

		list.ref_count--;
		if(list.ref_count == 0) 
		{
			clear();
			list.alloc.dispose(list);
		}
		list = null;
	}

	public bool opEquals(typeof(null) rhs)
	{
		return list == null;
	}

	public bool opEquals(CList!T rhs)
	{
		return this.list == rhs.list;
	}

	private void defaultMallocInit()
	{
		auto node_allocator = malloc;
		list = node_allocator.make!list_value();
		list.alloc = node_allocator;
	}

	public uint length() 
	{
		if(list == null) return 0;
		return list.count; 
	}
	
	/**
	* Allocates a node and inserts it to the front of the list
	*/
	public Node* insert(T v)
	{
		return insertFront(v);
	}

	/**
	* Allocates a node and inserts it to the front of the list
	*/
	public Node* insertFront(T v)
	{
		if(list == null) defaultMallocInit();

		Node* n = list.alloc.make!Node();
		n.data = v;

		if(list.head == null)
		{
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
	* Allocates a node and inserts it to the back of the list
	*/
	public Node* insertBack(T v)
	{
		auto r = insertFront(v);
		rotateBackward();
		return r;
	}

	public void rotateForward()
	{
		if(list != null && list.head != null) list.head = list.head.prev;
	}

	public void rotateBackward()
	{
		if(list != null && list.head != null) list.head = list.head.next;
	}
	
	public void clear()
	{
		if(list == null) return;

		auto temp = list.head;
		while(temp != null)
		{
			auto n = temp.next;
			list.alloc.dispose(temp);
			temp = n;
			if(temp == list.head) temp = null;
		}
		
		list.head = null;
		list.count = 0;
	}

	public void removeNode(Node* n)
	{
		if(list == null) return;

		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(list.head == n) list.head = list.head.next;
		if(list.head == n) list.head = null;
		list.count--;
		list.alloc.dispose(n);
	}

	public void remove(T v)
	{
		if(list == null) return;

		auto h = list.head;
		while(h)
		{
			auto t = h.next;
			if(t == list.head) t = null;
			if(h.data is v)
				removeNode(h);
			h = t;
		}
	}

	public T popFront()
	{
		assert(list != null && list.head != null, "Empty list");
		T r = list.head.data;
		removeNode(list.head);
		return r;
	}

	public T popBack()
	{
		rotateForward();
		return popFront();
	}

	public T peekFront()
	{
		assert(list != null && list.head != null, "Empty list");
		return list.head.data;
	}

	public T peekBack()
	{
		assert(list != null && list.head != null, "Empty list");
		return list.head.prev.data;
	}
	
	public auto Range()
	{
		import std.range.primitives;
		struct Result{
			private Node* m_head;
			private Node* m_tail;
			public bool empty;
			// Forward iteration
			public ref T front()	{ return m_head.data; }
			public void popFront() 	
			{ 
				m_head = m_head.next;
				if(m_head.prev == m_tail) empty = true;
			} 
			// Backwards iteration
			public ref T back()		{ return m_tail.data; }
			public void popBack() 	
			{ 
				m_tail = m_tail.prev;
				if(m_head.prev == m_tail) empty = true; 
			}
			// Save for forward range
			public auto save()		{ return this; }

		}

		static assert(isBidirectionalRange!Result);

		if(list == null) return Result(null, null, true);
		else return Result(
			list.head, 
			(list.head != null) ? list.head.prev : null,
			list.head == null
			);
	}

	public auto NodeRange()
	{
		import std.range.primitives;
		struct Result{
			private Node* m_head;
			private Node* m_tail;
			public bool empty;
			// Forward iteration
			public Node* front()	{ return m_head; }
			public void popFront() 	
			{ 
				m_head = m_head.next;
				if(m_head.prev == m_tail) empty = true;
			} 
			// Backwards iteration
			public Node* back()		{ return m_tail; }
			public void popBack() 
			{ 
				m_tail = m_tail.prev;
				if(m_head.prev == m_tail) empty = true; 
			}
			// Save for forward range
			public auto save()		{ return this; }
		}

		static assert(isBidirectionalRange!Result);
		
		if(list == null) return Result(null, null, true);
		else return Result(
			list.head, 
			(list.head != null) ? list.head.prev : null,
			list.head == null
			);
	}

	public auto opIndex()
	{
		return Range();
	}
}

unittest
{
	import std.algorithm;
	import std.range;

	CList!int l;

	l.insert(5);
	l.insert(6);
	l.insert(7);

	{
		// Make sure ref counting working... 
		assert(l.list.ref_count == 1);
		{
			void foo(CList!int x)
			{
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
		auto o = l;
		assert(o == l);
		o = null;
		assert(o != l);
		assert(l != null);
		assert(o == null);
	}

	// TODO test pop and peek
	// TODO test NodeRange
}
