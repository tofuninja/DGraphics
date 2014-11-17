﻿module math.matrix;

import std.conv;
import std.traits;
import std.math;

alias mat2 = matrix!(2, 2, float);
alias mat3 = matrix!(3, 3, float);
alias mat4 = matrix!(4, 4, float);

alias dmat2 = matrix!(2, 2, double);
alias dmat3 = matrix!(3, 3, double);
alias dmat4 = matrix!(4, 4, double);

alias imat2 = matrix!(2, 2, int);
alias imat3 = matrix!(3, 3, int);
alias imat4 = matrix!(4, 4, int);

alias umat2 = matrix!(2, 2, uint);
alias umat3 = matrix!(3, 3, uint);
alias umat4 = matrix!(4, 4, uint);

alias bmat2 = matrix!(2, 2, bool);
alias bmat3 = matrix!(3, 3, bool);
alias bmat4 = matrix!(4, 4, bool);

alias vec2 = matrix!(2,1);
alias vec3 = matrix!(3,1);
alias vec4 = matrix!(4,1);

alias dvec2 = matrix!(2,1,double);
alias dvec3 = matrix!(3,1,double);
alias dvec4 = matrix!(4,1,double);

alias ivec2 = matrix!(2,1,int);
alias ivec3 = matrix!(3,1,int);
alias ivec4 = matrix!(4,1,int);

alias uvec2 = matrix!(2,1,uint);
alias uvec3 = matrix!(3,1,uint);
alias uvec4 = matrix!(4,1,uint);

alias bvec2 = matrix!(2,1,bool);
alias bvec3 = matrix!(3,1,bool);
alias bvec4 = matrix!(4,1,bool);

/**
 * Simple matrix implimentation.
 * Something to remember is that every thing is row by column 
 * and it is a 0 based index system.
 * 
 * The values in the matrix are stored in m_data and is stored in column major
 * 
 * Also if the column count is 1 then it is considered a vector. 
 * 
 * Also if for some reason you are using a custom type for your 
 * elements, this assums that T.init is 'zero'. The only types that
 * are an exception to this is floating point types, and thats just 
 * because T.init for floating point is nan, so T.init is not used 
 * for floating point. 
 */
struct matrix(int m, int n, T = float)
{
	static assert(m > 0,"Row count must be greater than 0");
	static assert(n > 0,"Column count must be greater than 0");

	public enum iAmAMatrix = true;
	public enum rows = m;
	public enum columns = n;
	public enum bool isVector = (columns == 1); // Vectors will always be column vectors
	public enum bool isSquare = (rows == columns);
	public alias elementType = T;
	
	static if(isFloatingPoint!T)
	{
		public T[m*n] m_data = arrayInit!(m,n,T)(0); // Makes way more sense to init to zero than nan... 
	}
	else
	{
		public T[m*n] m_data;
	}
	
