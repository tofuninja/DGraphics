module graphics.render;

import std.range;
import math.matrix;
import std.algorithm;
import std.stdio;
import std.math;
import graphics.image;
import graphics.color;
import std.traits;
import std.typecons;
import std.typetuple;

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
	vec2 v1,v2,v3;
	ivec2 bounds;
	
	public this(ivec2 bound, vec2[3] points ...)
	{
		v1 = points[0];
		v2 = points[1];
		v3 = points[2];
		bounds = bound;
	}
	
	int opApply(int delegate(ivec2) dg)
	{
		int result = 0;
		
		// 28.4 fixed-point coordinates
		
		int iround(float x)
		{
			return cast(int) x;
		}
		
		const int Y1 = iround(16.0f * v1.y);
		const int Y2 = iround(16.0f * v2.y);
		const int Y3 = iround(16.0f * v3.y);
		
		const int X1 = iround(16.0f * v1.x);
		const int X2 = iround(16.0f * v2.x);
		const int X3 = iround(16.0f * v3.x);
		
		// Deltas
		const int DX12 = X1 - X2;
		const int DX23 = X2 - X3;
		const int DX31 = X3 - X1;
		
		const int DY12 = Y1 - Y2;
		const int DY23 = Y2 - Y3;
		const int DY31 = Y3 - Y1;
		
		// Fixed-point deltas
		const int FDX12 = DX12 << 4;
		const int FDX23 = DX23 << 4;
		const int FDX31 = DX31 << 4;
		
		const int FDY12 = DY12 << 4;
		const int FDY23 = DY23 << 4;
		const int FDY31 = DY31 << 4;
		
		// Bounding rectangle
		int minx = (min(X1, X2, X3) + 0xF) >> 4;
		int maxx = (max(X1, X2, X3) + 0xF) >> 4;
		int miny = (min(Y1, Y2, Y3) + 0xF) >> 4;
		int maxy = (max(Y1, Y2, Y3) + 0xF) >> 4;
		
		if(minx < 0) minx = 0;
		if(miny < 0) miny = 0;
		if(maxx > bounds.x) maxx = bounds.x;
		if(maxy > bounds.y) maxy = bounds.y;

		// Block size, standard 8x8 (must be power of two)
		const int q = 8;
		
		// Start in corner of 8x8 block
		minx &= ~(q - 1);
		miny &= ~(q - 1);
		
		//int colorBuffer += miny * stride;
		
		// Half-edge constants
		int C1 = DY12 * X1 - DX12 * Y1;
		int C2 = DY23 * X2 - DX23 * Y2;
		int C3 = DY31 * X3 - DX31 * Y3;
		
		// Correct for fill convention
		if(DY12 < 0 || (DY12 == 0 && DX12 > 0)) C1++;
		if(DY23 < 0 || (DY23 == 0 && DX23 > 0)) C2++;
		if(DY31 < 0 || (DY31 == 0 && DX31 > 0)) C3++;

		// Loop through blocks
		for(int y = miny; y < maxy; y += q)
		{
			for(int x = minx; x < maxx; x += q)
			{
				// Corners of block
				int x0 = x << 4;
				int x1 = (x + q - 1) << 4;
				int y0 = y << 4;
				int y1 = (y + q - 1) << 4;
				
				// Evaluate half-space functions
				bool a00 = C1 + DX12 * y0 - DY12 * x0 > 0;
				bool a10 = C1 + DX12 * y0 - DY12 * x1 > 0;
				bool a01 = C1 + DX12 * y1 - DY12 * x0 > 0;
				bool a11 = C1 + DX12 * y1 - DY12 * x1 > 0;
				int a = (a00 << 0) | (a10 << 1) | (a01 << 2) | (a11 << 3);
				
				bool b00 = C2 + DX23 * y0 - DY23 * x0 > 0;
				bool b10 = C2 + DX23 * y0 - DY23 * x1 > 0;
				bool b01 = C2 + DX23 * y1 - DY23 * x0 > 0;
				bool b11 = C2 + DX23 * y1 - DY23 * x1 > 0;
				int b = (b00 << 0) | (b10 << 1) | (b01 << 2) | (b11 << 3);
				
				bool c00 = C3 + DX31 * y0 - DY31 * x0 > 0;
				bool c10 = C3 + DX31 * y0 - DY31 * x1 > 0;
				bool c01 = C3 + DX31 * y1 - DY31 * x0 > 0;
				bool c11 = C3 + DX31 * y1 - DY31 * x1 > 0;
				int c = (c00 << 0) | (c10 << 1) | (c01 << 2) | (c11 << 3);
				
				// Skip block when outside an edge
				if(a == 0x0 || b == 0x0 || c == 0x0) continue;
				
				// Accept whole block when totally covered
				if(a == 0xF && b == 0xF && c == 0xF)
				{
					for(int iy = y; iy < y + q; iy++)
					{
						for(int ix = x; ix < x + q; ix++)
						{
							result = dg(ivec2(ix,iy));
							if (result) return result;
						}
					}
				}
				else// Partially covered block
				{
					int CY1 = C1 + DX12 * y0 - DY12 * x0;
					int CY2 = C2 + DX23 * y0 - DY23 * x0;
					int CY3 = C3 + DX31 * y0 - DY31 * x0;
					
					for(int iy = y; iy < y + q; iy++)
					{
						int CX1 = CY1;
						int CX2 = CY2;
						int CX3 = CY3;
						
						for(int ix = x; ix < x + q; ix++)
						{
							if(CX1 > 0 && CX2 > 0 && CX3 > 0)
							{
								result = dg(ivec2(ix,iy));
								if (result) return result;
							}
							
							CX1 -= FDY12;
							CX2 -= FDY23;
							CX3 -= FDY31;
						}
						
						CY1 += FDX12;
						CY2 += FDX23;
						CY3 += FDX31;
					}
				}
			}
		}
		
		return result;
	}
}

