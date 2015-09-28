module container.clist;

/**
 * Simple circular linked list where the nodes are controlled by user code, as opposed to std.container.llist
 * Allows for the node's allocation to be controlled
 * 
 * In debug mode, the list will take more time clearing to ensure that a Node only exits in one list at a time O(n)
 * In debug mode the list will assert if a node is added to more than one list at a time
 * In release the list just assumes that you only add it to one list at a time(enables faster clear O(1))
 */
public struct CList(T)
{
	public struct Node{
		public T args; 
		private Node* next = null;
		private Node* prev = null;
		debug private bool inAList = false;
		public void opAssign(T rhs) {
			args = rhs;
		}
	}
	
	private Node* head = null;
	private uint count = 0;

	public uint length() 
	{ 
		return count; 
	}
	
	public void insert(ref Node n)
	{
		insertFront(n);
	}

	public void insertFront(ref Node n)
	{
		debug assert(!n.inAList, "Node already in a list");
		debug n.inAList = true;
		
		if(head == null)
		{
			head = &n;
			head.prev = &n;
		}

		n.next = head;
		n.prev = head.prev;
		head.prev.next = &n;
		head.prev = &n;
		head = &n;

		count++;
	}

	public void insertBack(ref Node n)
	{
		insertFront(n);
		rotateBackward();
	}

	public void rotateForward()
	{
		if(head != null) head = head.prev;
	}

	public void rotateBackward()
	{
		if(head != null) head = head.next;
	}
	
	public void clear()
	{
		debug
		{
			auto temp = head;
			while(temp)
			{
				auto n = temp.next;
				temp.next = null;
				temp.prev = null;
				temp.inAList = false;
				temp = n;
			}
		}
		head = null;
		count = 0;
	}

	public void removeNode(ref Node n)
	{
		n.prev.next = n.next;
		n.next.prev = n.prev;
		if(head == &n) head = head.next;
		if(head == &n) head = null;
		debug {
			n.next = null;
			n.prev = null;
			n.inAList = false;
		}
		count--;
	}
	
	public auto Range()
	{
		import std.range.primitives;
		struct Result{
			private Node* m_head;
			private Node* m_tail;
			public bool empty;
			// Forward iteration
			public ref T front()	{ return m_head.args; }
			public void popFront() 	
			{ 
				m_head = m_head.next;
				if(m_head.prev == m_tail) empty = true;
			} 
			// Backwards iteration
			public ref T back()		{ return m_tail.args; }
			public void popBack() 	
			{ 
				m_tail = m_tail.prev;
				if(m_head.prev == m_tail) empty = true; 
			}
			// Save for forward range
			public auto save()		{ return this; }

		}

		static assert(isBidirectionalRange!Result);
		
		return Result(
			head, 
			(head != null) ? head.prev : null,
			head == null
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
	import std.stdio;

	CList!int l;
	l.Node n1, n2, n3;
	
	n1 = 5;
	n2 = 6;
	n3 = 7;

	l.insert(n1);
	l.insert(n2);
	l.insert(n3);

	assert(l.length == 3);
	assert(equal(l.Range,[7,6,5]));
	assert(equal(l[], [7,6,5]));
	assert(equal(l.Range.retro,[5,6,7]));

	l.clear();
	int[] b;
	assert(equal(l.Range,b));
	assert(l.length == 0);

	l.insert(n2);
	assert(equal(l.Range,[6]));
	assert(l.length == 1);

	l.clear();
	l.insertBack(n1);
	l.insertBack(n2);
	l.insertBack(n3);
	assert(equal(l.Range,[5,6,7]));

	l.clear();
	l.insertFront(n1);
	l.insertFront(n2);
	l.insertBack(n3);
	assert(equal(l.Range,[6,5,7]));

	l.clear();
	l.insert(n1);
	l.insert(n2);
	l.insert(n3);
	l.rotateBackward();
	assert(equal(l.Range,[6,5,7]));
	l.rotateBackward();
	assert(equal(l.Range,[5,7,6]));
	l.rotateForward();
	assert(equal(l.Range,[6,5,7]));

	l.clear();
	l.insert(n1);
	l.insert(n2);
	l.insert(n3);
	l.removeNode(n2);
	assert(equal(l.Range,[7,5]));

	l.clear();
	l.insert(n1);
	l.insert(n2);
	l.insert(n3);
	l.removeNode(n3);
	assert(equal(l.Range,[6,5]));

	l.clear();
	l.insert(n1);
	l.insert(n2);
	l.insert(n3);
	l.removeNode(n1);
	assert(equal(l.Range,[7,6]));
}