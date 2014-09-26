module graphics.render;

import std.range;
import math.matrix;
import std.algorithm;
import std.stdio;
import std.math;
import graphics.Image;
import graphics.Color;


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

	int opApply(int delegate(ivec2) dg)
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

	private int fillTop(vec2 v1, vec2 v2, vec2 v3, int delegate(ivec2) dg)
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

	private int fillBot(vec2 v1, vec2 v2, vec2 v3, int delegate(ivec2) dg)
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

	private int fillLine(int x1, int x2, int y, int delegate(ivec2) dg)
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
			result = dg(ivec2(x,y));
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
		img[point] = alphaBlend(c, img[point]);
	}
}

void drawTriangleFill(Image img, vec2 p1, vec2 p2, vec2 p3, Color c)
{
	foreach(ivec2 point; triangleRaster(p1, p2, p3))
	{
		img[point] = alphaBlend(c, img[point]);
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
			img.pixel(i,j) = alphaBlend(c, img.pixel(i,j));
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