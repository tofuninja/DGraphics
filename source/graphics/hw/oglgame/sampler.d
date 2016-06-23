module graphics.hw.oglgame.sampler;

import graphics.hw.enums;
import graphics.hw.structs;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.opengl3.gl3;

public struct samplerRef
{
	// ref type
	package GLuint id = 0;
}

public samplerRef createSampler(hwSamplerCreateInfo info) @nogc
{
	import graphics.color;
	import math.matrix : vec4;
	samplerRef r;
	
	glGenSamplers(1, &r.id);
	glSamplerParameteri(r.id, GL_TEXTURE_MIN_FILTER, oglgFilter(info.minFilter, info.mipFilter));
	glSamplerParameteri(r.id, GL_TEXTURE_MAG_FILTER, oglgFilter(info.magFilter, hwMipmapFilterMode.none));
	glSamplerParameteri(r.id, GL_TEXTURE_WRAP_S, oglgWrap(info.wrap_x));
	glSamplerParameteri(r.id, GL_TEXTURE_WRAP_T, oglgWrap(info.wrap_y));
	glSamplerParameteri(r.id, GL_TEXTURE_WRAP_R, oglgWrap(info.wrap_z));
	vec4 c = info.boarderColor.to!vec4();
	glSamplerParameterfv(r.id, GL_TEXTURE_BORDER_COLOR, c.data.ptr);
	oglgCheckError();
	return r;
}

public void destroySampler(ref samplerRef obj) @nogc
{
	glDeleteSamplers(1, &obj.id);
	obj.id = 0;
	oglgCheckError();
}

/**
 * Convert a filter mode to the ogl filter mode enum
 */
package GLenum oglgFilter(hwFilterMode mode, hwMipmapFilterMode mip) @nogc
{
	switch(mode) {
		case hwFilterMode.nearest:
		{
			switch(mip) {
				case hwMipmapFilterMode.none: 	return GL_NEAREST;
				case hwMipmapFilterMode.nearest: 	return GL_NEAREST_MIPMAP_NEAREST;
				case hwMipmapFilterMode.linear: 	return GL_NEAREST_MIPMAP_LINEAR;
				default: assert(false, "Invalid filter mode");
			}
		}
		case hwFilterMode.linear:
		{
			switch(mip) {
				case hwMipmapFilterMode.none: 	return GL_LINEAR;
				case hwMipmapFilterMode.nearest: 	return GL_LINEAR_MIPMAP_NEAREST;
				case hwMipmapFilterMode.linear: 	return GL_LINEAR_MIPMAP_LINEAR;
				default: assert(false, "Invalid filter mode");
			}
		}
		default: assert(false, "Invalid filter mode");
	}
}

/**
 * Convert a wrap mode to the ogl wrap mode enum
 */
package GLenum oglgWrap(hwWrapMode w) @nogc
{
	switch(w) {
		case hwWrapMode.repeat: 		return GL_REPEAT;
		case hwWrapMode.mirrorRepeat: return GL_MIRRORED_REPEAT;
		case hwWrapMode.edge: 		return GL_CLAMP_TO_EDGE;
		case hwWrapMode.edgeBlend: 	return GL_CLAMP_TO_BORDER;
		default: assert(false, "Invalid wrap mode");
	}
}