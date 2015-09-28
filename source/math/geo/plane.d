module math.geo.plane;
import math.matrix;

alias Plane = PlaneT!float;

struct PlaneT(T = float)
{
	public matrix!(3,1,T) N;
	public T D;

	public this(matrix!(3,1,T) A, matrix!(3,1,T) B, matrix!(3,1,T) C)
	{
		N = normalize(cross((B - A),(C - A)));
		D = -dot(N, A);
	}


	public T intersect(matrix!(3,1,T) v)
	{
		return dot( matrix!(4,1,T)(N.x, N.y, N.z, D) ,  matrix!(4,1,T)(v.x, v.y, v.z, 1));
	}
}