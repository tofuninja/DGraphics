module math.geo.vector;
import std.traits;
import std.math;
import core.simd;
import util.integerSeq;

alias vec2 = VectorT!(2, float);
alias vec3 = VectorT!(3, float);
alias vec4 = VectorT!(4, float);

alias dvec2 = VectorT!(2, double);
alias dvec3 = VectorT!(3, double);
alias dvec4 = VectorT!(4, double);

alias ivec2 = VectorT!(2, int);
alias ivec3 = VectorT!(3, int);
alias ivec4 = VectorT!(4, int);

alias uvec2 = VectorT!(2, uint);
alias uvec3 = VectorT!(3, uint);
alias uvec4 = VectorT!(4, uint);


struct VectorT(uint size, T) {
	alias ELEMENT_TYPE = T;
	enum SIZE = size;

	static assert(size < 5 && size > 1,"Size must be less than 5 and greater than 1");
	static assert(isNumeric!T);

	// If we have a vec4 use simd to make this thing faster
	enum USE_SIMD = (size == 4 && is(T == float) && is(float4));
	

	static if(USE_SIMD) {
		union{
			float[4] data = {
				float[4] r;
				r[] = 0; // init all vectors to 0
				return r;
			}();
			private float4 simd_data;
		}
	} else {
		T[size] data = {
			T[size] r;
			r[] = 0; // init all vectors to 0
			return r;
		}();
	}

	this(T[size]value...) {
		pragma(inline, true);
		data = value;
	}

	public this(T value) {
		pragma(inline, true);
		foreach(i; IntegerSeq!(0, size)) {
			data[i] = value;
		}
	}
	
	auto opBinary(string op : "+")(VectorT!(size, T) rhs) {
		pragma(inline, true);
		static if(USE_SIMD) {
			VectorT!(size, T) ret; 
			ret.simd_data = simd_data + rhs.simd_data;
			return ret;
		} else {
			VectorT!(size, T) ret; 
			foreach(i; IntegerSeq!(0, size)) {
				ret.data[i] = data[i] + rhs.data[i];
			}
			return ret;
		}
	}
	
	auto opBinary(string op : "-")(VectorT!(size, T) rhs) {
		pragma(inline, true);
		static if(USE_SIMD) {
			VectorT!(size, T) ret; 
			ret.simd_data = simd_data - rhs.simd_data;
			return ret;
		} else {
			VectorT!(size, T) ret; 
			foreach(i; IntegerSeq!(0, size)) {
				ret.data[i] = data[i] - rhs.data[i];
			}
			return ret;
		}
	}

	auto opBinary(string op : "*")(VectorT!(size, T) rhs) {
		pragma(inline, true);
		static if(USE_SIMD) {
			VectorT!(size, T) ret; 
			ret.simd_data = simd_data * rhs.simd_data;
			return ret;
		} else {
			VectorT!(size, T) ret; 
			foreach(i; IntegerSeq!(0, size)) {
				ret.data[i] = data[i] * rhs.data[i];
			}
			return ret;
		}
	}

	auto opBinary(string op : "*")(T rhs) {
		pragma(inline, true);
		VectorT!(size, T) ret; 
		foreach(i; IntegerSeq!(0, size)) {
			ret.data[i] = data[i] * rhs;
		}
		return ret;
		
	}

	auto opBinaryRight(string op : "*")(T lhs) {
		pragma(inline, true);
		return opBinary!"*"(lhs);
	}

	auto opBinary(string op : "/")(VectorT!(size, T) rhs) {
		pragma(inline, true);
		static if(USE_SIMD) {
			VectorT!(size, T) ret; 
			ret.simd_data = simd_data / rhs.simd_data;
			return ret;
		} else {
			VectorT!(size, T) ret; 
			foreach(i; IntegerSeq!(0, size)) {
				ret.data[i] = data[i] / rhs.data[i];
			}
			return ret;
		}
	}
	
	auto opBinary(string op : "/")(T rhs) {
		pragma(inline, true);
		VectorT!(size, T) ret; 
		foreach(i; IntegerSeq!(0, size)) {
			ret.data[i] = data[i] / rhs;
		}
		return ret;
	}

	auto opBinary(string op : "~")(T rhs) if(size + 1 <= 4) {
		pragma(inline, true);
		VectorT!(size+1, T) ret; 
		foreach(i; IntegerSeq!(0, size)) {
			ret.data[i] = data[i];
		}
		ret.data[size] = rhs;
		return ret;
	}

	auto opBinaryRight(string op : "~")(T lhs) if(size + 1 <= 4) {
		pragma(inline, true);
		VectorT!(size+1, T) ret; 
		ret.data[0] = lhs;
		foreach(i; IntegerSeq!(0, size)) {
			ret.data[i+1] = data[i];
		}
		return ret;
	}

