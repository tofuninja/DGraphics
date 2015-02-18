module resources.softwareShader.texturedShader;

import graphics.image;
import graphics.color;
import math.matrix;

// Textured Shader
struct texVertShader
{
	mat4 mvp;
	texShaderOut opCall(vec3 pos, vec2 uv)
	{
		texShaderOut rtn;
		
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		rtn.pos = mvp*p;
		
		rtn.texCord = uv;
		
		return rtn;
	}
}

struct texPixelShader
{
	Image tex;
	Color opCall(texShaderOut vout)
	{
		//if(useMirror.value) vout.texCord = uvMirror(vout.texCord);
		
		//if(!useBilin.value) return textureLookupNearest(tex, vout.texCord);
		//else 
		return textureLookupBilinear(tex, vout.texCord);
	}
}

struct texShaderOut
{
	vec4 pos;
	vec2 texCord;
}