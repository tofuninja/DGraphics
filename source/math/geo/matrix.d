module math.geo.matrix;
import std.traits;
import std.math;
import core.simd;
import util.integerSeq;
import math.geo.vector;
import math.geo.quaternion;

alias mat2 = MatrixT!(2, float);
alias mat3 = MatrixT!(3, float);
alias mat4 = MatrixT!(4, float);

alias dmat2 = MatrixT!(2, double);
alias dmat3 = MatrixT!(3, double);
alias dmat4 = MatrixT!(4, double);

struct MatrixT(uint size, T) {
	alias ELEMENT_TYPE = T;
	enum SIZE = size;
	static assert(size < 5 && size > 1,"Size must be less than 5 and greater than 1");
	static assert(isNumeric!T);

	T[size*size] data = {
		T[size*size] r;
		r[] = 0; // init all vectors to 0
		return r;
	}();

	this(VectorT!(size, T)[size] rows...) {
		pragma(inline, true);
		foreach(i; IntegerSeq!(0, size)) {
			foreach(j; IntegerSeq!(0, size)) {
				this[i,j] = rows[i][j];
			}
		}
	}

	this(T[size*size] value...) {
		pragma(inline, true);
		foreach(i; IntegerSeq!(0, size)) {
			foreach(j; IntegerSeq!(0, size)) {
				this[i,j] = value[i*size+j];
			}
		}
	}

	auto opBinary(string op : "*")(MatrixT!(size, T) rhs) {
		//pragma(inline, true);
		MatrixT!(size, T) rtn;
		foreach(i; IntegerSeq!(0, size)) {
			foreach(j; IntegerSeq!(0, size)) {
				auto r = this.getRow(i);
				auto c = rhs.getCol(j);
				rtn[i,j] = horizontalSum(r*c);
			}
		}
		return rtn;
	}

	auto opBinary(string op : "*")(VectorT!(size, T) rhs) {
		//pragma(inline, true);
		VectorT!(size, T) rtn;
		foreach(i; IntegerSeq!(0, size)) {
			auto r = this.getRow(i);
			rtn[i] = horizontalSum(r*rhs);
		}
		return rtn;
	}

	auto opBinary(string op : "*")(T rhs) {
		pragma(inline, true);
		MatrixT!(size, T) rtn;
		foreach(i; IntegerSeq!(0, size*size)) {
			rtn.data[i] = data[i]*rhs;
		}
		return rtn;
	}

	auto opBinaryRight(string op : "*")(T lhs) {
		pragma(inline, true);
		return opBinary!"*"(lhs);
	}

	auto opBinary(string op : "/")(T rhs) {
		pragma(inline, true);
		MatrixT!(size, T) rtn;
		foreach(i; IntegerSeq!(0, size*size)) {
			rtn.data[i] = data[i]/rhs;
		}
		return rtn;
	}

	auto opOpAssign(string op, R)(R rhs) {
		this = opBinary!(op)(rhs);
		return this;
	}

	ref T opIndex(size_t row, size_t col) {
		pragma(inline, true);
		assert(row>=0,"Index out of bounds");
		assert(col>=0,"Index out of bounds");
		assert(row<size,"Index out of bounds");
		assert(col<size,"Index out of bounds");
		return data[row+size*col];
	}

	auto getRow(size_t row) {
		//pragma(inline, true);
		assert(row>=0,"Index out of bounds");
		assert(row<size,"Index out of bounds");
		VectorT!(size, T) ret;
		foreach(i; IntegerSeq!(0, size)) {
			ret[i] = this[row,i];
		}
		return ret;
	}

	auto getCol(size_t col) {
		//pragma(inline, true);
		assert(col>=0,"Index out of bounds");
		assert(col<size,"Index out of bounds");
		VectorT!(size, T) ret;
		foreach(i; IntegerSeq!(0, size)) {
			ret[i] = this[i,col];
		}
		return ret;
	}