/*
struct triangleRaster3D
{
	vec3 v1,v2,v3;

	public this(vec3[3] points ...)
	{
		v1 = points[0];
		v2 = points[1];
		v3 = points[2];
	}
	
	int opApply(int delegate(vec3, vec3) dg)
	{
		int result = 0;

		// 28.4 fixed-point coordinates

		int iround(float x)
		{
			return cast(int) x;
		}

		const int Y1 = iround(16.0f * v1.y);
		const int Y2 = iround(16.0f * v2.y);
		const int Y3 = iround(16.0f * v3.y);
		
		const int X1 = iround(16.0f * v1.x);
		const int X2 = iround(16.0f * v2.x);
		const int X3 = iround(16.0f * v3.x);
		
		// Deltas
		const int DX12 = X1 - X2;
		const int DX23 = X2 - X3;
		const int DX31 = X3 - X1;
		
		const int DY12 = Y1 - Y2;
		const int DY23 = Y2 - Y3;
		const int DY31 = Y3 - Y1;
		
		// Fixed-point deltas
		const int FDX12 = DX12 << 4;
		const int FDX23 = DX23 << 4;
		const int FDX31 = DX31 << 4;
		
		const int FDY12 = DY12 << 4;
		const int FDY23 = DY23 << 4;
		const int FDY31 = DY31 << 4;
		
		// Bounding rectangle
		int minx = (min(X1, X2, X3) + 0xF) >> 4;
		int maxx = (max(X1, X2, X3) + 0xF) >> 4;
		int miny = (min(Y1, Y2, Y3) + 0xF) >> 4;
		int maxy = (max(Y1, Y2, Y3) + 0xF) >> 4;
		
		// Block size, standard 8x8 (must be power of two)
		const int q = 8;
		
		// Start in corner of 8x8 block
		minx &= ~(q - 1);
		miny &= ~(q - 1);
		
		//int colorBuffer += miny * stride;
		
		// Half-edge constants
		int C1 = DY12 * X1 - DX12 * Y1;
		int C2 = DY23 * X2 - DX23 * Y2;
		int C3 = DY31 * X3 - DX31 * Y3;
		
		// Correct for fill convention
		if(DY12 < 0 || (DY12 == 0 && DX12 > 0)) C1++;
		if(DY23 < 0 || (DY23 == 0 && DX23 > 0)) C2++;
		if(DY31 < 0 || (DY31 == 0 && DX31 > 0)) C3++;
		
		// Loop through blocks
		for(int y = miny; y < maxy; y += q)
		{
			for(int x = minx; x < maxx; x += q)
			{
				// Corners of block
				int x0 = x << 4;
				int x1 = (x + q - 1) << 4;
				int y0 = y << 4;
				int y1 = (y + q - 1) << 4;
				
				// Evaluate half-space functions
				bool a00 = C1 + DX12 * y0 - DY12 * x0 > 0;
				bool a10 = C1 + DX12 * y0 - DY12 * x1 > 0;
				bool a01 = C1 + DX12 * y1 - DY12 * x0 > 0;
				bool a11 = C1 + DX12 * y1 - DY12 * x1 > 0;
				int a = (a00 << 0) | (a10 << 1) | (a01 << 2) | (a11 << 3);
				
				bool b00 = C2 + DX23 * y0 - DY23 * x0 > 0;
				bool b10 = C2 + DX23 * y0 - DY23 * x1 > 0;
				bool b01 = C2 + DX23 * y1 - DY23 * x0 > 0;
				bool b11 = C2 + DX23 * y1 - DY23 * x1 > 0;
				int b = (b00 << 0) | (b10 << 1) | (b01 << 2) | (b11 << 3);
				
				bool c00 = C3 + DX31 * y0 - DY31 * x0 > 0;
				bool c10 = C3 + DX31 * y0 - DY31 * x1 > 0;
				bool c01 = C3 + DX31 * y1 - DY31 * x0 > 0;
				bool c11 = C3 + DX31 * y1 - DY31 * x1 > 0;
				int c = (c00 << 0) | (c10 << 1) | (c01 << 2) | (c11 << 3);
				
				// Skip block when outside an edge
				if(a == 0x0 || b == 0x0 || c == 0x0) continue;
				
				// Accept whole block when totally covered
				if(a == 0xF && b == 0xF && c == 0xF)
				{
					for(int iy = y; iy < y + q; iy++)
					{
						for(int ix = x; ix < x + q; ix++)
						{
							vec3 bc = Barycentric(vec3(ix,iy,0), vec3(v1.x,v1.y,0),vec3(v2.x,v2.y,0),vec3(v3.x,v3.y,0));
							float z = bc.x/v1.z + bc.y/v2.z + bc.z/v3.z;
							result = dg(vec3(ix,iy,1.0f/z),bc);
							if (result) return result;
						}
					}
				}
				else// Partially covered block
				{
					int CY1 = C1 + DX12 * y0 - DY12 * x0;
					int CY2 = C2 + DX23 * y0 - DY23 * x0;
					int CY3 = C3 + DX31 * y0 - DY31 * x0;
					
					for(int iy = y; iy < y + q; iy++)
					{
						int CX1 = CY1;
						int CX2 = CY2;
						int CX3 = CY3;
						
						for(int ix = x; ix < x + q; ix++)
						{
							if(CX1 > 0 && CX2 > 0 && CX3 > 0)
							{
								vec3 bc = Barycentric(vec3(ix,iy,0), vec3(v1.x,v1.y,0),vec3(v2.x,v2.y,0),vec3(v3.x,v3.y,0));
								float z = bc.x/v1.z + bc.y/v2.z + bc.z/v3.z;
								result = dg(vec3(ix,iy,1.0f/z),bc);
								if (result) return result;
							}
							
							CX1 -= FDY12;
							CX2 -= FDY23;
							CX3 -= FDY31;
						}
						
						CY1 += FDX12;
						CY2 += FDX23;
						CY3 += FDX31;
					}
				}
			}
		}
		
		return result;
	}
}*/


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
	
	
	int opApply(int delegate(ivec2) dg)
	{
		int result = 0;
		
		int dx = abs(x1-x0);
		int sx = x0<x1 ? 1 : -1;
		int dy = abs(y1-y0);
		int sy = y0<y1 ? 1 : -1; 
		int err = (dx>dy ? dx : -dy)/2;
		int e2;
		
		for(;;){
			result = dg(ivec2(x0,y0));
			if ( result || (x0==x1 && y0==y1) ) break;
			e2 = err;
			if (e2 >-dx) { err -= dy; x0 += sx; }
			if (e2 < dy) { err += dx; y0 += sy; }
		}
		
		return result;
	}
}

