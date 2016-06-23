module container.rstring;

import std.experimental.allocator;
import std.experimental.allocator.mallocator;

/// A refcounted string that does not use the gc
struct rstring
{
	private alias alloc = Mallocator.instance;
	private struct Data {
		dchar[] string = null;
		uint ref_count = 1;
	}
	private Data* data;

	this(const(dchar)[] string) @nogc {
		pragma(inline,true);
		opAssign(string);
	}

	this(this) @nogc {
		pragma(inline,true);
		if(data != null) data.ref_count ++;
	}

	~this() @nogc {
		pragma(inline,true);
		opAssign(null);
	}

	void opAssign(typeof(null) n) @nogc {
		//pragma(inline,true);
		if(data == null) return; 
		data.ref_count--;
		if(data.ref_count == 0) {
			alloc.dispose(data.string);
			alloc.dispose(data);
		}
		data = null;
	}

	void opAssign(const(dchar)[] string) @nogc {
		//pragma(inline,true);
		opAssign(null);
		if(string.length == 0) return;
		init(); 
		data.string = makeArray!dchar(alloc, string.length);
		data.string[] = string[];
	}

	bool opEquals(typeof(null) rhs) @nogc {
		pragma(inline,true);
		return data == null;
	}

	bool opEquals(const(dchar)[] string) @nogc {
		pragma(inline,true);
		import std.algorithm;
		if(data == null) return string.length == 0;
		return equal(data.string, string);
	}

	bool opEquals(rstring string) @nogc {
		//pragma(inline,true);
		import std.algorithm;
		if(data == string.data) return true;
		else if(data == null || string.data == null) return false;
		else return equal(data.string, string.data.string);
	}

	immutable(dchar) opIndex(size_t i) @nogc {
		pragma(inline,true);
		return data.string[i];
	}

	size_t length() @nogc {
		pragma(inline,true);
		if(data == null) return 0;
		else return data.string.length;
	}

	immutable(dchar)[] opIndex() @nogc {
		pragma(inline,true);
		if(data==null) return null;
		else return cast(immutable)(data.string);
	}

	rstring opBinary(string op : "~")(rstring rhs) {
		pragma(inline,true);
		return opBinary!"~"(rhs[]);
	}

	rstring opBinary(string op : "~")(const(dchar)[] rhs) {
		pragma(inline,true);
		return cat(this[], rhs);
	}

	rstring opBinaryRight(string op : "~")(const(dchar)[] lhs) {
		pragma(inline,true);
		return cat(lhs, this[]);
	}

	void opOpAssign(string op : "~")(rstring right) {
		pragma(inline,true);
		this = cat(this[], right[]);
	}

	void opOpAssign(string op : "~")(const(dchar)[] right) {
		pragma(inline,true);
		this = cat(this[], right);
	}
	

	private rstring cat(const(dchar)[] lhs, const(dchar)[] rhs) {
		pragma(inline,true);
		rstring rtn;
		rtn.init();
		auto l = lhs.length;
		auto r = rhs.length;
		rtn.data.string = alloc.makeArray!dchar(l + r);
		rtn.data.string[0..l][] = lhs[];
		rtn.data.string[l..$][] = rhs[];
		return rtn;
	}


	dstring to(T : dstring)() { // Only thing that gc allocates
		pragma(inline,true);
		return opIndex().idup;
	}

	private void init() @nogc {
		pragma(inline,true);
		data = alloc.make!Data();
	}

	size_t toHash() {
		if(data == null) return 0; 
		return hashOf(data.string);
	}
}

unittest
{
	import std.algorithm;
	import std.array;
	import std.stdio;
	rstring test = "test";
	assert(test.data.ref_count == 1);
	{
		rstring copy = test;
		assert(test.data.ref_count == 2);
		rstring copy2;
		assert(copy2 == null);
		copy2 = "";
		assert(copy2 == null);
		copy2 = null;
		assert(copy2 == null);
		copy2 = test;
		assert(test.data.ref_count == 3);
	}
	assert(test.data.ref_count == 1);
	assert(test != null);
	test = "test: this is a longer string";
	test = "short";
	assert(test[].map!(a=>dchar(a+1)).equal("tipsu"));
	dstring s = "dstring";
	test = s;
	assert(test == s);
	{
		rstring a = "a";
		rstring b = "b";
		rstring c = a~b;
		assert(c == "ab");
		rstring d = c ~ "d";
		assert(d == "abd");
		rstring e = "e" ~ a;
		assert(e == "ea");
		e ~= a;
		assert(e == "eaa");
		e ~= "1";
		assert(e == "eaa1");
		rstring f;
		assert(f == null);
		assert(f == "");
		f ~= "f";
		assert(f == "f");
	}

	{
		rstring a = "test";
		rstring b = "test";
		rstring c = "other test";
		rstring d;
		assert(hashOf(a) == hashOf(b));
		assert(hashOf(a) != hashOf(c));
		assert(hashOf(a) != hashOf(d));
		assert(hashOf(c) != hashOf(d));
	}
}