	auto opCast(T2 : MatrixT!(size, T2))() {
		pragma(inline, true);
		static assert(__traits(compiles, cast(T2)T.init), "No cast from " ~ T.stringof ~ " to " ~ T2.stringof);
		MatrixT!(size, T2) rtn;
		foreach(i; IntegerSeq!(0, size*size)) {
			rtn.data[i] = cast(T2)data[i];
		}
		return rtn;
	}


	string toString() {
		import std.conv;
		string r = "[";
		foreach(i; IntegerSeq!(0, size)) {
			foreach(j; IntegerSeq!(0, size)) {
				T v = this[i,j];
				r~= v.to!string();
				r~= ", ";
			}
		}
		return r[0..$-2] ~ "]";
	}
}

auto identity(uint size, T)() {
	pragma(inline, true);
	MatrixT!(size, T) ret; 
	foreach(i; IntegerSeq!(0, size)) {
		ret[i,i] = 1;
	}
	return ret;
}

auto scalarMatrix(uint size, T)(T value) {
	pragma(inline, true);
	MatrixT!(size, T) ret; 
	foreach(i; IntegerSeq!(0, size)) {
		ret[i,i] = value;
	}
	return ret;
}

auto transpose(uint size, T)(MatrixT!(size, T) mat) {
	pragma(inline, true);
	MatrixT!(size, T) ret; 
	foreach(i; IntegerSeq!(0, size)) {
		foreach(j; IntegerSeq!(0, size)) {
			ret[j,i] = mat[i,j];
		}
	}
	return ret;
}

auto minor(uint row, uint col, uint size, T)(MatrixT!(size, T) mat) if(size > 2) {
	MatrixT!(size-1, T) ret;
	foreach(i; IntegerSeq!(0, row)) {
		foreach(j; IntegerSeq!(0, col)) {
			ret[i,j] = mat[i,j];
		}
	}

	foreach(i; IntegerSeq!(row+1, size)) {
		foreach(j; IntegerSeq!(0, col)) {
			ret[i-1,j] = mat[i,j];
		}
	}

	foreach(i; IntegerSeq!(0, row)) {
		foreach(j; IntegerSeq!(col+1, size)) {
			ret[i,j-1] = mat[i,j];
		}
	}

	foreach(i; IntegerSeq!(row+1, size)) {
		foreach(j; IntegerSeq!(col+1, size)) {
			ret[i-1,j-1] = mat[i,j];
		}
	}
	return ret;
}

auto det(uint size, T)(MatrixT!(size, T) mat) {
	//pragma(inline, true);
	static if(size == 2) {
		return mat[0,0]*mat[1,1] - mat[0,1]*mat[1,0];
	} else static if(size == 3) {
		return mat[0,0]*det(mat.minor!(0,0)) - mat[0,1]*det(mat.minor!(0,1)) + mat[0,2]*det(mat.minor!(0,2));
	} else {
		return mat[0,0]*det(mat.minor!(0,0)) - mat[0,1]*det(mat.minor!(0,1)) + mat[0,2]*det(mat.minor!(0,2)) - mat[0,3]*det(mat.minor!(0,3));
	}
}

auto inverse(uint size, T)(MatrixT!(size, T) mat) {
	//pragma(inline, true);
	MatrixT!(size, T) ret;
	static if(size == 2) {
		ret[0,0] = mat[1,1];
		ret[1,0] = -mat[1,0];
		ret[0,1] = -mat[0,1];
		ret[1,1] = mat[0,0];
		return ret/det(mat);
	} else static if(size == 3) {
		foreach(i; IntegerSeq!(0, size)) {
			foreach(j; IntegerSeq!(0, size)) {
				static if((i+j)%2 == 0) {
					ret[i,j] = det(minor!(j,i)(mat));
				} else {
					ret[i,j] = det(flip(minor!(j,i)(mat)));
				}
			}
		}
		return ret/det(mat);
	} else {
		foreach(i; IntegerSeq!(0, size)) {
			foreach(j; IntegerSeq!(0, size)) {
				static if((i+j)%2 == 0) {
					ret[i,j] = det(minor!(j,i)(mat));
				} else {
					ret[i,j] = det(flip(minor!(j,i)(mat)));
				}
			}
		}
		return ret/det(mat);
	}
}

