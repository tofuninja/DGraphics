module math.noise.perlin;
import std.stdio;

public struct perlinNoise
{
	private float[][] data;
	private int s,o,ss;
	float a;

	public this(int seed, int octive, int startSize, float amp) {
		import std.random;
		s = seed;
		o = octive;
		ss = startSize;
		a = amp;

		auto rnd = rndGen();
		rnd.seed(seed);

		data = new float[][octive];
		for(int i = 0; i < o; i++) {
			int size = (startSize + 1)*(startSize + 1);
			data[i] = new float[size];
			for(int j = 0; j < size; j++) {
				data[i][j] = cast(float)((cast(double)rnd.front)/uint.max)*2.0f - 1.0f;
				rnd.popFront();
			}
			startSize *= 2;
		}
	}

	public auto toImage(int size) // The output is squere always
	{
		import graphics.image;
		import graphics.color;
		Image pimg = new Image(size,size);

		float fs = cast(float)size;

		for(int i = 0; i < size; i++) {
			for(int j = 0; j < size; j++) {
				ubyte p = cast(ubyte)((get(i/fs, j/fs)+1)*127.5);
				pimg[i,j] = Color(p,p,p);
			}
		}
		return pimg; 
	}

	public auto flatten(int size) {
		float[] dat = new float[size*size];
		void setDat(int x, int y, float v) {
			dat[x*size + y] = v;
		}
		
		float fs = cast(float)size;
		
		for(int i = 0; i < size; i++) {
			for(int j = 0; j < size; j++) {
				float v = get(i/fs, j/fs);
				setDat(i, j, v);
			}
		}
		return dat; 
		
	}

	public auto flattenRidged(int size) {
		import std.math;
		float[] dat = new float[size*size];
		void setDat(int x, int y, float v) {
			dat[x*size + y] = v;
		}
		
		float fs = cast(float)size;
		
		for(int i = 0; i < size; i++) {
			for(int j = 0; j < size; j++) {
				float v = getRidged(i/fs, j/fs);
				setDat(i, j, v);
			}
		}
		return dat; 
		
	}

	public float get(float x, float y) {
		return getVal(o,ss,a,x,y);
	}

	public float getRidged(float x, float y) {
		return getValR(o,ss,a,x,y);
	}

	private float getVal(int octive, int startSize, float amp, float x, float y) {
		import math.interpolate;
		import std.random;
		import std.math;
		
		float v;
		float fx, fy, ix, iy, dx, dy;
		fx = x*startSize;
		fy = y*startSize;
		ix = floor(fx);
		iy = floor(fy);
		dx = fx - ix;
		dy = fy - iy;
		
		float rxy(float inx, float iny) {
			int intx = (cast(int)inx);// % startSize;
			intx %= startSize;
			int inty = (cast(int)iny) % startSize;
			int id = (intx)*startSize + (inty);
			return data[o-octive][id%(data[o-octive].length)]; // loops around if you index to far
		}

		float r00 = rxy(ix, iy);
		float r10 = rxy(ix + 1, iy);
		float r01 = rxy(ix, iy + 1);
		float r11 = rxy(ix + 1, iy + 1);
	
		auto interp0 = cosInterp(r00, r10, dx);
		auto interp1 = cosInterp(r01, r11, dx);
		v = cosInterp(interp0, interp1, dy)*amp;

		if(octive == 1) return v;
		else return v + getVal(octive-1, startSize*2, amp/2.0f, x, y);
	}

	private float getValR(int octive, int startSize, float amp, float x, float y) {
		import math.interpolate;
		import std.random;
		import std.math;
		
		float v;
		float fx, fy, ix, iy, dx, dy;
		fx = x*startSize;
		fy = y*startSize;
		ix = floor(fx);
		iy = floor(fy);
		dx = fx - ix;
		dy = fy - iy;
		
		float rxy(float x, float y) {
			int id = (cast(int)x)*startSize + (cast(int)y);
			return data[o-octive][id%(data[o-octive].length)]; // loops around if you index to far
		}
		
		float r00 = rxy(ix, iy);
		float r10 = rxy(ix + 1, iy);
		float r01 = rxy(ix, iy + 1);
		float r11 = rxy(ix + 1, iy + 1);
		
		auto interp0 = cosInterp(r00, r10, dx);
		auto interp1 = cosInterp(r01, r11, dx);
		v = cosInterp(interp0, interp1, dy)*amp;
		v = abs(v);

		if(octive == 1) return v;
		else return v + getValR(octive-1, startSize*2, amp/2.0f, x, y);
	}
}

public float perlin(int seed, int octive, int startSize, float amp, float x, float y) {
	import math.interpolate;
	import std.random;
	import std.math;

	float v;
	float fx, fy, ix, iy, dx, dy;
	fx = x*startSize;
	fy = y*startSize;
	ix = floor(fx);
	iy = floor(fy);
	dx = fx - ix;
	dy = fy - iy;

	float rxy(float x, float y) {
		import std.random;
		auto rnd = rndGen();
		rnd.seed(cast(int)(x)*seed + cast(int)(y) + octive + seed);
		auto r = rnd.front;
		return cast(float)((cast(double)r)/uint.max);
	}

	float r00 = rxy(ix, iy);
	float r10 = rxy(ix + 1, iy);
	float r01 = rxy(ix, iy + 1);
	float r11 = rxy(ix + 1, iy + 1);

	auto interp0 = cosInterp(r00, r10, dx);
	auto interp1 = cosInterp(r01, r11, dx);
	v = cosInterp(interp0, interp1, dy)*amp;

	if(octive == 0) return v;
	else return v + perlin(seed, octive-1, startSize*2, amp/2.0f, x, y);
}
