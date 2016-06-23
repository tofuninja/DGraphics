module graphics.hw.oglgame.texture;

import graphics.hw.enums;
import graphics.hw.structs;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.opengl3.gl3;
import math.matrix;

public struct textureRef(hwTextureType T = hwTextureType.tex2D) {
	// ref type
	debug package hwTextureCreateInfo!(T) 	info; // use for correctness checking
	package enum hwTextureType 				type 		= T;
	package GLuint 							id			= 0;
	public uvec3 							size		= uvec3(0,0,0);
	public bool 							isRenderBuffer = false;
	
	public void subData(hwTextureSubDataInfo info) @nogc
	{
		oglgTextureSubData!T(this,info);
	}
	
	public void genMipmaps() @nogc
	{
		assert(id != 0);
		glGenerateTextureMipmap(id);
		oglgCheckError();
	}
	
}

public auto createTexture(hwTextureType T)(hwTextureCreateInfo!(T) info) @nogc
{
	static if(T == hwTextureType.tex2D) {
		if(info.renderBuffer) return oglgCreateRenderBuffer(info);
	} else {
		assert(info.renderBuffer == false);
	}
	
	// Create immutable texture storage
	textureRef!(T) r;
	GLenum target;
	GLenum format;
	int dim;
	r.size = info.size;
	oglgTexTypeToGLenum(info.type, target, dim);
	oglgColorFormatToGLenum(info.format, format);
	glCreateTextures(target, 1, &(r.id));

	switch(dim) {
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

	glTextureParameteri(r.id, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTextureParameteri(r.id, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	//if(info.format == hwColorFormat.Depth_24 || info.format == hwColorFormat.Depth_24_Stencil_8 || info.format == hwColorFormat.Depth_32 || info.format == hwColorFormat.Depth_32_Stencil_8) {
	//    if(info.compareDepth) {
	//        glTextureParameteri(r.id, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE);
	//    } else {
	//        glTextureParameteri(r.id, GL_TEXTURE_COMPARE_MODE, GL_NONE);
	//    }
	//}
	debug r.info = info;
	oglgCheckError();
	return r;
}

public auto createTexture(hwTextureType T)(hwTextureViewCreateInfo!(T) info) @nogc
	if(T == hwTextureType.tex1DArray || T == hwTextureType.tex2DArray || T == hwTextureType.texCube || T == hwTextureType.texCubeArray) {
	static assert(T != hwTextureType.texCubeArray, "Not fully implimented yet, just because I dont really know how it works, if I need it later then I will fix this");
	assert(false, "really dont know if this works");
	// Will check if this works when I first use it
	// TODO check if this works
	// TODO check if cube map array works, not sure if index needs to be mul by 6 as well... 
	
	debug assert(!info.source.isRenderBuffer, "Can not make view from render buffer");
	
	enum hwTextureType viewType = oglgTextureTypeView(T);
	auto r = textureRef!(viewType, F);
	r.size = info.source.size;
	GLenum target;
	int dim;
	int numLevels;
	GLenum format;
	static if(viewType == hwTextureType.texCube) enum numLayers = 6;
	else enum numLayers = 1;
	
	// TODO check if GL_TEXTURE_VIEW_NUM_LEVELS is right, there were a few others that look like they could have fit... 
	glGetTextureParameteriv(info.source.id, GL_TEXTURE_VIEW_NUM_LEVELS, &numLevels);
	
	oglgTexTypeToGLenum(viewType, target, dim);
	oglgColorFormatToGLenum(info.format, format);
	glCreateTextures(target, 1, &(r.id));
	glTextureView(r.id, target, info.source.id, info.source.glformat, 0, numlevels, info.index, numlayers);
	
	oglgCheckError();
	return r;
}

public void destroyTexture(hwTextureType T)(ref textureRef!T obj) @nogc
{
	if(!obj.isRenderBuffer)
		glDeleteTextures(1, &obj.id);
	else 
		glDeleteRenderbuffers(1, &obj.id);
	
	obj.id = 0;
	oglgCheckError();
}




/**
 * Convert a texture type to the ogl texture target and the dimentionality 
 */
package void oglgTexTypeToGLenum(hwTextureType type, out GLenum target, out int dim) @nogc
{
	switch(type) {
		case hwTextureType.tex1D: 
			target = GL_TEXTURE_1D; 
			dim = 1;
			break;
		case hwTextureType.tex1DArray: 
			target = GL_TEXTURE_1D_ARRAY;
			dim = 2;
			break;
		case hwTextureType.tex2D: 
			target = GL_TEXTURE_2D; 
			dim = 2;
			break;
		case hwTextureType.tex2DArray: 
			target = GL_TEXTURE_2D_ARRAY; 
			dim = 3;
			break;
		case hwTextureType.tex3D: 
			target = GL_TEXTURE_3D; 
			dim = 3;
			break;
		case hwTextureType.texCube: 
			target = GL_TEXTURE_CUBE_MAP;
			dim = 2;
			break;
		case hwTextureType.texCubeArray: 
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
package uint oglgColorFormatToGLenum(hwColorFormat color, out GLenum format) @nogc
{
	//switch(color)
	//{
	//    case hwColorFormat.R_n8:
	//        format = GL_R8;
	//        return 1;
	//    case hwColorFormat.RG_n8:
	//        format = GL_RG8;
	//        return 2;
	//    case hwColorFormat.RGB_n8:
	//        format = GL_RGB8;
	//        return 3;
	//    case hwColorFormat.RGBA_n8:
	//        format = GL_RGBA8;
	//        return 4;
	//    case hwColorFormat.R_f32:
	//        format = GL_R32F;
	//        return 4;
	//    case hwColorFormat.RG_f32:
	//        format = GL_RG32F;
	//        return 8;
	//    case hwColorFormat.RGB_f32:
	//        format = GL_RGB32F;
	//        return 12;
	//    case hwColorFormat.RGBA_f32:
	//        format = GL_RGBA32F;
	//        return 16;
	//    case hwColorFormat.Depth_24:
	//        format = GL_DEPTH_COMPONENT24;
	//        return 3;
	//    case hwColorFormat.Depth_32:
	//        format = GL_DEPTH_COMPONENT32F;
	//        return 4;
	//    case hwColorFormat.Stencil_8:
	//        format = GL_STENCIL_INDEX8;
	//        return 1;
	//    case hwColorFormat.Depth_24_Stencil_8:
	//        format = GL_DEPTH24_STENCIL8;
	//        return 4;
	//    case hwColorFormat.Depth_32_Stencil_8:
	//        format = GL_DEPTH32F_STENCIL8;
	//        return 5;
	//    default: assert(false, "Invalid Color Format");
	//}
	GLenum temp1, temp2;
	return oglgColorFormatInfo(color, format, temp1, temp2);
}

/**
 * Degrade a texture type to its view type
 */
package hwTextureType oglgTextureTypeView(hwTextureType t) @nogc
{
	switch(t) {
		case hwTextureType.texCube: 		return hwTextureType.tex2D;
		case hwTextureType.tex1DArray: 	return hwTextureType.tex1D;
		case hwTextureType.tex2DArray: 	return hwTextureType.tex2D;
		case hwTextureType.texCubeArray:	return hwTextureType.texCube;
		case hwTextureType.tex1D: 
		case hwTextureType.tex2D: 
		case hwTextureType.tex3D:
		default: assert(false, "Invalid texture source type");
	}
}

/**
 * Create a render buffer
 */
package auto oglgCreateRenderBuffer(T)(T info) @nogc
{
	assert(info.levels == 1, "Render buffer can only have one(1) level");
	assert(info.type == hwTextureType.tex2D, "Render buffer type can only be tex2D");
	
	// Create renderBuffer
	textureRef!(T.type) r;
	GLenum format;
	oglgColorFormatToGLenum(info.format, format);
	
	glCreateRenderbuffers(1, &r.id);
	glNamedRenderbufferStorage(r.id, format, info.size.x, info.size.y);
	r.isRenderBuffer = true;
	debug r.info = info;
	oglgCheckError();
	return r;
}

/*
 * Convert a color format to its ogl enums
 */
package uint oglgColorFormatInfo(hwColorFormat c, out GLenum format, out GLenum baseFormat, out GLenum type) @nogc
{
	with(hwColorFormat) {
		switch(c) {
			case R_n8: 					format = GL_R8; 				baseFormat = GL_RED;				type = GL_UNSIGNED_BYTE; 	return 1;
			case RG_n8:					format = GL_RG8; 				baseFormat = GL_RG;					type = GL_UNSIGNED_BYTE; 	return 2;
			case RGB_n8:				format = GL_RGB8; 				baseFormat = GL_RGB;				type = GL_UNSIGNED_BYTE; 	return 3;
			case RGBA_n8:				format = GL_RGBA8; 				baseFormat = GL_RGBA;				type = GL_UNSIGNED_BYTE; 	return 4;
			case R_u8: 					format = GL_R8UI; 				baseFormat = GL_RED;				type = GL_UNSIGNED_BYTE; 	return 1;
			case RG_u8:					format = GL_RG8UI; 				baseFormat = GL_RG;					type = GL_UNSIGNED_BYTE; 	return 2;
			case RGB_u8:				format = GL_RGB8UI; 			baseFormat = GL_RGB;				type = GL_UNSIGNED_BYTE; 	return 3;
			case RGBA_u8:				format = GL_RGBA8UI; 			baseFormat = GL_RGBA;				type = GL_UNSIGNED_BYTE; 	return 4;
			case R_f32:					format = GL_R32F; 				baseFormat = GL_RED;				type = GL_FLOAT; 			return 4;
			case RG_f32:				format = GL_RG32F; 				baseFormat = GL_RG;					type = GL_FLOAT; 			return 8;
			case RGB_f32:				format = GL_RGB32F; 			baseFormat = GL_RGB;				type = GL_FLOAT; 			return 16;
			case RGBA_f32:				format = GL_RGBA32F; 			baseFormat = GL_RGBA;				type = GL_FLOAT; 			return 32;
			case Stencil_8:				format = GL_STENCIL_INDEX; 		baseFormat = GL_STENCIL_INDEX;		type = GL_UNSIGNED_BYTE; 	return 1;
			case Depth_24:				format = GL_DEPTH_COMPONENT24; 	baseFormat = GL_DEPTH_COMPONENT;	type = GL_INVALID_ENUM; 	return 3;
			case Depth_32:				format = GL_DEPTH_COMPONENT32; 	baseFormat = GL_DEPTH_COMPONENT;	type = GL_FLOAT; 			return 4;
			case Depth_24_Stencil_8:	format = GL_DEPTH24_STENCIL8; 	baseFormat = GL_INVALID_ENUM;		type = GL_INVALID_ENUM; 	return 4;
			case Depth_32_Stencil_8:	format = GL_DEPTH32F_STENCIL8; 	baseFormat = GL_INVALID_ENUM;		type = GL_INVALID_ENUM; 	return 5;
			default: assert(false, "Invalid format type");
		}
	}
}

package void oglgTextureSubData(hwTextureType T)(textureRef!T obj, hwTextureSubDataInfo info) @nogc
{
	debug
	{
		// check if input data can fit into texture
		GLenum _temp;
		uint formatSize = oglgColorFormatToGLenum(obj.info.format, _temp);
		static if(T == hwTextureType.tex1D) {
			assert(formatSize*info.size.x == info.data.length, 		"Texture sub data bounds does not match data size");
			assert(info.level < obj.info.levels,					"Texture level out of bounds");
			assert(info.offset.x + info.size.x  <= obj.info.size.x, "Texture sub data out of bounds");
			assert(!obj.info.renderBuffer,							"Can't set data on render buffer");
		} else static if(T == hwTextureType.tex2D) {
			assert(formatSize*info.size.x*info.size.y == info.data.length, 	"Texture sub data bounds does not match data size");
			assert(info.level < obj.info.levels,							"Texture level out of bounds");
			assert(info.offset.x + info.size.x  <= obj.info.size.x, 		"Texture sub data out of bounds");
			assert(info.offset.y + info.size.y  <= obj.info.size.y, 		"Texture sub data out of bounds");
			assert(!obj.info.renderBuffer,									"Can't set data on render buffer");
		} else static if(T == hwTextureType.tex3D) {
			assert(formatSize*info.size.x*info.size.y*info.size.z == info.data.length, 	"Texture sub data bounds does not match data size");
			assert(info.level < obj.info.levels,										"Texture level out of bounds");
			assert(info.offset.x + info.size.x  <= obj.info.size.x, 					"Texture sub data out of bounds");
			assert(info.offset.y + info.size.y  <= obj.info.size.y, 					"Texture sub data out of bounds");
			assert(info.offset.z + info.size.z  <= obj.info.size.z, 					"Texture sub data out of bounds");
			assert(!obj.info.renderBuffer,												"Can't set data on render buffer");
		} else {
			static assert(false, "Wut, how did I get here?");
		}
	}
	
	GLenum format, baseFormat, type;
	oglgColorFormatInfo(info.format, format, baseFormat, type);
	assert(type != GL_INVALID_ENUM);
	assert(baseFormat != GL_INVALID_ENUM);
	
	static if(T == hwTextureType.tex1D)
		glTextureSubImage1D(obj.id, info.level, info.offset.x, info.size.x, baseFormat, type, info.data.ptr);
	else static if(T == hwTextureType.tex2D)
		glTextureSubImage2D(obj.id, info.level, info.offset.x, info.offset.y, info.size.x, info.size.y, baseFormat, type, info.data.ptr);
	else static if(T == hwTextureType.tex3D)
		glTextureSubImage3D(obj.id, info.level, info.offset.x, info.offset.y, info.offset.z, info.size.x, info.size.y, info.size.z, baseFormat, type, info.data.ptr);
	oglgCheckError();
}
