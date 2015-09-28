module resources.softwareShader.basicShader;

import graphics.image;
import graphics.color;
import math.matrix;

// Basic Shader
struct basicVertexShader
{
	mat4 mvp;
	vertOut opCall(vec3 pos)
	{
		vertOut rtn;
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		rtn.pos = mvp*p;
		return rtn;
	}
}

struct vertOut
{
	vec4 pos;
}

struct basicPixelShader
{
	Color opCall(vertOut vout)
	{
		return ((vout.pos.zzz + vec3(1,1,1)) * 255/2).to!Color;
		//return Color(0,0,0);
	}
}