	auto opBinary(string op : "~", uint L)(VectorT!(L, T) rhs) if(size + L <= 4) {
		pragma(inline, true);
		VectorT!(size+L, T) ret; 
		foreach(i; IntegerSeq!(0, size)) {
			ret.data[i] = data[i];
		}
		
		foreach(i; IntegerSeq!(0, L)) {
			ret.data[size+i] = rhs.data[i];
		}
		return ret;
	}

	auto opOpAssign(string op, R)(R rhs) {
		this = opBinary!(op)(rhs);
		return this;
	}
	
	bool opEquals(VectorT!(size, T) rhs) {
		pragma(inline,true);
		return data == rhs.data;
	}

	ref T opIndex(size_t i) {
		pragma(inline,true);
		return data[i];
	}

	// Swizzle
	auto ref opDispatch(string s)() {
		pragma(inline, true);
		static assert(s.length <= 4, "Swizzel mask too long");
		enum int l = s.length;
		static if(l == 1) {
			static if(s[0] == 'x') return data[0];
			else static if(s[0] == 'y') return data[1];
			else static if(s[0] == 'z') return data[2];
			else static if(s[0] == 'w') return data[3];
			else static assert(false, "Invalid Swizzel");
		} else {
			VectorT!(l, T) ret;
			foreach(i; IntegerSeq!(0, l)) {
				static if(s[i] == 'x') ret.data[i] = data[0];
				else static if(s[i] == 'y') ret.data[i] = data[1];
				else static if(s[i] == 'z') ret.data[i] = data[2];
				else static if(s[i] == 'w') ret.data[i] = data[3];
				else static assert(false, "Invalid Swizzel");
			}
			return ret;
		}
	}

	void opDispatch(string s, uint l)(VectorT!(l, T) rhs) {
		pragma(inline, true);
		static assert(s.length <= 4, "Swizzel mask too long");
		static assert(s.length == l, "Invalid Swizzel");

		foreach(i; IntegerSeq!(0, l)) {
			static if(s[i] == 'x') data[0] = rhs.data[i];
			else static if(s[i] == 'y') data[1] = rhs.data[i];
			else static if(s[i] == 'z') data[2] = rhs.data[i];
			else static if(s[i] == 'w') data[3] = rhs.data[i];
			else static assert(false, "Invalid Swizzel");
		}
	}

	void opDispatch(string s)(T v) {
		pragma(inline, true);
		static assert(s.length <= 4, "Swizzel mask too long");
		enum int l = s.length;

		foreach(i; IntegerSeq!(0, l)) {
			static if(s[i] == 'x') data[0] = v;
			else static if(s[i] == 'y') data[1] = v;
			else static if(s[i] == 'z') data[2] = v;
			else static if(s[i] == 'w') data[3] = v;
			else static assert(false, "Invalid Swizzel");
		}
	}

	auto opUnary(string op : "-")() {
		pragma(inline, true);
		static if(USE_SIMD) {
			VectorT!(size,T) rtn;
			rtn.simd_data = -simd_data;
			return rtn;
		} else {
			VectorT!(size,T) rtn;
			foreach(i; IntegerSeq!(0, size)) {
				rtn.data[i] = -data[i];
			}
			return rtn;
		}
	}

	auto opCast(T2 : VectorT!(size, T2))() {
		pragma(inline, true);
		static assert(__traits(compiles, cast(T2)T.init), "No cast from " ~ T.stringof ~ " to " ~ T2.stringof);
		VectorT!(size, T2) rtn;
		foreach(i; IntegerSeq!(0, size)) {
			rtn.data[i] = cast(T2)data[i];
		}
		return rtn;
	}

	string toString() {
		import std.conv;
		return data.to!string;
	}
}

auto horizontalSum(uint size, T)(VectorT!(size, T) value) {
	pragma(inline, true);
	static if(value.USE_SIMD) {
		auto t = __simd(XMM.HADDPS, value.simd_data, value.simd_data);
		t = __simd(XMM.HADDPS, t, t);
		return (cast(float[4])(t))[0];
	} else {
		T sum = 0;
		foreach(i; IntegerSeq!(0, size)) {
			sum += value.data[i];
		}
		return sum;
	}
}

auto dot(uint size, T)(VectorT!(size, T) a, VectorT!(size, T) b) {
	pragma(inline, true);
	return horizontalSum(a*b);
}

auto length(uint size, T)(VectorT!(size, T) a) {
	pragma(inline, true);
	return sqrt(dot(a,a));
}

auto angle(uint size, T)(VectorT!(size, T) a, VectorT!(size, T) b) {
	pragma(inline, true);
	return acos(dot(a,b)/(length(a)*length(b)));
}

auto signedAngle(uint size, T)(VectorT!(size, T) a, VectorT!(size, T) b, VectorT!(size, T) n) {
	pragma(inline, true);
	return angle(a,b)*sgn(dot(n,cross(a,b)));
}

auto projection(uint size, T)(VectorT!(size, T) a, VectorT!(size, T) b) {
	auto n = normalize(b);
	return dot(a,n)*n;
}

