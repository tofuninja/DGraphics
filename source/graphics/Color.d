module graphics.Color;

import std.traits;
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

	/// Scalar multiplication op
	auto opBinary(string op : "*", T2)(T2 rhs) if(isScalarType!T2)
	{	
		T2 dR = R*rhs;
		T2 dG = G*rhs;
		T2 dB = B*rhs;
		T2 dA = A*rhs;

		if(dR < 0) dR = 0;
		if(dG < 0) dG = 0;
		if(dB < 0) dB = 0;
		if(dA < 0) dA = 0;

		if(dR > 255) dR = 255;
		if(dG > 255) dG = 255;
		if(dB > 255) dB = 255;
		if(dA > 255) dA = 255;

		return Color(cast(ubyte)(dR),cast(ubyte)(dG),cast(ubyte)(dB),cast(ubyte)(dA));
	} 

	/// Scalar divide op
	auto opBinary(string op : "/", T2)(T2 rhs) if(isScalarType!T2)
	{	
		return this*(1/rhs);
	} 

	/// add op
	auto opBinary(string op : "+")(Color x)
	{	
		int dR = R+x.R;
		int dG = G+x.G;
		int dB = B+x.B;
		int dA = A+x.A;
		
		if(dR < 0) dR = 0;
		if(dG < 0) dG = 0;
		if(dB < 0) dB = 0;
		if(dA < 0) dA = 0;
		
		if(dR > 255) dR = 255;
		if(dG > 255) dG = 255;
		if(dB > 255) dB = 255;
		if(dA > 255) dA = 255;
		return Color(cast(ubyte)(dR),cast(ubyte)(dG),cast(ubyte)(dB),cast(ubyte)(dA));
	} 
}

public Color alphaBlend(Color fg, Color bg)
{
	// Todo This is not correct, needs fixing, seems like this keeps happending, I will use something for a while and then suddenly relize it is not correct... 
	Color rtn;
	if(fg.A == 255) return fg;
    uint alpha = fg.A + 1;
    uint inv_alpha = 256 - fg.A;
    rtn.R = cast(ubyte)((alpha * fg.R + inv_alpha * bg.R) >> 8); // For one, these dont take into account the Alpha of the bg
	rtn.G = cast(ubyte)((alpha * fg.G + inv_alpha * bg.G) >> 8); // Shit pile of badness 
	rtn.B = cast(ubyte)((alpha * fg.B + inv_alpha * bg.B) >> 8);
	float alphaB = bg.A / 255.0f;
	float alphaA = fg.A / 255.0f;
	rtn.A = cast(ubyte)((alphaB + (1.0 - alphaB) * alphaA)*255.0f); // For two, this might not be corect, though it prob is, could be made to be faster
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

Color to(T: Color)(vec3 c)
{
	foreach(ref float f; c.m_data)
	{
		if(f > 255) f = 255;
		if(f < 0) f = 0;
	}
	return Color(cast(ubyte)c.x, cast(ubyte)c.y, cast(ubyte)c.z, 255);
}

Color perpInterp(Color A, Color B, Color C, vec3 uvw, vec3 depth)
{
	vec4 a = A.to!vec4;
	vec4 b = B.to!vec4;
	vec4 c = C.to!vec4;
	import std.stdio;

	// Perspective corect
	auto tmp = (a*uvw.x)/depth.x + (b*uvw.y)/depth.y + (c*uvw.z)/depth.z;
	auto denom = (uvw.x/depth.x) + (uvw.y/depth.y) + (uvw.z/depth.z);
	return (tmp / denom).to!Color;
}