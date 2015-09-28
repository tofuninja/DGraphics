module math.noise.poissondisk;

import std.math;
import math.matrix;
import std.random;

import std.stdio;

vec2[] pDisk(int seed, float size, float r, int k = 30)
{

	float cSize = r / SQRT2;
	int gridSize = cast(int)ceil(size/cSize);

	int[] grid = new int[gridSize*gridSize];
	grid[] = -1;

	auto active = ArrayList!int(gridSize*gridSize);
	auto points = ArrayList!vec2(gridSize*gridSize);

	ivec2 gridLoc(vec2 p)
	{
		return cast(ivec2)(p/cSize);
	}

	int gridID(ivec2 p)
	{
		return p.x*gridSize + p.y;
	}

	void newPoint(vec2 p)
	{
		int id = points.size;
		points.insert(p);
		active.insert(id);
		grid[gridID(gridLoc(p))] = id;
	}

	auto rnd = rndGen();
	rnd.seed(seed);

	auto fx = cast(float)((cast(double)rnd.front)/uint.max)*size;
	rnd.popFront();
	auto fy = cast(float)((cast(double)rnd.front)/uint.max)*size;
	rnd.popFront();

	newPoint(vec2(fx,fy));

	while(active.size > 0)
	{
		int activeId = rnd.front%active.size;
		rnd.popFront();
		int id = active.get(activeId);
		vec2 curP = points.get(id);
		bool added = false;

		for(int i = 0; i < k; i++)
		{
			float nr = cast(float)((cast(double)rnd.front)/uint.max)*r + r;
			rnd.popFront();
			auto a = cast(float)((cast(double)rnd.front)/uint.max)*2.0f*PI;
			rnd.popFront();


			auto dir = vec2(sin(a),cos(a));
			auto newP = curP + dir*nr;
			auto newpGridLoc = gridLoc(newP);
			if(newpGridLoc.x < 0 || newpGridLoc.y < 0 || newpGridLoc.x >= gridSize || newpGridLoc.y >= gridSize) continue;
			if(grid[gridID(newpGridLoc)] != -1) continue;

			bool checkGrid(ivec2 gp, vec2 cp)
			{
				if(gp.x < 0 || gp.y < 0 || gp.x >= gridSize || gp.y >= gridSize) return false;
				int gpID = grid[gridID(gp)];
				if(gpID == -1) return true;
				vec2 gpPoint = points.get(gpID);
				if((cp-gpPoint).length() < r) return false;
				return true;
			}

			bool check = checkGrid(newpGridLoc + ivec2(1,0), newP);
			check = check && checkGrid(newpGridLoc + ivec2(1,1), newP);
			check = check && checkGrid(newpGridLoc + ivec2(0,1), newP);
			check = check && checkGrid(newpGridLoc + ivec2(-1,1), newP);
			check = check && checkGrid(newpGridLoc + ivec2(-1,0), newP);
			check = check && checkGrid(newpGridLoc + ivec2(-1,-1), newP);
			check = check && checkGrid(newpGridLoc + ivec2(0,-1), newP);
			check = check && checkGrid(newpGridLoc + ivec2(1,-1), newP);
			if(check)
			{
				newPoint(newP);
				added = true;
				break;
			}
		}
		if(!added) active.remove(activeId);
	}

	return points.dat[0 .. points.size];
}

private struct ArrayList(T)
{
	int size = 0;
	public T[] dat;

	public this(int max)
	{
		dat = new T[max];
	}

	public void insert(T v)
	{
		dat[size] = v;
		size ++;
	}

	public T remove(int i)
	{
		T r = dat[i];
		for(int j = i; j < size - 1; j++)
		{
			dat[j] = dat[j + 1];
		}
		size --;
		return r;
	}

	public T get(int i)
	{
		return dat[i];
	}

}