auto cross(T)(VectorT!(3,T) a, VectorT!(3,T) b) {
	pragma(inline, true);
	VectorT!(3,T) rtn;
	rtn[0] = a[1]*b[2] - a[2]*b[1];
	rtn[1] = a[2]*b[0] - a[0]*b[2];
	rtn[2] = a[0]*b[1] - a[1]*b[0];
	return rtn;
}

auto normalize(uint size, T)(VectorT!(size,T) a) {
	pragma(inline, true);
	return a/(length(a));
}

auto lerp(uint size, T)(VectorT!(size,T) a, VectorT!(size,T) b, T percent) {
	pragma(inline, true);
	VectorT!(size,T) rtn;
	foreach(i; IntegerSeq!(0, size)) {
		rtn.data[i] = a.data[i] + (b.data[i] - a.data[i])*percent;
	}
	return rtn;
} 

template isVector(T) {
	enum isVector = isInstanceOf!(VectorT, T);
}

unittest{
	import std.stdio;
	
	{
		auto v2 = vec2(1,2);
		auto v3 = vec3(1,2,3);
		auto v4 = vec4(1,2,3,4);
	}
	{
		auto a = vec2(1,2);
		auto b = vec2(3,4);
		assert(a+b ==  vec2(4,6));
	}
	{
		auto a = vec3(1,2,3);
		auto b = vec3(4,5,6);
		assert(a+b ==  vec3(5,7,9));
	}
	{
		auto a = vec4(1,2,3,4);
		auto b = vec4(5,6,7,8);
		assert(a+b ==  vec4(6,8,10,12));
	}
	{
		auto a = vec4(1,2,3,4);
		auto b = vec4(5,6,7,8);
		assert(a-b ==  vec4(-4,-4,-4,-4));
	}
	{
		auto a = vec4(1,2,3,4);
		auto b = vec4(5,6,7,8);
		assert(a*b ==  vec4(5,12,21,32));
	}
	{
		auto a = vec4(10,12,14,16);
		auto b = vec4(2,6,7,4);
		assert(a/b ==  vec4(5,2,2,4));
	}
	{
		assert(horizontalSum(vec2(1,2)) == 3);
		assert(horizontalSum(vec3(1,2,3)) == 6);
		assert(horizontalSum(vec4(1,2,3,4)) == 10);
	}
	{
		assert(dot(vec2(1,2), vec2(3,4)) == 11);
		assert(dot(vec3(1,2,3), vec3(3,4,5)) == 26);
		assert(dot(vec4(1,2,3,4), vec4(3,4,5,6)) == 50);
	}
	{
		assert(length(vec2(3,4)) == 5);
		assert(length(vec3(3,4,12)) == 13);
		assert(length(vec4(1,1,1,1)) == 2);
	}
	{
		auto v = vec4(1,2,3,4);
		assert(v.wzyx == vec4(4,3,2,1));
		assert(v.xxxx == vec4(1,1,1,1));
		assert(v.x == 1);
		assert(v.y == 2);
		assert(v.xy == vec2(1,2));
		assert(v.xy.xxxx == vec4(1,1,1,1));
		v.xy = vec2(5,6);
		assert(v == vec4(5,6,3,4));
		v.xyzw = 0;
		assert(v == vec4(0,0,0,0));
		v.x += 4;
		assert(v == vec4(4,0,0,0));
	}
	{
		auto a = vec4(1,2,3,4);
		assert(a*2 == vec4(2,4,6,8));
		assert(2*a == vec4(2,4,6,8));
		auto b = vec4(2,4,6,8);
		assert(b/2 == vec4(1,2,3,4));
	}
	{
		assert(-vec2(1,2) == vec2(-1,-2));
		assert(-vec3(1,2,3) == vec3(-1,-2,-3));
		assert(-vec4(1,2,3,4) == vec4(-1,-2,-3,-4));
	}
	{
		assert(1 ~ vec2(2,3) == vec3(1,2,3));
		assert(vec2(1,2) ~ 3 == vec3(1,2,3));
		assert(vec2(1,2) ~ vec2(3,4) == vec4(1,2,3,4));
	}
	{
		assert(cross(vec3(3,-3,1), vec3(4,9,2)) == vec3(-15, -2, 39));
	}
	{
		assert(normalize(vec3(3,5,6)).length == 1);
	}
	{
		assert(lerp(vec4(0,0,1,5), vec4(0,0,5,1), 0.5f) == vec4(0,0,3,3));
	}
	{
		assert(cast(vec2)dvec2(1,2) == vec2(1,2));
	}
	{
		assert(isVector!vec2);
		assert(!isVector!int);
	}
	{
		vec2 a = vec2(1,2);
		a += vec2(3,4);
		assert(a == vec2(4,6));
		a *= 2;
		assert(a == vec2(8,12));
		a /= 4;
		assert(a == vec2(2,3));
	}
}
