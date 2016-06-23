module util.serial2;

import std.experimental.allocator.mallocator;
import std.experimental.allocator;
import std.range;
import std.traits;
import std.digest.md;
import std.meta:AliasSeq;
import container.ubyteBuffer;

// This is a bit of a leaner serializer, from some very simple tests, this seems to be about 5 times smaller than the previous serializer 
// That is a big difference, the down side is there is basicly no way to deal with updated type layouts

enum SerialSkip;

class Serializer{
	private MD5 hash;
	private ubyteBuffer buffer;
	private bool disable_startstop = false;
	private bool started = false;
	private bool doHash = true;

	this() {}

	this(bool doMD5Hash) {
		doHash = doMD5Hash;
	}

	void start() {
		assert(disable_startstop == false);
		assert(started == false);
		if(doHash) hash.start();
		started = true;
	}

	ubyte[] stop() {
		assert(disable_startstop == false);
		assert(started == true);
		if(doHash) {
			ubyte[16] result = hash.finish();
			buffer.write(result);
		}
		auto ret = buffer.getBuffer();
		buffer.clear();
		started = false;
		return ret;
	}

	void serialize(T)(T t) {
		assert(started == true);
		auto temp = disable_startstop;
		disable_startstop = true;
		scope(exit) disable_startstop = temp;

		static if(hasSimpleSerial!T) {
			alias simple = simpleSerial!(T);
			simple.write(t, this);
		} else static if(is(T == struct) || is(T == class)) {
			foreach(m;serialMembers!T) {
				serialize(mixin("t." ~ m));
			}
		} else {
			static assert(false);
		}
	}


	private void basicWrite(T)(T t) if(isBasicType!T) {	ubyte* p = cast(ubyte*)(&t);
		if(doHash) hash.put(p[0 .. T.sizeof]);
		buffer.write(p[0 .. T.sizeof]);
	}

	

}


class Deserializer{
	private ubyte[] input;
	private MD5 hash;
	private bool disable_startstop = false;
	private bool started = false;
	private bool doHash = true;
	
	this() {}
	this(bool doMD5Hash) {
		doHash = doMD5Hash;
	}

	void start(ubyte[] sourceData) {
		assert(disable_startstop == false);
		assert(started == false);
		if(doHash) hash.start();
		input = sourceData;
		started = true;
	}

	void stop() {
		import std.algorithm:equal;
		assert(disable_startstop == false);
		assert(started == true);
		started = false;
		if(doHash) {
			ubyte[16] result = hash.finish();
			if(input.length < 16) throw new Exception("Ran out of input");
			if(!equal(result[0..16], input[0..16])) throw new Exception("MD5 hash mismatch");
		}
		input = null;
	}

	void deserialize(T)(ref T t) {
		assert(started == true);
		auto temp = disable_startstop;
		disable_startstop = true;
		scope(exit) disable_startstop = temp;

		static if(hasSimpleSerial!T) {
			alias simple = simpleSerial!(T);
			simple.read(t, this);
		} else static if(is(T == struct) || is(T == class)) {
			foreach(m;serialMembers!T) {
				deserialize(mixin("t." ~ m));
			}
		} else {
			static assert(false);
		}
	}

	private void basicRead(T)(ref T v) {
		if(input.length < T.sizeof) throw new Exception("Ran out of input");
		ubyte* p = cast(ubyte*)(&v);
		p[0 .. T.sizeof] = input[0 .. T.sizeof];
		if(doHash) hash.put(input[0 .. T.sizeof]);
		input = input[T.sizeof .. $];
	}
}


private template serialMembers(T) {
	template rec(Members ...) {
		static if(Members.length == 0) {
			alias rec = AliasSeq!();
		} else static if(__traits(compiles, (T t, Serializer s, Deserializer d) {
			enum M = Members[0];
			static assert(
						__traits(compiles, typeof(mixin("T." ~ M))) &&		// Member has a type
						!isCallable!(mixin("T." ~ M)) && 					// Member not a function
						!(hasUDA!(mixin("T." ~ M), SerialSkip))				// We shouldnt skip it
						);
			s.serialize(mixin("t." ~ M));	// can actually serial the member
			d.deserialize(mixin("t." ~ M));	// can actually deserialize the member
		})) {
			alias rec = AliasSeq!(Members[0], rec!(Members[1..$]));
		} else {
			alias rec = rec!(Members[1..$]);
		}
	}

	alias serialMembers = rec!(staticSort!(Compar,__traits(allMembers, T))); // sort to make sure there is a deffinitive order. 
}

private enum Compar(alias A, alias B) = A < B;

private template staticSort(alias cmp, Seq...) {
    static if (Seq.length < 2) {
        alias staticSort = Seq; 
    } else {
        private alias bottom = staticSort!(cmp, Seq[0 .. $ / 2]);
        private alias top = staticSort!(cmp, Seq[$ / 2 .. $]);
        alias staticSort = staticMerge!(cmp, Seq.length / 2, bottom, top);
    }
}

private template staticMerge(alias cmp, int half, Seq...) {
    static if (half == 0 || half == Seq.length) {
        alias staticMerge = Seq;
    } else {
        private enum Result = cmp!(Seq[0], Seq[half]);
        static if (is(typeof(Result) == bool)) {
            private enum Check = Result;
        } else static if (is(typeof(Result) : int)) {
            private enum Check = Result <= 0;
        } else {
            static assert(0, typeof(Result).stringof ~ " is not a value comparison type");
        }
        static if (Check) {
            alias staticMerge = AliasSeq!(Seq[0], staticMerge!(cmp, half - 1, Seq[1 .. $]));
        } else {
            alias staticMerge = AliasSeq!(Seq[half], staticMerge!(cmp, half,
																  Seq[0 .. half], Seq[half + 1 .. $]));
        }
    }
}