struct lineRaster3D
{
	vec3 start;
	vec3 end;
	this(vec3 vector1, vec3 vector2)
	{
		start = vector1;
		end = vector2;
	}
	
	
	int opApply(int delegate(vec3, float) dg)
	{
		import math.conversion;
		int result = 0;
		int x0 = cast(int)start.x;
		int x1 = cast(int)end.x;
		int y0 = cast(int)start.y;
		int y1 = cast(int)end.y;
		int dx = abs(x1-x0);
		int sx = x0<x1 ? 1 : -1;
		int dy = abs(y1-y0);
		int sy = y0<y1 ? 1 : -1; 
		int err = (dx>dy ? dx : -dy)/2;
		float len = (end.xy - start.xy).length;

		for(;;){
			float percent = (vec2(x0,y0) - start.xy).length/len;
			result = dg(vec3(x0,y0,lerp(start.z, end.z, percent)), percent);
			if ( result || (x0==x1 && y0==y1) ) break;
			int e2 = err;
			if (e2 >-dx) { err -= dy; x0 += sx; }
			if (e2 < dy) { err += dx; y0 += sy; }
		}
		
		return result;
	}
}


struct ellipseRaster
{
	private vec2 c;
	private vec2 s;
	this(vec2 center, vec2 size)
	{
		c = center;
		s = size;
	}

