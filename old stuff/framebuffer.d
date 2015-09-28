module graphics.frameBuffer;

import graphics.image;
import graphics.color;
import math.matrix;
import std.stdio;

class FrameBuffer : Image
{
	
	private bool alphaBlending = true;
	private bool depthCheck = true;
	public float[] depthBuffer;
	
	
	
	public this(int w, int h, bool alpha, bool depth)
	{
		
		alphaBlending = alpha;
		depthCheck = depth;
		if(depth)
		{
			depthBuffer = new float[w*h];
			clearDepth();
		}
		super(w, h);
	}
	
	override public void setPixel3D(vec3 p, Color c) 
	{
		int x = cast(int) p.x;
		int y = cast(int) p.y;
		
		if(depthCheck)
		{
			if(depth(x,y) < p.z)
			{
				if(alphaBlending)
				{
					m_data[x + y*m_width] = alphaBlend(c, m_data[x + y*m_width]);
				}
				else
				{
					m_data[x + y*m_width] = c;
				}
				
				depth(x,y) = p.z;
			}
		}
		else
		{
			if(alphaBlending)
			{
				m_data[x + y*m_width] = alphaBlend(c, m_data[x + y*m_width]);
			}
			else
			{
				m_data[x + y*m_width] = c;
			}
		}
	}
	
	public ref depth(int x, int y)
	{
		return depthBuffer[x + y*m_width];
	}

	public float depthLookupNearest(vec2 uv)
	{
		import std.math;
		int w,h;
		w = this.Width;
		h = this.Height;
		
		float inBounds(int xl, int yl)
		{
			if(xl < 0 || yl < 0 || xl >= w || yl >= h) return float.infinity;
			return depth(xl,yl);
		}
		
		float u = uv.x;
		float v = uv.y;
		
		float x = (u*(w/2.0f) + (w/2.0f));
		float y = (v*(h/2.0f) + (h/2.0f));
		
		int ix = cast(int)x;
		int iy = cast(int)y;

		return inBounds(ix,iy);
	}
	
	public void clearDepth()
	{
		for(int i = 0; i < m_width*m_height; i++) depthBuffer[i] = -float.infinity;
	}
	
}