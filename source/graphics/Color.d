module graphics.Color;

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

/*
public Color alphaBlend(Color A, Color B)
{

}
*/