private auto flip(uint size, T)(MatrixT!(size, T) mat) {
	//pragma(inline, true);
	MatrixT!(size, T) ret;
	foreach(i; IntegerSeq!(0, size)) {
		foreach(j; IntegerSeq!(0, size)) {
			ret[i,j] = mat[i,size-j-1];
		}
	}
	return ret;
}


auto projectionMatrix(T)(T fov, T aspect, T nearDist, T farDist, bool leftHanded=true) {
	assert(fov > 0, "Fov is less than or equals to zero");
	assert(aspect != 0, "Aspect equals zero");

	auto result = identity!(4,T);
	T frustumDepth = farDist - nearDist;
	T oneOverDepth = 1 / frustumDepth;

	result[1,1] = cast(T)(1 / tan(0.5f * cast(real)fov));
	result[0,0] = ((leftHanded ? 1 : -1 ) * result[1,1] / aspect);
	result[2,2] = ((farDist + nearDist) * oneOverDepth);
	result[2,3] = -((2*farDist * nearDist) * oneOverDepth);
	result[3,2] = 1;
	result[3,3] = 0;

	return result;
}

auto orthoMatrix(T)(T width, T aspect, T nearDist, T farDist) {
	assert(width > 0, "Width is less than or equals to zero");
	assert(aspect != 0, "Aspect equals zero");

	auto result = identity!(4,T);
	T frustumDepth = farDist - nearDist;
	T oneOverDepth = 1 / frustumDepth;
	auto wo2 = width/2.0f;
	result[1,1] = cast(T)(1 / wo2);
	result[0,0] = result[1,1] / aspect;
	result[2,2] = 2 * oneOverDepth;
	result[2,3] = -((farDist + nearDist) * oneOverDepth);
	result[3,3] = 1;

	return result;
}

mat4 viewMatrix(T)(VectorT!(3,T) eye, VectorT!(3,T) target, VectorT!(3,T) up ) {
	auto zaxis = normalize(target - eye);		// The "forward" vector.
	auto xaxis = normalize(cross(up, zaxis));	// The "right" vector.
	auto yaxis = cross(zaxis, xaxis);			// The "up" vector.

	// Create a 4x4 view matrix from the right, up, forward and eye position vectors
	auto viewMatrix = identity!(4,T);
	viewMatrix[0,0] = xaxis.x;
	viewMatrix[1,0] = yaxis.x;
	viewMatrix[2,0] = zaxis.x;
	viewMatrix[0,1] = xaxis.y;
	viewMatrix[1,1] = yaxis.y;
	viewMatrix[2,1] = zaxis.y;
	viewMatrix[0,2] = xaxis.z;
	viewMatrix[1,2] = yaxis.z;
	viewMatrix[2,2] = zaxis.z;
	viewMatrix[0,3] = -dot( xaxis, eye );
	viewMatrix[1,3] = -dot( yaxis, eye );
	viewMatrix[2,3] = -dot( zaxis, eye );

	return viewMatrix;
}

auto rotationMatrix(T)(QuaternionT!T q) {
	auto result = identity!(4,T);
	q = normalize(q);
	auto x = q.x;
	auto y = q.y;
	auto z = q.z;
	auto w = q.w;
	result[0,0] = 1 - 2*y*y - 2*z*z;
	result[0,1] = 2*x*y - 2*z*w;
	result[0,2] = 2*x*z + 2*y*w;
	result[1,0] = 2*x*y + 2*z*w;
	result[1,1] = 1 - 2*x*x - 2*z*z;
	result[1,2] = 2*y*z - 2*x*w;
	result[2,0] = 2*x*z - 2*y*w;
	result[2,1] = 2*y*z + 2*x*w;
	result[2,2] = 1 - 2*x*x - 2*y*y;
	return result;
}

auto scalingMatrix(T)(T x, T y, T z) {
	auto r = identity!(4, T);
	r[0,0] = x;
	r[1,1] = y;
	r[2,2] = z;
	return r;
}