	int opApply(int delegate(ivec2) dg)
	{
		int result = 0;
		s = s / 2.0f;

		float width = s.x;
		float height = s.y;
		float hh = height * height;
		float ww = width * width;
		float hhww = hh * ww;
		float x0 = width;
		float dx = 0;
		
		// do the horizontal diameter
		for (float x = -width; x <= width; x++)
		{
			result = dg(ivec2(cast(int)(c.x + x), cast(int)(c.y)));
			if(result) return result;
		}
		
		// now do both halves at the same time, away from the diameter
		for (float y = 1; y <= height; y++)
		{
			float x1 = x0 - (dx - 1);  // try slopes of dx - 1 or more
			for ( ; x1 > 0; x1--)
				if (x1*x1*hh + y*y*ww <= hhww)
					break;
			dx = x0 - x1;  // current approximation of the slope
			x0 = x1;
			
			for (float x = -x0; x <= x0; x++)
			{
				result = dg(ivec2(cast(int)(c.x + x), cast(int)(c.y - y)));
				if(result) return result;
				result = dg(ivec2(cast(int)(c.x + x), cast(int)(c.y + y)));
				if(result) return result;
			}
		}

		return result;
	}
}

struct ellipseEdgeRaster
{
	private vec2 c;
	private vec2 s;
	private float angle1;
	private float angle2;
	this(vec2 center, vec2 size, float startAngle, float endAngle)
	{
		c = center;
		s = size;
		angle1 = startAngle;
		angle2 = endAngle;
		while(angle1 > PI) angle1 -= PI*2.0f;
		while(angle2 > PI) angle2 -= PI*2.0f;
		while(angle1 < -PI) angle1 += PI*2.0f;
		while(angle2 < -PI) angle2 += PI*2.0f;
		if(angle2 <= angle1) angle2 += PI*2.0f;
	}
	
