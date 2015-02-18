module resources.softwareShader.shadowMapShader;

import graphics.image;
import graphics.color;
import math.matrix;

// Shadow mapped shader
struct shadowVertShader
{
	mat4 mvp;
	mat4 light_mvp;
	shadowShaderOut opCall(vec3 pos)
	{
		shadowShaderOut rtn;
		
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		rtn.pos = mvp*p;
		
		// calc shadow map lookup values
		rtn.shadow = light_mvp*p;
		
		return rtn;
	}
}

struct shadowPixelShader
{
	import graphics.frameBuffer;
	FrameBuffer tex;
	Image tex2;
	float epsilon;
	Color opCall(shadowShaderOut vout)
	{
		vout.shadow = vout.shadow / vout.shadow.w;
		if(vout.shadow.z > tex.depthLookupNearest(vout.shadow.xy)-epsilon) 
		{
			return tex2.textureLookupNearest((vout.shadow.xy + vec2(1,1))/2.0f);
		}
		else return Color(0, 0,0);
	}
}

struct shadowShaderOut
{
	vec4 pos;
	vec4 shadow;
}
