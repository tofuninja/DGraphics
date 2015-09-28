module math.interpolate;

auto lerp(T)(T v0, T v1, T t)
{
	return (1-t)*v0 + t*v1;
}

auto cosInterp(T)(T y1, T y2, T mu)
{
	import std.math;
	auto mu2 = (1-cos(mu*PI))/2.0;
	return cast(T)(y1*(1-mu2)+y2*mu2);
}

struct interpolate2d
{
	import std.math;
	import math.matrix;

	private alias interp = cosInterp;

	int s;
	float[] d;
	public this(int size, float[] data)
	{
		s = size;
		d = data;
	}

	public ivec2 getIndex(float x, float y)
	{
		float fx = x*(s-1);
		float fy = y*(s-1);
		int ix = cast(int)floor(fx);
		int iy = cast(int)floor(fy);
		return ivec2(ix, iy);
	}

	public float get(float x, float y)
	{
		import std.math;
		import std.algorithm;
		
		float v;
		float fx, fy, ix, iy, dx, dy;
		fx = x*(s-1);
		fy = y*(s-1);
		ix = floor(fx);
		iy = floor(fy);
		dx = fx - ix;
		dy = fy - iy;
		
		float rxy(float x, float y)
		{
			int xi = min(max(cast(int)x,0),s-1);
			int yi = min(max(cast(int)y,0),s-1);
			int id = (xi)*s + (yi);
			return d[id%(d.length)]; // loops around if you index to far
		}
		
		float r00 = rxy(ix, iy);
		float r10 = rxy(ix + 1, iy);
		float r01 = rxy(ix, iy + 1);
		float r11 = rxy(ix + 1, iy + 1);
		
		auto interp0 = interp(r00, r10, dx);
		auto interp1 = interp(r01, r11, dx);
		v = interp(interp0, interp1, dy);
		
		return v;
	}

	public vec2 getFlow(float x, float y)
	{
		import std.math;
		import std.algorithm;
		
		float v;
		float fx, fy, ix, iy, dx, dy;
		fx = x*(s-1);
		fy = y*(s-1);
		ix = floor(fx);
		iy = floor(fy);
		dx = fx - ix;
		dy = fy - iy;
		
		float rxy(float x, float y)
		{
			int xi = min(max(cast(int)x,0),s-1);
			int yi = min(max(cast(int)y,0),s-1);
			int id = (xi)*s + (yi);
			return d[id%(d.length)]; // loops around if you index to far
		}
		
		float r00 = rxy(ix, iy);
		float r10 = rxy(ix + 1, iy);
		float r01 = rxy(ix, iy + 1);
		float r11 = rxy(ix + 1, iy + 1);
		
		float x1 = F(dx, r00, r10);
		float x2 = F(dx, r01, r11);
		
		float dx1 = dF(dx, r00, r10);
		float dx2 = dF(dx, r01, r11);
		
		float ddx = F(dy, dx1, dx2);
		float ddy = dF(dy, x1, x2);
		
		return vec2(ddx,ddy);
	}

	public float[] flatten(int size)
	{
		float[] dat = new float[size*size];
		void setDat(int x, int y, float v)
		{
			dat[x*size + y] = v;
		}
		
		float fs = cast(float)size;
		
		for(int i = 0; i < size; i++)
		{
			for(int j = 0; j < size; j++)
			{
				float v = get(i/fs, j/fs);
				setDat(i, j, v);
			}
		}
		return dat; 
	}

	private float G(float x)
	{
		return (1 - cast(float)cos(PI * x)) * 0.5f;
	}
	
	private float dG(float x)
	{
		return cast(float)(sin(PI * x) * 0.5);
	}
	
	private float F(float x, float a, float b)
	{
		float g = G(x);
		return a - a * g + b * g;
	}
	
	private float dF(float x, float a, float b)
	{
		return dG(x) * (b - a);
	}
}