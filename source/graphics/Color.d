module graphics.Color;

import std.conv;

struct Color
{
	this(uint bgra)
	{
		BGRA = bgra;
	}

	this(int red, int green, int blue, int alpha)
	{
		R = cast(ubyte) red;
		G = cast(ubyte) green;
		B = cast(ubyte) blue;
		A = cast(ubyte) alpha;
	}

	this(int red, int green, int blue)
	{
		this(red,green,blue,255);
	}

	union
	{
		uint m_BGRA;
		struct
		{
			ubyte m_Blue;
			ubyte m_Green;
			ubyte m_Red;
			ubyte m_Alpha;
		}
	}

	public string toString()
	{
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
	public alias BGRA = m_BGRA;
}

/*
public Color alphaBlend(Color A, Color B)
{

}
*/