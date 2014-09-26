module graphics.Color;

import math.matrix;

struct Color
{
	this(uint rgba)
	{
		RGBA = rgba;
	}

	this(ubyte red, ubyte green, ubyte blue, ubyte alpha)
	{
		R = red;
		G = green;
		B = blue;
		A = alpha;
	}

	this(ubyte red, ubyte green, ubyte blue)
	{
		this(red,green,blue,255);
	}

	union
	{
		uint m_RGBA;
		struct
		{
			ubyte m_Red;
			ubyte m_Green;
			ubyte m_Blue;
			ubyte m_Alpha;
		}
	}

	public string toString()
	{
		import std.conv;
		return "Color(" ~ R.to!string ~ "," ~ G.to!string  ~ "," ~ B.to!string  ~ "," ~ A.to!string  ~ ")";
	}

	public alias R = m_Red;
	public alias Red = m_Red;

	public alias G = m_Green;
	public alias Green = m_Green;

	public alias B = m_Blue;
	public alias Blue = m_Blue;

	public alias A = m_Alpha;
	public alias Alpha = m_Alpha;

	public alias RGBA = m_RGBA;

}

public Color alphaBlend(Color fg, Color bg)
{
	Color rtn;
    uint alpha = fg.A + 1;
    uint inv_alpha = 256 - fg.A;
    rtn.R = cast(ubyte)((alpha * fg.R + inv_alpha * bg.R) >> 8);
	rtn.G = cast(ubyte)((alpha * fg.G + inv_alpha * bg.G) >> 8);
	rtn.B = cast(ubyte)((alpha * fg.B + inv_alpha * bg.B) >> 8);
	rtn.A = 255;
	return rtn;
}

vec4 to(T: vec4)(Color c)
{
	return vec4(c.R, c.G, c.B, c.A);
}

Color to(T: Color)(vec4 c)
{
	foreach(ref float f; c.m_data)
	{
		if(f > 255) f = 255;
		if(f < 0) f = 0;
	}
	return Color(cast(ubyte)c.x, cast(ubyte)c.y, cast(ubyte)c.z, cast(ubyte)c.w);
}