	int opApply(int delegate(ivec2) dg)
	{
		int result = 0;
		s = s / 2.0f;
		int width = cast(int) s.x;
		int height = cast(int) s.y;
		int a2 = width * width;
		int b2 = height * height;
		int fa2 = 4 * a2;
		int fb2 = 4 * b2;
		int x0, y0, x, y, sigma;
		x0 = cast(int)c.x;
		y0 = cast(int)c.y;

		bool f(int x, int y)
		{
			float a = atan2(cast(float)y, cast(float)x);
			if(a < angle1) a += PI*2.0f;
			if(a > angle1 && a < angle2)
			{
				result = dg(ivec2(x0 + x, y0 + y)); 
				if(result) return true;
			}
			return false;
		}
		
		/* first half */
		for (x = 0, y = height, sigma = 2*b2+a2*(1-2*height); b2*x <= a2*y; x++)
		{
			if(f(  x,   y)) return result;
			if(f(- x,   y)) return result;
			if(f(  x, - y)) return result;
			if(f(- x, - y)) return result;
			if (sigma >= 0)
			{
				sigma += fa2 * (1 - y);
				y--;
			}
			sigma += b2 * ((4 * x) + 6);
		}
		
		/* second half */
		for (x = width, y = 0, sigma = 2*a2+b2*(1-2*width); a2*y <= b2*x; y++)
		{
			if(f(   x,   y)) return result;
			if(f( - x,   y)) return result;
			if(f(   x, - y)) return result;
			if(f( - x, - y)) return result;
			if (sigma >= 0)
			{
				sigma += fb2 * (1 - x);
				x--;
			}
			sigma += a2 * ((4 * y) + 6);
		}
		
		return result;
	}
}

void drawLine(Image img, vec2 start, vec2 end, Color c)
{
	foreach(ivec2 point; lineRaster(start, end))
	{
		img[point] = c;
	}
}

void drawTriangleFill(Image img, vec2 p1, vec2 p2, vec2 p3, Color c)
{
	foreach(ivec2 point; triangleRaster(ivec2(img.Width, img.Height),p1, p2, p3))
	{
		img[point] = c;
	}
}

void drawBoxFill(Image img, vec2 loc, vec2 size, Color c)
{
	import std.algorithm;
	int w = cast(int)size.x;
	int h = cast(int)size.y;
	int x = cast(int)loc.x;
	int y = cast(int)loc.y;

	int destW = img.Width;
	int destH = img.Height;

	for(int i = max(x,0); i < min(x+w, destW); i++)
	{
		for(int j = max(y,0); j < min(y+h, destH); j++)
		{
			img.setPixel(i,j, c);
		}
	}
}

void drawBox(Image img, vec2 loc, vec2 size, Color c)
{
	vec2 p1 = loc;
	vec2 p2 = loc; 
	p2.x += size.x - 1;
	vec2 p3 = loc;
	p3.x += size.x - 1;
	p3.y += size.y - 1;
	vec2 p4 = loc;
	p4.y += size.y - 1;

	img.drawLine(p1, p2, c);
	img.drawLine(p2, p3, c);
	img.drawLine(p4, p3, c);
	img.drawLine(p1, p4, c);
}

void drawEllipseFill(Image img, vec2 center, vec2 size, Color c)
{
	foreach(ivec2 p; ellipseRaster(center, size))
	{
		img[p] = c;
	}
}

void drawEllipse(Image img, vec2 center, vec2 size, float startAngle, float endAngle, Color c)
{
	foreach(ivec2 p; ellipseEdgeRaster(center, size, startAngle, endAngle))
	{
		img[p] = c;
	}
}

void drawEllipse(Image img, vec2 center, vec2 size, Color c)
{
	foreach(ivec2 p; ellipseEdgeRaster(center, size, 0, 0))
	{
		img[p] = c;
	}
}

void drawRoundedRectangle(Image img, vec2 loc, vec2 size, float r, Color c)
{
	size = size - vec2(1,1);
	img.drawEllipse(loc + vec2(0, size.y) + vec2(r,-r), vec2(r*2, r*2), (PI/2.0f) , PI, c);
	img.drawEllipse(loc + size + vec2(-r,-r), vec2(r*2, r*2), 0 , PI/2.0f, c);
	img.drawEllipse(loc + vec2(size.x, 0) + vec2(-r,r), vec2(r*2, r*2), (3.0f*PI)/2.0f , 2.0f*PI, c);
	img.drawEllipse(loc + vec2(r,r), vec2(r*2, r*2), PI , (3.0f*PI)/2.0f, c);
	
	img.drawLine(loc + vec2(r, 0), loc + vec2(-r, 0) + vec2(size.x, 0), c);
	img.drawLine(loc + vec2(0, r) + vec2(size.x, 0), loc + vec2(0, -r) + size, c); 
	img.drawLine(loc + vec2(-r, 0) + size, loc + vec2(r, 0) + vec2(0, size.y), c);
	img.drawLine(loc + vec2(0, -r) + vec2(0, size.y), loc + vec2(0, r), c);
}