auto scalingMatrix(T)(VectorT!(3,T) v) {
	auto r = identity!(4, T);
	r[0,0] = v.x;
	r[1,1] = v.y;
	r[2,2] = v.z;
	return r;
}

auto translationMatrix(T)(T x, T y, T z) {
	auto r = identity!(4, T);
	r[0,3] = x;
	r[1,3] = y;
	r[2,3] = z;
	return r;
}

auto translationMatrix(T)(VectorT!(3,T) v) {
	auto r = identity!(4, T);
	r[0,3] = v.x;
	r[1,3] = v.y;
	r[2,3] = v.z;
	return r;
}

auto modelMatrix(T)(VectorT!(3,T) location, QuaternionT!(T) rotation, VectorT!(3,T) scale) {
	return translationMatrix(location)*rotationMatrix(rotation)*scalingMatrix(scale);
}

template isMatrix(T) {
	enum isMatrix = isInstanceOf!(MatrixT, T);
}


unittest{
	{
		auto a = mat4(vec4(1,2,3,4),vec4(5,6,7,8),vec4(9,10,11,12),vec4(13,14,15,16));
		auto b = mat4(vec4(1,2,3,4),vec4(5,6,7,8),vec4(9,10,11,12),vec4(13,14,15,16));
		assert(a*b == mat4(vec4(90,100,110,120),vec4(202,228,254,280),vec4(314,356,398,440),vec4(426,484,542,600)));
	}
	{
		assert(mat2(1,2,3,4) == mat2(vec2(1,2), vec2(3,4)));
		assert(mat2(1,2,3,4)*2 == mat2(2,4,6,8));
		assert(2*mat2(1,2,3,4) == mat2(2,4,6,8));
		assert(mat2(2,4,6,8)/2 == mat2(1,2,3,4));
	}
	{
		auto a = mat4(vec4(1,2,3,4),vec4(5,6,7,8),vec4(9,10,11,12),vec4(13,14,15,16));
		auto b = vec4(1,2,3,4);
		assert(a*b == vec4(30,70,110,150));
	}
	{
		assert(det(mat2(1,2,3,4)) == -2);
		assert(det(mat3(6,1,1,4,-2,5,2,8,7)) == -306);
		assert(det(mat4(1,0,2,-1,3,0,0,5,2,1,4,-3,1,0,5,0)) == 30);
	}
	{
		assert(inverse(mat2(1,2,3,4)) == mat2(-2,1,3/2.0f, -1/2.0f));
		assert(inverse(mat3(6,1,1,4,-2,5,2,8,7)) == mat3(3/17.0f, -1/306.0f, -7/306.0f, 1/17.0f, -20/153.0f,13/153.0f,-2/17.0f,23/153.0f,8/153.0f));
		assert(inverse(mat4(1,0,2,-1,3,0,0,5,2,1,4,-3,1,0,5,0)) == mat4(5/6.0f, 1/6.0f,-0.0f,-1/3.0f,-5/2.0f,1/10.0f,1,1/5.0f,-1/6.0f,-1/30.0f,0,4/15.0f,-1/2.0f,1/10.0f,0,1/5.0f));
	}
	{
		auto proj = projectionMatrix!float(0.3f,1,1,100);
		auto view = viewMatrix(vec3(0,0,0),vec3(0,0,1),vec3(0,1,0));
		auto rot  = rotationMatrix(quatern(0,0.3,0));
		auto scale1 = scalingMatrix(3.0f,4.0f,5.0f);
		auto scale2 = scalingMatrix(vec3(3,4,5));
		auto trans1 = translationMatrix(3.0f,4.0f,5.0f);
		auto trans2 = translationMatrix(vec3(3,4,5));
		auto m = modelMatrix(vec3(3,4,5), quatern(0.3f,0.2f,0.1f), vec3(1,1,1));
	}
	{
		assert(cast(mat2)(dmat2(1,2,3,4)) == mat2(1,2,3,4));
	}
	{
		assert(isMatrix!mat2);
		assert(!isMatrix!int);
	}
}
