module math.geo.AABox;
import math.matrix;

alias AABox = AABoxT!float;

struct AABoxT(T = float)
{
	public matrix!(3,1,T) c;
	public matrix!(3,1,T) s;

	public this( matrix!(3,1,T) center, matrix!(3,1,T) size)
	{
		c = center;
		s = size;
	}

	public matrix!(3,1,T)[] getCorners()
	{
		matrix!(3,1,T)[] r = new matrix!(3,1,T)[8];
		r[0] = c + matrix!(3,1,T)( s.x, s.y, s.z);
		r[1] = c + matrix!(3,1,T)( s.x, s.y,-s.z);
		r[2] = c + matrix!(3,1,T)( s.x,-s.y, s.z);
		r[3] = c + matrix!(3,1,T)( s.x,-s.y,-s.z);
		r[4] = c + matrix!(3,1,T)(-s.x, s.y, s.z);
		r[5] = c + matrix!(3,1,T)(-s.x, s.y,-s.z);
		r[6] = c + matrix!(3,1,T)(-s.x,-s.y, s.z);
		r[7] = c + matrix!(3,1,T)(-s.x,-s.y,-s.z);
		return r;
	}
}