void drawRoundedRectangleFill(Image img, vec2 loc, vec2 size, float r, Color c)
{
	vec2 ballSize = vec2(r*2, r*2);
	size = size - vec2(1,1);
	img.drawEllipseFill(loc + vec2(0, size.y) + vec2(r,-r), ballSize, c);
	img.drawEllipseFill(loc + size + vec2(-r,-r), ballSize, c);
	img.drawEllipseFill(loc + vec2(size.x, 0) + vec2(-r,r), ballSize, c);
	img.drawEllipseFill(loc + vec2(r,r), ballSize, c);
	
	img.drawBoxFill(loc + vec2(r, r), size - vec2(r*2, r*2), c);
	img.drawBoxFill(loc + vec2(0, r), vec2(r, size.y-r*2), c);
	img.drawBoxFill(loc + vec2(r, 0), vec2(size.x-r*2, r), c);
	img.drawBoxFill(loc + vec2(size.x - r, r), vec2(r, size.y-r*2), c);
	img.drawBoxFill(loc + vec2(r, size.y - r), vec2(size.x-r*2, r), c);
}

void AALine(Image img, vec2 start, vec2 end)
{
	foreach(ivec2 point; lineRaster(start, end))
	{
		img.AAPoint(point);
	}
}

void AAPoint(Image img, ivec2 point)
{
	enum c1o20 = 1.0f/20.0f;
	enum c1o10 = 1.0f/10.0f;
	enum c1o5 = 1.0f/5.0f;
	enum kernal = mat3(c1o20, c1o10, c1o20, c1o10, c1o5, c1o10, c1o20, c1o10, c1o20);

	float R = 0;
	float G = 0;
	float B = 0;
	for(int i = 0; i < 3; i ++)
	{
		for(int j = 0; j < 3; j++)
		{
			Color c = img[point + ivec2(i - 1, j - 1)];
			R += c.R*kernal[i,j];
			G += c.G*kernal[i,j];
			B += c.B*kernal[i,j];
		}
	}

	img[point] = Color(cast(ubyte) R, cast(ubyte) G, cast(ubyte) B); 
}

void AAEllipse(Image img, vec2 center, vec2 size, float startAngle, float endAngle)
{
	foreach(ivec2 p; ellipseEdgeRaster(center, size, startAngle, endAngle))
	{
		img.AAPoint(p);
	}
	/*
	size = size / 2.0f;
	if(endAngle < startAngle)
	{
		float t = endAngle;
		endAngle = startAngle;
		startAngle = t;
	}
	
	float deltaR = PI/20;
	
	float r1 = startAngle;
	float r2 = r1 + deltaR;
	while(true)
	{
		if(r2 > endAngle) r2 = endAngle;
		vec2 start = vec2(cos(r1)*size.x, sin(r1)*size.y) + center;
		vec2 end = vec2(cos(r2)*size.x, sin(r2)*size.y) + center;
		img.AALine(start, end);
		r1 = r2;
		r2 += deltaR;
		if(r1 == endAngle) break;
	}*/
}

