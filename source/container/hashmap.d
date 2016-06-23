module container.hashmap;
import container.clist;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
alias alloc = Mallocator.instance;

// Extramly simple hash map

struct Hashmap(Key, Value, size_t size) {
	private struct entry{
		Key k;
		Value v;
	}
	private struct Data
	{
		CList!(entry)[size] table;
		size_t count = 0;
		uint ref_count = 1;
	}
	private Data* data;

	this(this) { if(data != null) data.ref_count ++; }
	~this() { opAssign(null); }

	void opAssign(typeof(null) n) {
		if(data == null) return; 

		data.ref_count--;
		if(data.ref_count == 0) {
			clear();
			alloc.dispose(data);
		}
		data = null;
	}

	bool opEquals(typeof(null) rhs) {
		return data == null || data.count == 0;
	}

	bool opEquals(typeof(this) rhs) {
		return this.data == rhs.data;
	}

	size_t length() @property
	{
		pragma(inline, true);
		if(data == null) return 0;
		return data.count;
	}

	void clear() {
		if(data == null) return;
		foreach(ref l; data.table) l.clear(); 
	}

	ref Value opIndex(Key k) {
		if(data == null) data = alloc.make!Data();

		size_t index = hashOf(k)%size;
		if(data.table[index].length != 0) {
			foreach(ref l; data.table[index][]) {
				if(l.k == k) {
					// Entry already in list, return
					return l.v;
				}
			}
		}
		// Not in the list already, put in an empty entry
		auto n = data.table[index].insert(entry(k));
		data.count++;
		return n.data.v;
	}

	void remove(Key k) {
		if(data == null) return;

		size_t index = hashOf(k)%size;
		if(data.table[index].length != 0) {
			CList!(entry).Node* found_node = null;
			foreach(ref l; data.table[index].NodeRange) {
				if(l.data.k == k) {
					found_node = l;
					break;
				}
			}
			if(found_node != null){
				data.table[index].removeNode(found_node);
				data.count--;
				return;
			}
		}
	}

	Value* opBinaryRight(string op: "in")(Key k) {
		if(data == null) return null;

		size_t index = hashOf(k)%size;
		if(data.table[index].length != 0) {
			foreach(ref l; data.table[index][]) {
				if(l.k == k) {
					// Entry in list, return
					return &(l.v);
				}
			}
		}
		// Not in the list
		return null;
	}

	auto Range() {
		import std.typecons:Tuple;
		import std.range;
		import std.traits:ReturnType;
		struct Result{
			private CList!(entry)[] table;
			private typeof(table[0].Range()) cur;
			private size_t index;
			
			bool empty;
			Tuple!(Key, RefHack!(Value)) front() { return typeof(return)(cur.front.k,refHack(cur.front.v)); }
			void popFront() {
				cur.popFront();
				if(cur.empty) {
					index ++;
					for(; index < size; index++) {
						if(table[index].length != 0) {
							cur = table[index].Range();
							break;
						}
					}
					if(index == size) {
						empty = true;
						table = null;
					}
				}
			}
		}
		
		static assert(isInputRange!(Result));

		if(data == null || data.count == 0) {
			Result r;
			r.table = null;
			r.index = 0;
			r.empty = true;
			return r;
		}


		size_t i;
		for(i = 0; i < size; i++) {
			if(data.table[i].length != 0) break;
		}

		assert(i != size);
		Result r;
		r.table = data.table;
		r.index = i;
		r.empty = false;
		r.cur = data.table[i].Range();
		return r;
	}
}

private struct RefHack(T) {
	T* ptr;
	ref get() @property { return *ptr; }
	alias get this;
}
private auto refHack(T)(ref T a) { return RefHack!T(&a); }

unittest
{
	{
		Hashmap!(string, int, 1024) map;
		map["A"] = 5;
		assert(map["A"] == 5);
		map["A"] = 6;
		assert(map["A"] == 6);
		assert(map.length == 1);

		map["B name"] = 7;
		assert(map["A"] == 6);
		assert(map["B name"] == 7);
		assert(map.length == 2);

		map.remove("A");
		assert(map.length == 1);
		assert("A" !in map);
		assert("B name" in map);
		auto p = "B name" in map;
		p[0] = 8;
		assert(map["B name"] == 8);
	}

	{
		Hashmap!(string, int, 1) map; // Should 100% collide 
		map["A"] = 5;
		assert(map["A"] == 5);
		map["A"] = 6;
		assert(map["A"] == 6);
		assert(map.length == 1);

		map["B name"] = 7;
		assert(map["A"] == 6);
		assert(map["B name"] == 7);
		assert(map.length == 2);
	}

	//{
	//    import container.rstring;
	//    Hashmap!(rstring, int, 1024) map;
	//    map["test"] = 10;
	//
	//}
	
	//{
	//    import std.stdio;
	//    Hashmap!(string, int, 1024) map;
	//    map["A test"] = 5;
	//    map["c test"] = 6;
	//    map["foo"] = 7;
	//    
	//    foreach(k,v; map.Range()) {
	//        writeln("Key = ", k, " V = ", v);
	//    }
	//
	//}

}