	// Just some convenience stuff for vectors
	static if(isVector)
	{
		public enum size = rows;
		
		static if(size >= 1)
		{
			@property ref T x() { return this[0]; };
		}
		static if(size >= 2)
		{
			@property ref T y() { return this[1]; };
		}
		static if(size >= 3)
		{
			@property ref T z() { return this[2]; };
		}
		static if(size >= 4)
		{
			@property ref T w() { return this[3]; };
		}
		
		// Indexing op for vector
		ref T opIndex(size_t element)
		{
			return this[element,0];
		}

		// Swizzle
		auto opDispatch(string s)()
		{
			static assert(s.length <= rows, "Swizzel mask too long");
			enum int l = s.length;
			
			T grab(char c)()
			{
				static if(c == 'x' && rows >= 1) return this[0,0];
				static if(c == 'y' && rows >= 2) return this[1,0];
				static if(c == 'z' && rows >= 3) return this[2,0];
				static if(c == 'w' && rows >= 4) return this[3,0];
				
				static if(c != 'x' && c != 'y' && c != 'z' && c != 'w')
				{
					static assert(false, "Non Valid swizzel");
					return T.init;
				}
			}

			static if(l == 4)
			{
				return matrix!(4,1,T)(grab!(s[0]), grab!(s[1]), grab!(s[2]), grab!(s[3]));
			}
			static if(l == 3)
			{
				return matrix!(3,1,T)(grab!(s[0]), grab!(s[1]), grab!(s[2]));
			}
			static if(l == 2)
			{
				return matrix!(2,1,T)(grab!(s[0]), grab!(s[1]));
			}
			/*
			static if(l == 1)
			{
				return matrix!(4,1,T)(grab!(s[0]), grab!(s[1]), grab!(s[2]), grab!(s[3]));
			}*/
		}

		auto opDispatch(string s, int l)(matrix!(l,1,T) v)
		{
			static assert(s.length <= 4, "Swizzel mask too long");
			static assert(s.length == l, "Swizzel and vector size dont match");

			void place(char c)(T i)
			{
				static if(c == 'x' && rows >= 1) this[0,0] = i;
				static if(c == 'y' && rows >= 2) this[1,0] = i;
				static if(c == 'z' && rows >= 3) this[2,0] = i;
				static if(c == 'w' && rows >= 4) this[3,0] = i;
				
				static if(c != 'x' && c != 'y' && c != 'z' && c != 'w')
				{
					static assert(false, "Non Valid swizzel");
				}
			}

			static if(l == 4)
			{
				place!(s[0])(v[0,0]);
				place!(s[1])(v[1,0]);
				place!(s[2])(v[2,0]);
				place!(s[3])(v[3,0]);
			}
			static if(l == 3)
			{
				place!(s[0])(v[0,0]);
				place!(s[1])(v[1,0]);
				place!(s[2])(v[2,0]);
			}
			static if(l == 2)
			{
				place!(s[0])(v[0,0]);
				place!(s[1])(v[1,0]);
			}
			/*
			static if(l == 1)
			{
				return matrix!(4,1,T)(grab!(s[0]), grab!(s[1]), grab!(s[2]), grab!(s[3]));
			}*/
		}

		/// Vector division op
		auto opBinary(string op : "/", T2,int rowCount)(matrix!(rowCount,1,T2) rhs) 
		{
			static assert(isVector && rhs.isVector && rows == rhs.rows, "opBinary(/) not defined");
			static assert(__traits(compiles, (T.init) / (T2.init)),"opBinary(/) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
			alias mulT = typeof((T.init) / (T2.init));
			matrix!(rows,1,mulT) rtn;
			rtn.m_data[] = m_data[] / rhs.m_data[];
			return rtn;
		}
	}
	
	public this(T val)
	{
		for(int j = 0; j < columns; j++)
		{
			for(int i = 0; i < rows; i++)
			{
				this[i,j] = val;
			}
		}
	}
	
	public this(T[rows*columns] arr ...)
	{
		int index = 0;
		for(int i = 0; i < rows; i++)
		{
			for(int j = 0; j < columns; j++)		
			{
				this[i,j] = arr[index];
				index++;
			}
		}
	}
	
	/// Indexing op
	ref T opIndex(size_t row, size_t col)
	{
		assert(row>=0,"Index out of bounds");
		assert(col>=0,"Index out of bounds");
		assert(row<rows,"Index out of bounds");
		assert(col<columns,"Index out of bounds");
		return m_data[row + col*rows];
	}
	
	/// Negation op
	auto opUnary(string op : "-")()
	{
		static assert(__traits(compiles, -T.init), "opUnary(-) is not defined on " ~ T.stringof);
		
		matrix!(rows,columns,T) rtn;
		rtn.m_data[] = -m_data[];
		return rtn;
	}
	
	/// Addition op
	auto opBinary(string op : "+",T2)(matrix!(rows,columns,T2) rhs) 
	{
		static assert(__traits(compiles, T.init + T2.init), "opBinary(+) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
		
		alias sumT = typeof(T.init + T2.init);
		matrix!(rows,columns,sumT) rtn;
		
		rtn.m_data[] = m_data[] + rhs.m_data[];
		
		return rtn;
	}
	
	/// Subtraction op
	auto opBinary(string op : "-",T2)(matrix!(rows,columns,T2) rhs) 
	{
		static assert(__traits(compiles, T.init - T2.init), "opBinary(-) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
		alias difT = typeof(T.init - T2.init);
		matrix!(rows,columns,difT) rtn;
		
		rtn.m_data[] = m_data[] - rhs.m_data[];
		
		return rtn;
	}
	
	/// Scalar multiplication op
	auto opBinary(string op : "*", T2)(T2 rhs) 
		if(isScalarType!T2)
	{
		static assert(__traits(compiles, ((T.init) * (T2.init))), "opBinary(*) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
		
		alias mulT = typeof(((T.init) * (T2.init)));
		matrix!(rows,columns,mulT) rtn;
		rtn.m_data[] = m_data[] * rhs;
		return rtn;
	}
	
	/// Scalar multiplication op from the right
	auto opBinaryRight(string op : "*", T2)(T2 lhs) 
		if(isScalarType!T2)
	{
		static assert(__traits(compiles, ((T2.init) * (T.init))), "opBinary(*) is not defined between " ~ T2.stringof ~ " and " ~ T.stringof);
		
		alias mulT = typeof(((T2.init) * (T.init)));
		matrix!(rows,columns,mulT) rtn;
		
		rtn.m_data[] = lhs*m_data[];
		return rtn;
	}
	
	
	/// Scalar division op
	auto opBinary(string op : "/", T2)(T2 rhs) 
		if(isScalarType!T2)
	{
		static assert(__traits(compiles, ((T.init) / (T2.init))), "opBinary(/) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
		
		alias mulT = typeof(((T.init) / (T2.init)));
		matrix!(rows,columns,mulT) rtn;
		rtn.m_data[] = m_data[] / rhs;
		return rtn;
	}
	
	/// Scalar division op from the right
	auto opBinaryRight(string op : "/", T2)(T2 lhs) 
		if(isScalarType!T2)
	{
		static assert(false, "It does not make sense to divide a scalar by a vector");
	}

	/// Matrix multiplication op
	auto opBinary(string op : "*", T2,int rowCount, int colCount)(matrix!(rowCount,colCount,T2) rhs) 
	{
		static if(isVector && rhs.isVector && rows == rhs.rows)
		{
			// Convinence for multiplying vectors
			static assert(__traits(compiles, (T.init) * (T2.init)),"opBinary(*) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
			alias mulT = typeof((T.init) * (T2.init));
			matrix!(rows,1,mulT) rtn;
			rtn.m_data[] = m_data[] * rhs.m_data[];
			return rtn;
		}
		else
		{	
			// Normal matrix multiplication 
			static assert(columns == rowCount,"Left hand matrix's column count must equal right hand matrix's row count.");
			static assert(__traits(compiles, (T.init) * (T2.init)),"opBinary(*) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
			static assert(__traits(compiles, ((T.init) * (T2.init)) + ((T.init) * (T2.init))),"opBinary(+) is not defined on " ~ typeof((T.init) * (T2.init)).stringof);
			
			alias mulT = typeof(((T.init) * (T2.init)) + ((T.init) * (T2.init)));
			matrix!(rows,colCount,mulT) rtn;
			
			for(int i = 0; i < rows; i++)
			{
				for(int j = 0; j < colCount; j++)
				{
					mulT sum = this[i,0]*rhs[0,j];
					for(int k = 1; k < columns; k++)
					{
						sum += this[i,k]*rhs[k,j];
					}
					rtn[i,j] = sum;
				}
			}
			
			return rtn;
		}
	}


	/// Matrix concatination, does a horizontal concatination
	auto opBinary(string op : "~", int m2, int n2)(matrix!(m2,n2,T) rhs) 
	{
		return horizontalCat!(m,n,m2,n2,T)(this,rhs);
	}
	
	/// Casting op
	auto opCast(T2 : matrix!(m,n,T2))()
	{
		static assert(__traits(compiles, cast(T2)T.init), "No cast from " ~ T.stringof ~ " to " ~ T2.stringof);
		
		matrix!(m,n,T2) rtn;
		
		for(int j = 0; j < n; j++)
		{
			for(int i = 0; i < m; i++)
			{
				rtn[i,j] = cast(T2)this[i,j];
			}
		}
		return rtn;
	}
	
	public string toString()
	{
		string s = "[";
		for(int i = 0; i < rows; i++)
		{
			for(int j = 0; j < columns; j++)
			{
				s ~= this[i,j].to!string;
				if(j < columns - 1) s ~= ",";
			}
			if(i < rows - 1) s ~= ";";
		}
		return s ~ "]";
	}
}

/**
 * Flips a matrix over the main axis
 */
public auto transpose(int m, int n, T)(matrix!(m,n,T) mat)
{
	matrix!(n,m,T) rtn;
	
	for(int i = 0; i < m; i++)
	{
		for(int j = 0; j < n; j++)		
		{
			rtn[j,i] = mat[i,j];
		}
	}
	
	return rtn;
}

/**
 * Calculates the dot product between two vectors
 */
public auto dot(int m, T1, T2)(matrix!(m,1,T1) a, matrix!(m,1,T2) b)
{
	static assert(__traits(compiles, (T1.init) * (T2.init)),"opBinary(*) is not defined between " ~ T1.stringof ~ " and " ~ T2.stringof);
	static assert(__traits(compiles, ((T1.init) * (T2.init)) + ((T1.init) * (T2.init))),"opBinary(+) is not defined on " ~ typeof((T1.init) * (T2.init)).stringof);
	static assert(a.isVector); // If these fail, something is really wrong...
	static assert(b.isVector);
	alias T = typeof(((T1.init) * (T2.init)) + ((T1.init) * (T2.init)));
	
	T rtn = a[0] * b[0];
	for(int i = 1; i < m; i++)
	{
		rtn += a[i] * b[i];
	}
	return rtn;
}

/**
 * Calculates the cross product between two 3d vectors
 */
public auto cross(T1,T2)(matrix!(3,1,T1) a, matrix!(3,1,T2) b)
{
	static assert(__traits(compiles, (T1.init) * (T2.init)),"opBinary(*) is not defined between " ~ T1.stringof ~ " and " ~ T2.stringof);
	static assert(__traits(compiles, ((T1.init) * (T2.init)) + ((T1.init) * (T2.init))),"opBinary(+) is not defined on " ~ typeof((T1.init) * (T2.init)).stringof);
	static assert(a.isVector); // If these fail, something is really wrong...
	static assert(b.isVector);
	alias T = typeof(((T1.init) * (T2.init)) + ((T1.init) * (T2.init)));
	
	matrix!(3,1,T) rtn;
	rtn[0] = a[1]*b[2] - a[2]*b[1];
	rtn[1] = a[2]*b[0] - a[0]*b[2];
	rtn[2] = a[0]*b[1] - a[1]*b[0];
	return rtn;
}

/**
 * Constructs an identity matrix of size m
 */
public auto identity(int m, T = float)()
{
	static assert(isNumeric!T, "Dont know what '1' is for type " ~ T.stringof ~ ", use scalarMatrix to construct an identity matrix manualy");
	return scalarMatrix!(m,T)(1);
}

/**
 * Constructs a scalar matrix of size m with the all
 * the elements on the main diagonal set to value. 
 */
public auto scalarMatrix(int m, T = float)(T value)
{
	alias matT = matrix!(m,m,T);
	matT rtn;
	for(int i = 0; i < m; i++)
		rtn[i,i] = value;
	return rtn;
}

/**
 * Concatinates the two matricies horizontaly.
 * They must have the same row count.
 * 
 * ... not a cat on its side ... 
 */
public auto horizontalCat(int m1, int n1, int m2, int n2, T)(matrix!(m1,n1,T) a, matrix!(m2,n2,T) b)
{
	static assert(m1 == m2,"Row count must be equal");
	alias rtnT = matrix!(m1,n1 + n2,T);
	rtnT rtn;
	
	for(int i = 0; i < m1; i++)
	{
		for(int j = 0; j < n1; j++)
		{
			rtn[i,j] = a[i,j];
		}
	}
	
	for(int i = 0; i < m2; i++)
	{
		for(int j = 0; j < n2; j++)
		{
			rtn[i,n1 + j] = b[i,j];
		}
	}
	
	return rtn;
}

/**
 * Concatinates the two matricies verticaly.
 * They must have the same column count.
 */
public auto verticalCat(int m1, int n1, int m2, int n2, T)(matrix!(m1,n1,T) a, matrix!(m2,n2,T) b)
{
	static assert(n1 == n2,"Column count must be equal");
	alias rtnT = matrix!(m1 + m2,n1,T);
	rtnT rtn;
	
	for(int i = 0; i < m1; i++)
	{
		for(int j = 0; j < n1; j++)
		{
			rtn[i,j] = a[i,j];
		}
	}
	
	for(int i = 0; i < m2; i++)
	{
		for(int j = 0; j < n2; j++)
		{
			rtn[m1 + i,j] = b[i,j];
		}
	}
	
	return rtn;
}

/**
 * Calculates the inverse of a matrix when posible.
 * If no inverse exists, then it will throw an exception.
 * 
 * If T is an intergral type, it will be promoted to a float.
 * 
 * T must be a built in numeric type as '1' must be know for
 * identity.
 */
public auto invert(int matR, int matC, T)(matrix!(matR,matC,T) mat)
{
	static assert(mat.isSquare, "Must be a square matrix");
	static assert(isNumeric!T, "T must be a numeric type");

	/*
	auto reducedAugment = (mat ~ identity!(m,T)).rref();
	
	// Determin if mat is singular
	if(reducedAugment[m-1,n-1] != 1) throw new Exception("Matrix is singular");
	
	matrix!(m,n,reducedAugment.elementType) rtn;
	
	for(int j = 0; j < n; j++)
	{
		for(int i = 0; i < m; i++)
		{
			rtn[i,j] = reducedAugment[i,n + j];
		}
	}
	
	return rtn;
	*/
	import std.exception;
	enum f = matR;
	matrix!(f - 1,f - 1,T) b;
	matrix!(f,f,T) fac;

	T d = determinant(mat);
	enforce(d != 0, "Matrix is singular");
	
	for(int q = 0; q < f; q++)
	{
		for(int p = 0; p < f; p++)
		{
			int m=0;
			int n=0;
			for (int i = 0; i < f; i++)
			{
				for (int j = 0; j < f; j++)
				{
					if (i != q && j != p)
					{
						b[m,n] = mat[i,j];
						if (n < (f - 2)) n++; 
						else
						{
							n=0;
							m++;
						}
					}
				}
			}
			fac[p, q] = pow(-1,q + p) * determinant(b);
		}
	}
	return fac/d;
}

/**
 * Calculates the determinant of a matrix
 */
auto determinant(int matR, int matC, T)(matrix!(matR,matC,T) a)
{
	static assert(a.isSquare, "Must be a square matrix");
	static assert(isNumeric!T, "T must be a numeric type");
	enum k = matR;

	static if(k==1)
	{
		return (a[0,0]);
	}
	else
	{
		T s=1;
		T det=0;
		for (int c = 0; c < k; c++)
		{
			int m = 0;
			int n = 0;
			matrix!(k - 1,k -1,T) b;
			for(int i = 0; i < k; i++)
			{
				for(int j = 0; j < k; j++)
				{
					if (i != 0 && j != c)
					{
						b[m,n] = a[i,j];
						if (n < (k - 2)) n++;
						else
						{
							n=0;
							m++;
						}
					}
				}
			}
			det = det + s * (a[0,c] * determinant(b));
			s = -1 * s;
		}
		return det;
	}
}

/**
 * Performs Gauss-Jordan elimination to get 
 * the reduced row echelon form of the matrix.
 * 
 * If T is an intergral type, it will be promoted to a float.
 */
public auto rref(int m, int n, T)(matrix!(m,n,T) mat)
{
	static if(isIntegral!T)
	{
		alias matT = float;
		auto augment = (cast(matrix!(m,n,float))mat);
	}
	else
	{
		alias matT = T;
		auto augment = mat;
	}
	
	static assert(__traits(compiles,(matT.init) - (matT.init)), "binaryOp(-) not defined on " ~ matT.stringof);
	static assert(__traits(compiles,(matT.init) * (matT.init)), "binaryOp(*) not defined on " ~ matT.stringof);
	static assert(__traits(compiles,(matT.init) / (matT.init)), "binaryOp(/) not defined on " ~ matT.stringof);
	static assert(__traits(compiles,(matT.init) > (matT.init)), "opCmp() not defined on " ~ matT.stringof);
	
	/* using gauss-jordan elimination */
	int currentRow = 0;
	for (int j = 0; j < n; j++) 
	{
		if(currentRow == m) break;
		int temp = currentRow;
		
		
		for (int i = currentRow + 1; i < m; i++)
		{
			if (augment[i,j] > augment[temp,j]) temp = i;
		}
		
		
		if (temp != currentRow)
		{
			for (int k = 0; k < n; k++) 
			{
				matT temporary = augment[currentRow,k];
				augment[currentRow,k] = augment[temp,k];
				augment[temp,k] = temporary;
			}
		}
		
		/* performing row operations */
		if(augment[currentRow,j] != 0)
		{
			for (int i = 0; i < m; i++)
			{
				if (i != currentRow) 
				{
					matT r = augment[i,j];
					for (int k = 0; k <  n; k++)
					{
						augment[i,k] -= augment[currentRow,k] * r / augment[currentRow,j];
					}
				} 
				else 
				{
					matT r = augment[i,j];
					for (int k = 0; k < n; k++)
					{
						augment[i,k] /= r;
					}
				}
			}
			currentRow++;
		}
	}
	
	return augment;
}

/**
 * Constructs a 3d perspective projection matrix
 */
auto projectionMatrix(T=float)(T fov, T aspect, T nearDist, T farDist, bool leftHanded=false)
{
	//
	// General form of the Projection Matrix
	//
	// uh = Cot( fov/2 ) == 1/Tan(fov/2)
	// uw / uh = 1/aspect
	// 
	//   uw         0       0       0
	//    0        uh       0       0
	//    0         0      f/(f-n)  1
	//    0         0    -fn/(f-n)  0
	//
	// check for bad parameters to avoid divide by zero:
	// if found, assert and return an identity matrix.
	assert(fov > 0, "Fov is less than or equals to zero");
	assert(aspect != 0, "Aspect equals zero");
	static assert(__traits(compiles, cast(real)T.init), "No cast from " ~ T.stringof ~ " to real");
	static assert(__traits(compiles, cast(T)real.init), "No cast from real to " ~ T.stringof);
	static assert(isNumeric!T, T.stringof ~ " is not numaric");
	
	auto result = identity!(4,T);
	T frustumDepth = farDist - nearDist;
	T oneOverDepth = 1 / frustumDepth;
	/*
	result[1,1] = cast(T)(1 / tan(0.5f * cast(real)fov));
	result[0,0] = ((leftHanded ? 1 : -1 ) * result[1,1] / aspect);
	result[2,2] = (farDist * oneOverDepth);
	result[3,2] = ((-farDist * nearDist) * oneOverDepth);
	result[2,3] = 1;
	result[3,3] = 0;
	*/

	result[1,1] = cast(T)(1 / tan(0.5f * cast(real)fov));
	result[0,0] = ((leftHanded ? 1 : -1 ) * result[1,1] / aspect);
	result[2,2] = -((farDist + nearDist) * oneOverDepth);
	result[2,3] = ((2*farDist * nearDist) * oneOverDepth);
	result[3,2] = 1;
	result[3,3] = 0;

	return result;
}

/**
 * Constructs a view matrix
 */
mat4 viewMatrix(T=float)(matrix!(3,1,T) eye, matrix!(3,1,T) target, matrix!(3,1,T) up )
{
	auto zaxis = normalize(eye - target);		// The "forward" vector.
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

/// Constructs a quaternion for rotation
auto quaternion(T=float)(matrix!(3,1,T) axis, T angle)
{
	static assert(__traits(compiles, cast(real)T.init), "No cast from " ~ T.stringof ~ " to real");
	static assert(__traits(compiles, cast(T)real.init), "No cast from real to " ~ T.stringof);
	static assert(isNumeric!T, T.stringof ~ " is not numaric");
	
	T c = cast(T)cos(angle/2);
	T s = cast(T)sin(angle/2);
	return matrix!(4,1,T)(s*axis.x,s*axis.y,s*axis.z,c);
}

auto length(int m, T)(matrix!(m,1,T) vec)
{
	return dot(vec,vec);
}

auto normalize(int m, T)(matrix!(m,1,T) vec)
{
	return vec/vec.length;
}

/**
 * Constructs a rotation matrix
 */
auto rotationMatrix(T=float)(matrix!(4, 1,T) q)
{
	static assert(__traits(compiles, cast(real)T.init), "No cast from " ~ T.stringof ~ " to real");
	static assert(__traits(compiles, cast(T)real.init), "No cast from real to " ~ T.stringof);
	static assert(isNumeric!T, T.stringof ~ " is not numaric");
	
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

/**
 * Constructs a rotation matrix
 * axis+angle to rotation matrix
 */
auto rotationMatrix(T=float)(matrix!(3, 1, T) axis, T angle)
{
	return rotationMatrix(quaternion(axis, angle));
}

/**
 * Constructs a rotation matrix from yaw, pitch, roll
 * vec3(yaw, pitch, roll)
 */
auto rotationMatrix(T=float)(matrix!(3, 1, T) ypr)
{
	return 
		rotationMatrix(matrix!(3, 1, T)(0,1,0),ypr.x)* // Yaw
		rotationMatrix(matrix!(3, 1, T)(1,0,0),ypr.y)* // Pitch
		rotationMatrix(matrix!(3, 1, T)(0,0,1),ypr.z); // Roll
}

/**
 * Construct a rotation matrix to rotate about an arbitrary axis
 */
auto rotationMatrixArbitraryAxis(T=float)(matrix!(3, 1, T) axisStart, matrix!(3, 1, T) axisEnd, T angle)
{
	auto axis = axisEnd-axisStart;
	return translationMatrix(axisStart)*rotationMatrix(axis,angle)*translationMatrix(-axisStart);
}

/// Construct a scaling matrix
auto scalingMatrix(T=float)(T x, T y, T z)
{
	auto r = identity!(4, T);
	r[0,0] = x;
	r[1,1] = y;
	r[2,2] = z;
	return r;
}

/// Construct a scaling matrix
auto scalingMatrix(T=float)(matrix!(3,1,T) v)
{
	auto r = identity!(4, T);
	r[0,0] = v.x;
	r[1,1] = v.y;
	r[2,2] = v.z;
	return r;
}

/// Constructs a translation matrix
auto translationMatrix(T=float)(T x, T y, T z)
{
	auto r = identity!(4, T);
	r[0,3] = x;
	r[1,3] = y;
	r[2,3] = z;
	return r;
}

/// Constructs a translation matrix
auto translationMatrix(T=float)(matrix!(3,1,T) v)
{
	auto r = identity!(4, T);
	r[0,3] = v.x;
	r[1,3] = v.y;
	r[2,3] = v.z;
	return r;
}

void prettyPrint(int m, int n, T)(matrix!(m,n,T) mat)
{
	import std.stdio;
	for(int i = 0; i < m; i++)
	{
		for(int j = 0; j < n; j++)
		{
			writef("%8s  ", mat[i,j]);
		}
		write("\n");
	}
}

auto lerp(int M, int N, T)(matrix!(M,N,T) m1, matrix!(M,N,T) m2, T percent)
{
	matrix!(M,N,T) rtn;
	rtn.m_data[] = m1.m_data[] + (m2.m_data[] - m1.m_data[])*percent;
	return rtn;
} 

// just some trash...
private auto arrayInit(int m, int n, T)(T v)
{
	T[m*n] rtn;
	for(int i = 0; i < m*n; i++)
	{
		rtn[i] = v;
	}
	return rtn;
}

template isMatrix(T)
{
	static if(__traits(hasMember, T, "iAmAMatrix")) enum isMatrix = true;
	else enum isMatrix = false;
}

auto modelMatrix(vec3 translation, vec3 rotation, vec3 scale)
{
	return translationMatrix(translation)*rotationMatrix(rotation)*scalingMatrix(scale);
}