void AARoundedRectangle(Image img, vec2 loc, vec2 size, float r)
{
	img.AAEllipse(loc + vec2(0, size.y) + vec2(r,-r), vec2(r*2, r*2), (PI/2.0f) , PI);
	img.AAEllipse(loc + size + vec2(-r,-r), vec2(r*2, r*2), 0 , PI/2.0f);
	img.AAEllipse(loc + vec2(size.x, 0) + vec2(-r,r), vec2(r*2, r*2), (3.0f*PI)/2.0f , 2.0f*PI);
	img.AAEllipse(loc + vec2(r,r), vec2(r*2, r*2), PI , (3.0f*PI)/2.0f);
	
	img.AALine(loc + vec2(r, 0), loc + vec2(-r, 0) + vec2(size.x, 0));
	img.AALine(loc + vec2(0, r) + vec2(size.x, 0), loc + vec2(0, -r) + size); 
	img.AALine(loc + vec2(-r, 0) + size, loc + vec2(r, 0) + vec2(0, size.y));
	img.AALine(loc + vec2(0, -r) + vec2(0, size.y), loc + vec2(0, r));
}

vec3 Barycentric(vec3 p, vec3 a, vec3 b, vec3 c)
{
	import util.debugger;
	float u,v,w;
	vec3 v0 = b - a;
	vec3 v1 = c - a;
	vec3 v2 = p - a;
	float d00 = dot(v0, v0);
	float d01 = dot(v0, v1);
	float d11 = dot(v1, v1);
	float d20 = dot(v2, v0);
	float d21 = dot(v2, v1);
	float denom = d00 * d11 - d01 * d01;
	v = (d11 * d20 - d01 * d21) / denom;
	w = (d00 * d21 - d01 * d20) / denom;
	u = 1.0f - v - w;
	vec3 rtn = vec3(u,v,w);

	//writeln(rtn);
	//writeln(u+v+w);
	//breakPoint();
	return rtn;
}


bool isVertexShader(alias f)()
{
	import std.traits;
	static if(!isCallable!(f)) return false;
	else
	{
		alias T = ReturnType!(f);
		static if(!__traits(isPOD, T)) return false;
		T t;
		static if(!__traits(hasMember, t, "pos")) return false;
		else
		{
			static if(!is(typeof(__traits(getMember, t, "pos")) == vec4)) return false;
		}

        static if(!(arity!f >= 1)) return false;
		else
		{
			alias T2 = ParameterTypeTuple!f[0];
			static if(!is(T2 == vec3)) return false; // First arg is always the pos
		}
	}
	return true;
}

bool isPixelShader(alias f)()
{
	import std.traits;
	static if(!isCallable!(f)) return false;
	else
	{
		alias T = ReturnType!(f);
		static if(!is(T == Color)) return false;
		static if(arity!f != 1) return false;
		else
		{
			alias T2 = ParameterTypeTuple!f[0];
			static if(!__traits(isPOD, T2)) return false;
			T2 t2;
			static if(!__traits(hasMember, T2, "pos")) return false;
			else
			{
				static if(!is(typeof(__traits(getMember, t2, "pos")) == vec4)) return false;
			}
		}
	}
	return true;
}

template arrayType(T)
{
	alias arrayType = T[];
}

auto multiAccess(Args...)(int i, staticMap!(arrayType, Args) args)
{
	static if(args.length == 1) return tuple(args[0][i]);
	else return tuple(args[0][i], multiAccess!(Args[1 .. $])(i,args[1 .. $]).tupleof);
}


