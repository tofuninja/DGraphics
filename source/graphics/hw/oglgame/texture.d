module graphics.hw.oglgame.texture;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;
import math.matrix;

public struct textureRef(textureType T = textureType.tex2D) 
{
	// ref type
	debug package textureCreateInfo!(T) 	info; // use for correctness checking
	package enum textureType 				type 		= T;
	package GLuint 							id			= 0;
	public uvec3 							size		= uvec3(0,0,0);
	
	public void subData(textureSubDataInfo info) @nogc
	{
		oglgTextureSubData!T(this,info);
	}
	
	public void genMipmaps() @nogc
	{
		assert(id != 0);
		glGenerateTextureMipmap(id);
	}
	
}

public auto createTexture(textureType T)(textureCreateInfo!(T) info) @nogc
{
	if(info.renderBuffer) return oglgCreateRenderBuffer(info);
	
	// Create immutable texture storage
	textureRef!(T) r;
	GLenum target;
	GLenum format;
	int dim;
	r.size = info.size;
	oglgTexTypeToGLenum(info.type, target, dim);
	oglgColorFormatToGLenum(info.format, format);
	glCreateTextures(target, 1, &(r.id));
	
	switch(dim)
	{
		case 1: 
			glTextureStorage1D(r.id, info.levels, format, info.size.x);
			break;
		case 2:
			glTextureStorage2D(r.id, info.levels, format, info.size.x, info.size.y);
			break;
		case 3:
			glTextureStorage3D(r.id, info.levels, format, info.size.x, info.size.y, info.size.z);
			break;
		default: assert(false, "Wut? How did I get here?");
	}
	debug r.info = info;
	return r;
}

public auto createTexture(textureType T)(textureViewCreateInfo!(T) info) @nogc
	if(T == textureType.tex1DArray || T == textureType.tex2DArray || T == textureType.texCube || T == textureType.texCubeArray)
{
	static assert(T != textureType.texCubeArray, "Not fully implimented yet, just because I dont really know how it works, if I need it later then I will fix this");
	assert(false, "really dont know if this works");
	// Will check if this works when I first use it
	// TODO check if this works
	// TODO check if cube map array works, not sure if index needs to be mul by 6 as well... 
	
	debug assert(glIsTexture(info.soruce.id) == GL_TRUE, "Can not make view from render buffer");
	
	enum textureType viewType = oglgTextureTypeView(T);
	auto r = textureRef!(viewType, F);
	r.size = info.source.size;
	GLenum target;
	int dim;
	int numLevels;
	GLenum format;
	static if(viewType == textureType.texCube) enum numLayers = 6;
	else enum numLayers = 1;
	
	// TODO check if GL_TEXTURE_VIEW_NUM_LEVELS is right, there were a few others that look like they could have fit... 
	glGetTextureParameteriv(info.source.id, GL_TEXTURE_VIEW_NUM_LEVELS, &numLevels);
	
	oglgTexTypeToGLenum(viewType, target, dim);
	oglgColorFormatToGLenum(info.format, format);
	glCreateTextures(target, 1, &(r.id));
	glTextureView(r.id, target, info.source.id, info.source.glformat, 0, numlevels, info.index, numlayers);
	
	debug oglgCheckGlError();
	return r;
}

public void destroyTexture(textureType T)(ref textureRef!T obj) @nogc
{
	if(glIsTexture(obj.id) == GL_TRUE)
		glDeleteTextures(1, &obj.id);
	else 
		glDeleteRenderbuffers(1, &obj.id);
	
	obj.id = 0;
}




/**
 * Convert a texture type to the ogl texture target and the dimentionality 
 */
package void oglgTexTypeToGLenum(textureType type, out GLenum target, out int dim) @nogc
{
	switch(type)
	{
		case textureType.tex1D: 
			target = GL_TEXTURE_1D; 
			dim = 1;
			break;
		case textureType.tex1DArray: 
			target = GL_TEXTURE_1D_ARRAY;
			dim = 2;
			break;
		case textureType.tex2D: 
			target = GL_TEXTURE_2D; 
			dim = 2;
			break;
		case textureType.tex2DArray: 
			target = GL_TEXTURE_2D_ARRAY; 
			dim = 3;
			break;
		case textureType.tex3D: 
			target = GL_TEXTURE_3D; 
			dim = 3;
			break;
		case textureType.texCube: 
			target = GL_TEXTURE_CUBE_MAP;
			dim = 2;
			break;
		case textureType.texCubeArray: 
			target = GL_TEXTURE_CUBE_MAP_ARRAY;
			dim = 3;
			break;
		default: assert(false, "Invalid texture type");
	}
}

/**
 * Convert a color format to the ogl image format enum
 * 
 * Returns the byte size of the format
 */
package uint oglgColorFormatToGLenum(colorFormat color, out GLenum format) @nogc
{
	switch(color)
	{
		case colorFormat.R_u8:
			format = GL_R8;
			return 1;
		case colorFormat.RG_u8:
			format = GL_RG8;
			return 2;
		case colorFormat.RGB_u8:
			format = GL_RGB8;
			return 3;
		case colorFormat.RGBA_u8:
			format = GL_RGBA8;
			return 4;
		case colorFormat.R_f32:
			format = GL_R32F;
			return 4;
		case colorFormat.RG_f32:
			format = GL_RG32F;
			return 8;
		case colorFormat.RGB_f32:
			format = GL_RGB32F;
			return 12;
		case colorFormat.RGBA_f32:
			format = GL_RGBA32F;
			return 16;
		case colorFormat.Depth_24:
			format = GL_DEPTH_COMPONENT24;
			return 3;
		case colorFormat.Depth_32:
			format = GL_DEPTH_COMPONENT32F;
			return 4;
		case colorFormat.Stencil_8:
			format = GL_STENCIL_INDEX8;
			return 1;
		case colorFormat.Depth_24_Stencil_8:
			format = GL_DEPTH24_STENCIL8;
			return 4;
		case colorFormat.Depth_32_Stencil_8:
			format = GL_DEPTH32F_STENCIL8;
			return 5;
		default: assert(false, "Invalid Color Format");
	}
}

