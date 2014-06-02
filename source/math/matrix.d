module math.matrix;

import std.conv;
import std.traits;

alias mat2 = matrix!(2, 2, float);
alias mat3 = matrix!(3, 3, float);
alias mat4 = matrix!(4, 4, float);

alias mat2d = matrix!(2, 2, double);
alias mat3d = matrix!(3, 3, double);
alias mat4d = matrix!(4, 4, double);

alias mat2i = matrix!(2, 2, int);
alias mat3i = matrix!(3, 3, int);
alias mat4i = matrix!(4, 4, int);

/**
 * Vectors are simply matrices with only 1 column. 
 */
template vector(int m, T = float)
{
	alias vector = matrix!(m,1,T);
}

alias vec2 = matrix!(2,1);
alias vec3 = matrix!(3,1);
alias vec4 = matrix!(4,1);

alias vec2d = matrix!(2,1,double);
alias vec3d = matrix!(3,1,double);
alias vec4d = matrix!(4,1,double);

alias vec2i = matrix!(2,1,int);
alias vec3i = matrix!(3,1,int);
alias vec4i = matrix!(4,1,int);

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
		for(int j = 0; j < columns; j++)
		{
			for(int i = 0; i < rows; i++)
			{
				rtn[i,j] = -this[i,j]; // assumes T has a opUnary("-")
			}
		}

		return rtn;
	}

	/// Addition op
	auto opBinary(string op : "+",T2)(matrix!(rows,columns,T2) rhs) 
	{
		static assert(__traits(compiles, T.init + T2.init), "opBinary(+) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);

		alias sumT = typeof(T.init + T2.init);
		matrix!(rows,columns,sumT) rtn;

		for(int j = 0; j < columns; j++)
		{
			for(int i = 0; i < rows; i++)
			{
				rtn[i,j] = this[i,j] + rhs[i,j];
			}
		}

		return rtn;
	}

	/// Subtraction op
	auto opBinary(string op : "-",T2)(matrix!(rows,columns,T2) rhs) 
	{
		static assert(__traits(compiles, T.init - T2.init), "opBinary(-) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);
		alias difT = typeof(T.init - T2.init);
		matrix!(rows,columns,difT) rtn;
		
		for(int j = 0; j < columns; j++)
		{
			for(int i = 0; i < rows; i++)
			{
				rtn[i,j] = this[i,j] - rhs[i,j];
			}
		}
		
		return rtn;
	}

	/// Scalar multiplication op
	auto opBinary(string op : "*", T2)(T2 rhs) 
		if(isScalarType!T2)
	{
		static assert(__traits(compiles, ((T.init) * (T2.init))), "opBinary(*) is not defined between " ~ T.stringof ~ " and " ~ T2.stringof);

		alias mulT = typeof(((T.init) * (T2.init)));
		matrix!(rows,columns,mulT) rtn;
		
		for(int j = 0; j < columns; j++)
		{
			for(int i = 0; i < rows; i++)
			{
				rtn[i,j] = this[i,j]*rhs;
			}
		}
		return rtn;
	}

	/// Scalar multiplication op from the right
	auto opBinaryRight(string op : "*", T2)(T2 lhs) 
		if(isScalarType!T2)
	{
		static assert(__traits(compiles, ((T2.init) * (T.init))), "opBinary(*) is not defined between " ~ T2.stringof ~ " and " ~ T.stringof);

		alias mulT = typeof(((T2.init) * (T.init)));
		matrix!(rows,columns,mulT) rtn;
		
		for(int j = 0; j < columns; j++)
		{
			for(int i = 0; i < rows; i++)
			{
				rtn[i,j] = lhs*this[i,j];
			}
		}
		return rtn;
	}

	/// Matrix multiplication op
	auto opBinary(string op : "*", T2,int rowCount, int colCount)(matrix!(rowCount,colCount,T2) rhs) 
	{
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
public auto invert(int m, int n, T)(matrix!(m,n,T) mat)
{
	static assert(mat.isSquare, "Must be a square matrix");
	static assert(isNumeric!T, "T must be a numeric type");
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