// Basic types
private template simpleSerial(T) if(isBasicType!T) {
	void write(T v, Serializer s) {
		s.basicWrite(v);
	}

	void read(ref T v, Deserializer d) {
		d.basicRead(v);
	}
}

// Static arrays
private template simpleSerial(T) if(isStaticArray!T) {
	void write(T v, Serializer s) {
		foreach(m; v) s.serialize(m); 
	}

	void read(ref T v, Deserializer d) {
		foreach(ref m; v) d.deserialize(m); 
	}
}

// Dynamic arrays
private template simpleSerial(T) if(isDynamicArray!T) {
	static if(is(T E: E[]))
		alias U = Unqual!(E);
	else static assert(0);

	void write(T v, Serializer s) {
		ulong len = v.length;
		s.serialize(len);
		foreach(m; v) s.serialize(m); 
	}

	void read(ref T v, Deserializer d) {
		ulong len;
		d.deserialize(len); 
		auto a = Mallocator.instance.makeArray!U(len);
		foreach(ref m; a) d.deserialize(m); 
		v = cast(T)a;
	}
}

// Vector/Matrix types
import math.matrix;
private template simpleSerial(T) if(isMatrix!T || isVector!T) {
	void write(T v, Serializer s) {
		s.serialize(v.data);
	}

	void read(ref T v, Deserializer d) {
		d.deserialize(v.data); 
	}
}

// Color
import graphics.color;
private template simpleSerial(T) if(is(T == Color)) {
	void write(T v, Serializer s) {
		s.serialize(v.RGBA);
	}

	void read(ref T v, Deserializer d) {
		d.deserialize(v.RGBA); 
	}
}

// rstring
import container.rstring;
private template simpleSerial(T) if(is(T== rstring)) {
	void write(T v, Serializer s) {
		ulong len = v.length;
		s.serialize(len);
		foreach(m; v) s.serialize(m); 
	}

	void read(ref T v, Deserializer d) {
		ulong len;
		d.deserialize(len); 
		auto a = Mallocator.instance.makeArray!dchar(len);
		foreach(ref m; a) d.deserialize(m); 
		v = a;
		Mallocator.instance.dispose(a);
	}
}

// Custom serial
private template simpleSerial(T) if(hasCustomSerial!T) {
	void write(T v, Serializer s) {
		v.customSerialize(s);
	}

	void read(ref T v, Deserializer d) {
		v.customDeserialize(d);
	}
}

private template hasCustomSerial(T) {
	enum hasCustomSerial = __traits(compiles, (T t, Serializer s, Deserializer d) {
		t.customSerialize(s);
		t.customDeserialize(d);
	});
}

private template hasSimpleSerial(T) {
	enum hasSimpleSerial = __traits(compiles, (T x, Serializer s, Deserializer d) {
		alias ts = simpleSerial!T;
		ts.write(x, s);
		ts.read(x, d); 
	});
}

private template hasSerial(T) {
	enum hasSerial = __traits(compiles, (T x, Serializer s, Deserializer d) {
		s.serialize(x);
		d.deserialize(x); 
	});
}

static assert(hasSerial!ubyte);
static assert(hasSerial!ushort);
static assert(hasSerial!uint);
static assert(hasSerial!ulong);
static assert(hasSerial!byte);
static assert(hasSerial!short);
static assert(hasSerial!int);
static assert(hasSerial!long);
static assert(hasSerial!char);
static assert(hasSerial!dchar);
static assert(hasSerial!wchar);
static assert(hasSerial!float);
static assert(hasSerial!double);
static assert(hasSerial!real);
static assert(hasSerial!bool);
static assert(hasSerial!size_t);
static assert(hasSerial!(int[5]));
static assert(hasSerial!(double[10]));
static assert(hasSerial!vec2);
static assert(hasSerial!vec3);
static assert(hasSerial!vec4);
static assert(hasSerial!mat2);
static assert(hasSerial!mat3);
static assert(hasSerial!mat4);
static assert(hasSerial!quatern);
static assert(hasSerial!Color);
static assert(hasSerial!(int[]));
static assert(hasSerial!(string));
static assert(hasSerial!(rstring));


unittest{
	struct foo{
		int a;
		double b;
		vec3 c;
		@SerialSkip int skip;
		rstring s;
	}

	struct bar{
		int x;
		int y = 0;
		void customSerialize(Serializer s) {
			s.serialize(x+1);
			y=1;
		}

		void customDeserialize(Deserializer d) {
			d.deserialize(x);
			y=2;
		}
	}
	
	{
		Serializer s = new Serializer();
		s.start();
		{
			s.serialize!int(5);
			s.serialize!float(10.0f);
			foo f;
			f.a = 20;
			f.b = 3.14;
			f.c = vec3(1,2,3);
			f.skip = 404;
			f.s = "hello world";
			s.serialize(f);
			bar b;
			b.x = 10;
			s.serialize(&b);
			assert(b.y == 1);
		}
		ubyte[] data = s.stop();

		Deserializer d = new Deserializer;
		d.start(data);
		{
			int a;
			d.deserialize(a);
			assert(a == 5);
			float b;
			d.deserialize(b);
			assert(b == 10.0f);
			foo c;
			d.deserialize(c);
			assert(c.a == 20);
			assert(c.b == 3.14);
			assert(c.c == vec3(1,2,3));
			assert(c.skip != 404);
			assert(c.s == "hello world");

			bar bb;
			d.deserialize(bb);
			assert(bb.x == 11);
			assert(bb.y == 2);
		}
		d.stop();
		Mallocator.instance.dispose(data);
	}
}