/**
 * Degrade a texture type to its view type
 */
package textureType oglgTextureTypeView(textureType t) @nogc
{
	switch(t)
	{
		case textureType.texCube: 		return textureType.tex2D;
		case textureType.tex1DArray: 	return textureType.tex1D;
		case textureType.tex2DArray: 	return textureType.tex2D;
		case textureType.texCubeArray:	return textureType.texCube;
		case textureType.tex1D: 
		case textureType.tex2D: 
		case textureType.tex3D:
		default: assert(false, "Invalid texture source type");
	}
}

/**
 * Create a render buffer
 */
package auto oglgCreateRenderBuffer(T)(T info) @nogc
{
	assert(info.levels == 1, "Render buffer can only have one(1) level");
	assert(info.type == textureType.tex2D, "Render buffer type can only be tex2D");
	
	// Create renderBuffer
	textureRef!(T.type) r;
	GLenum format;
	oglgColorFormatToGLenum(info.format, format);
	
	glCreateRenderbuffers(1, &r.id);
	glNamedRenderbufferStorage(r.id, format, info.size.x, info.size.y);
	
	debug r.info = info;
	return r;
}

/*
 * Convert a color format to its ogl format and type enums
 */
package void oglgColorFormatToSubDataFormat(colorFormat c, out GLenum format, out GLenum type) @nogc
{
	with(colorFormat)
	{
		switch(c)
		{
			case R_u8: 					format = GL_RED; 				type = GL_UNSIGNED_BYTE; 	return;
			case RG_u8:					format = GL_RG; 				type = GL_UNSIGNED_BYTE; 	return;
			case RGB_u8:				format = GL_RGB; 				type = GL_UNSIGNED_BYTE; 	return;
			case RGBA_u8:				format = GL_RGBA; 				type = GL_UNSIGNED_BYTE; 	return;
			case R_f32:					format = GL_RED; 				type = GL_FLOAT; 			return;
			case RG_f32:				format = GL_RG; 				type = GL_FLOAT; 			return;
			case RGB_f32:				format = GL_RGB; 				type = GL_FLOAT; 			return;
			case RGBA_f32:				format = GL_RGBA; 				type = GL_FLOAT; 			return;
			case Depth_32:				format = GL_DEPTH_COMPONENT; 	type = GL_FLOAT; 			return;
			case Stencil_8:				format = GL_STENCIL_INDEX; 		type = GL_UNSIGNED_BYTE; 	return;
			case Depth_24:
			case Depth_24_Stencil_8:
			case Depth_32_Stencil_8:
			default: assert(false, "Invalid format type");
		}
	}
}

package void oglgTextureSubData(textureType T)(textureRef!T obj, textureSubDataInfo info) @nogc
{
	debug
	{
		// check if input data can fit into texture
		GLenum _temp;
		uint formatSize = oglgColorFormatToGLenum(obj.info.format, _temp);
		static if(T == textureType.tex1D)
		{
			assert(formatSize*info.size.x == info.data.length, 		"Texture sub data bounds does not match data size");
			assert(info.level < obj.info.levels,					"Texture level out of bounds");
			assert(info.offset.x + info.size.x  <= obj.info.size.x, "Texture sub data out of bounds");
			assert(!obj.info.renderBuffer,							"Can't set data on render buffer");
		}
		else static if(T == textureType.tex2D)
		{
			assert(formatSize*info.size.x*info.size.y == info.data.length, 	"Texture sub data bounds does not match data size");
			assert(info.level < obj.info.levels,							"Texture level out of bounds");
			assert(info.offset.x + info.size.x  <= obj.info.size.x, 		"Texture sub data out of bounds");
			assert(info.offset.y + info.size.y  <= obj.info.size.y, 		"Texture sub data out of bounds");
			assert(!obj.info.renderBuffer,									"Can't set data on render buffer");
		}
		else static if(T == textureType.tex3D)
		{
			assert(formatSize*info.size.x*info.size.y*info.size.z == info.data.length, 	"Texture sub data bounds does not match data size");
			assert(info.level < obj.info.levels,										"Texture level out of bounds");
			assert(info.offset.x + info.size.x  <= obj.info.size.x, 					"Texture sub data out of bounds");
			assert(info.offset.y + info.size.y  <= obj.info.size.y, 					"Texture sub data out of bounds");
			assert(info.offset.z + info.size.z  <= obj.info.size.z, 					"Texture sub data out of bounds");
			assert(!obj.info.renderBuffer,												"Can't set data on render buffer");
		}
		else
		{
			static assert(false, "Wut, how did I get here?");
		}
	}
	
	GLenum format, type;
	oglgColorFormatToSubDataFormat(info.format, format, type);
	
	static if(T == textureType.tex1D)
		glTextureSubImage1D(obj.id, info.level, info.offset.x, info.size.x, format, type, info.data.ptr);
	else static if(T == textureType.tex2D)
		glTextureSubImage2D(obj.id, info.level, info.offset.x, info.offset.y, info.size.x, info.size.y, format, type, info.data.ptr);
	else static if(T == textureType.tex3D)
		glTextureSubImage3D(obj.id, info.level, info.offset.x, info.offset.y, info.offset.z, info.size.x, info.size.y, info.size.z, format, type, info.data.ptr);
}