T bcenInterp(T)(T v1, T v2, T v3, vec3 uvw, vec3 depth)
{
	T rtn;
	float z1 = depth.x;
	float z2 = depth.y;
	float z3 = depth.z;
	foreach(mem; __traits(allMembers, T))
	{
		static if(mem != "pos")
		{
			static if(anySatisfy!(checkAffine, __traits(getAttributes, __traits(getMember, rtn, mem))))
			{
				// Affine
				static if(__traits(compiles, affineInterp(__traits(getMember, v1, mem), __traits(getMember, v2, mem), __traits(getMember, v3), mem, uvw, vec3(z1, z2, z3)))) 
				{
					// If affineInterp exists for type the use it
					__traits(getMember, rtn, mem) = affineInterp(__traits(getMember, v1, mem), __traits(getMember, v2, mem), __traits(getMember, v3, mem), uvw, vec3(z1, z2, z3));
				}
				else
				{
					// Generic affine interpolation
					__traits(getMember, rtn, mem) = __traits(getMember, v1, mem)*uvw.x + __traits(getMember, v2, mem)*uvw.y + __traits(getMember, v3, mem)*uvw.z;
				}
			}
			else
			{
				// Perspective corect
				static if(__traits(compiles, perpInterp(__traits(getMember, v1, mem), __traits(getMember, v2, mem), __traits(getMember, v3, mem), uvw, vec3(z1, z2, z3)))) 
				{
					// If perpInterp exists for type the use it
					__traits(getMember, rtn, mem) = perpInterp(__traits(getMember, v1, mem), __traits(getMember, v2, mem), __traits(getMember, v3, mem), uvw, vec3(z1, z2, z3));
				}
				else
				{
					// Generic perspective interpolation
					//static if(is(typeof(__traits(getMember, v1, mem)) == vec2)) writeln("test");
					auto tmp = (__traits(getMember, v1, mem)*uvw.x)/z1 + (__traits(getMember, v2, mem)*uvw.y)/z2 + (__traits(getMember, v3, mem)*uvw.z)/z3;
					auto denom = (uvw.x/z1) + (uvw.y/z2) + (uvw.z/z3);
					__traits(getMember, rtn, mem) = tmp / denom;
				}
			}
		}
	}

	return rtn;
}

private template checkAffine(alias t)
{
	static if(is(t == Affine)) alias checkAffine = TRUE;
	else alias checkAffine = FALSE;
}

struct Affine{}

void runShadersIndexed(A,B)(Image frame, A vert, B pix, uvec3[] tris, staticMap!(arrayType, ParameterTypeTuple!A) args)
	if(isVertexShader!A && isPixelShader!B && is(ParameterTypeTuple!B[0] == ReturnType!(A)))
{
	alias T = ReturnType!(A);
	//writeln(args[0]);

	auto size = vec2(frame.Width, frame.Height);
	size = size/2.0f;

	foreach(uvec3 tri; tris)
	{
		// Run vertex shader
		auto v1 = vert(multiAccess!(ParameterTypeTuple!vert)(tri.x,args).tupleof);
		auto v2 = vert(multiAccess!(ParameterTypeTuple!vert)(tri.y,args).tupleof);
		auto v3 = vert(multiAccess!(ParameterTypeTuple!vert)(tri.z,args).tupleof);


		float w1 = v1.pos.w;
		float w2 = v2.pos.w;
		float w3 = v3.pos.w;

		float z1 = v1.pos.z;
		float z2 = v2.pos.z;
		float z3 = v3.pos.z;

		// Divide by w
		v1.pos = v1.pos / w1;
		v2.pos = v2.pos / w2;
		v3.pos = v3.pos / w3;

		if(!((v1.pos.z > -1 && v1.pos.z < 1) && (v2.pos.z > -1 && v2.pos.z < 1) && (v3.pos.z > -1 && v3.pos.z < 1))) continue;

		// Scale to screen
		vec3 A = v1.pos.xyz;
		vec3 B = v2.pos.xyz;
		vec3 C = v3.pos.xyz;
		A.xy = A.xy*size + size;
		B.xy = B.xy*size + size;
		C.xy = C.xy*size + size;

		foreach(ivec2 iv; triangleRaster(ivec2(frame.Width, frame.Height), A.xy, B.xy, C.xy))
		{
			// Calc uvw
			vec3 uvw = Barycentric(vec3(iv.x,iv.y,0), vec3(A.x,A.y,0),vec3(B.x,B.y,0),vec3(C.x,C.y,0));
			//float z = uvw.x/z1 + uvw.y/z2 + uvw.z/z3;
			float z = uvw.x*v1.pos.z + uvw.y*v2.pos.z + uvw.z*v3.pos.z;
			//float w = uvw.x/w1 + uvw.y/w2 + uvw.z/w3;
			auto v = vec3(iv.x,iv.y,z);

			// Interpolate vertex outputs
			T t = bcenInterp(v1, v2, v3, uvw, vec3(w1,w2,w3));
			t.pos.xyz = v;
			t.pos.w = 1;
			// Run pixel shader
			frame[v] = pix(t);
		}
	}
}