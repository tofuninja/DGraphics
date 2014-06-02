module graphics.render;

import std.range;
import math.matrix;
import std.algorithm;
import std.stdio;
import std.math;

/**
 * A structure for rasterizing an triangle.
 * It is implimented as an opApply.
 * 
 * Example use:
 * foreach(vec2i p; triangleRaster(v1,v2,v3))
 * {
 * 		... 
 * }
 */
struct triangleRaster
{
	private vec2[3] m_data;

	public this(vec2[3] points ...)
	{
		vec2[] arr = points;
		m_data = arr.sort!("a.y < b.y").array;
	}

	int opApply(int delegate(vec2i) dg)
	{
		int result = 0;
		if (m_data[1].y == m_data[2].y)
		{
			result = fillBot(m_data[0], m_data[1], m_data[2], dg);
			if(result) return result;
		}
		else if (m_data[0].y == m_data[1].y)
		{
			result = fillTop(m_data[0], m_data[1], m_data[2], dg);
			if(result) return result;
		} 
		else
		{
			vec2 v4 = vec2(m_data[0].x + ((m_data[1].y-m_data[0].y)/(m_data[2].y-m_data[0].y))*(m_data[2].x-m_data[0].x),m_data[1].y);
			result = fillBot(m_data[0], m_data[1], v4, dg);
			if(result) return result;
			result = fillTop(m_data[1], v4, m_data[2], dg);
			if(result) return result;
		}

		return result;
	}

	private int fillTop(vec2 v1, vec2 v2, vec2 v3, int delegate(vec2i) dg)
	{
		int result = 0;
		
		float invslope1 = (v3.x - v1.x) / (v3.y - v1.y);
		float invslope2 = (v3.x - v2.x) / (v3.y - v2.y);
		
		float curx1 = v3.x;
		float curx2 = v3.x;
		
		for (int scanlineY = cast(int)v3.y; scanlineY > v1.y; scanlineY--)
		{
			curx1 -= invslope1;
			curx2 -= invslope2;
			result = fillLine(cast(int)curx1, cast(int)curx2, scanlineY, dg);
			if (result) break;
		}
		
		return result;
	}

	private int fillBot(vec2 v1, vec2 v2, vec2 v3, int delegate(vec2i) dg)
	{
		int result = 0;

		float invslope1 = (v2.x - v1.x) / (v2.y - v1.y);
		float invslope2 = (v3.x - v1.x) / (v3.y - v1.y);
		
		float curx1 = v1.x;
		float curx2 = v1.x;
		
		for (int scanlineY = cast(int)v1.y; scanlineY <= v2.y; scanlineY++)
		{
			result = fillLine(cast(int)curx1, cast(int)curx2, scanlineY, dg);
			if (result) break;
			curx1 += invslope1;
			curx2 += invslope2;
		}

		return result;
	}

	private int fillLine(int x1, int x2, int y, int delegate(vec2i) dg)
	{
		int result = 0;
		if(x2 < x1)
		{
			int t = x2;
			x2 = x1;
			x1 = t;
		}

		for(int x = x1 ; x <= x2; x++)
		{
			result = dg(vec2i(x,y));
			if (result) break;
		}
		return result;
	}

}

/**
 * A structure for rasterizing an line.
 * It is implimented as an opApply.
 * 
 * Example use:
 * foreach(vec2i p; lineRaster(v1,v2))
 * {
 * 		... 
 * }
 */
struct lineRaster
{
	int x0,x1,y0,y1;
	this(vec2 vector1, vec2 vector2)
	{
		x0 = cast(int)vector1.x;
		x1 = cast(int)vector2.x;
		y0 = cast(int)vector1.y;
		y1 = cast(int)vector2.y;
	}


	int opApply(int delegate(vec2i) dg)
	{
		int result = 0;

		int dx = abs(x1-x0);
		int sx = x0<x1 ? 1 : -1;
		int dy = abs(y1-y0);
		int sy = y0<y1 ? 1 : -1; 
		int err = (dx>dy ? dx : -dy)/2;
		int e2;
		
		for(;;){
			result = dg(vec2i(x0,y0));
			if ( result || (x0==x1 && y0==y1) ) break;
			e2 = err;
			if (e2 >-dx) { err -= dy; x0 += sx; }
			if (e2 < dy) { err += dx; y0 += sy; }
		}
		
		return result;
	}
}

