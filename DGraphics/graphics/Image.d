module graphics.Image;
import graphics.Color;
import math.matrix;

struct Image
{
	private int m_width;
	private int m_height;
	public Color[] m_data;

	this(int width, int height)
	{
		m_width = width;
		m_height = height;
		m_data = new Color[width*height];
	}

	@property int Width()  { return m_width; }
	@property int Height()  { return m_height; }

	Color opIndex(int x, int y)
	{
		if(x<0 || y<0 || x>=m_width || y>=m_height) return Color(0); // Silently fail... 
		return m_data[x + y*m_height];
	}

	Color opIndexAssign(Color c, int x, int y)
	{
		if(x>=0 || y>=0 || x<m_width || y<m_height) m_data[x + y*m_height] = c; // Silently fail... 
		return c;
	}

	Color opIndex(vec2i index)
	{
		return opIndex(index.x,index.y);
	}
	
	Color opIndexAssign(Color c, vec2i index)
	{
		return opIndexAssign(c, index.x, index.y);
	}


	Color opIndex(vec2 index)
	{
		return opIndex(cast(int)index.x,cast(int)index.y);
	}
	
	Color opIndexAssign(Color c, vec2 index)
	{
		return opIndexAssign(c, cast(int)index.x, cast(int)index.y);
	}
}

