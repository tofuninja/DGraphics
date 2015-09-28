module graphics.hw.texture;

import graphics.image;

// TODO Texture needs an overhul 
// Make it wayyyyyy more generic, dont type it to any thing, just take void[] and just make sure the size is right

// TODO remove shity formats 
public enum TextureType
{
	RGBA,
	RGBA_FLOAT,
	RED_FLOAT,
	Depth,
	Cube,
}

// TODO this texture setup is kinad jank.... could do better 
class Texture
{
	import derelict.opengl3.gl3;
	import math.matrix;
	import graphics.color;

	public GLuint id = 0;
	public int width = 0;
	public int height = 0;

	// TODO: Support other texture types
	public TextureType textureType;
	public GLenum oglTextureType;
	public GLenum partArangment;
	public GLenum internalFormat;
	public GLenum partType;
	public GLenum min;
	public GLenum mag;

	public this(Image img, TextureType type = TextureType.RGBA, bool genMip = true)
	{
		create(img, type, genMip);
	}

	public this(int w, int h, TextureType type = TextureType.RGBA)
	{
		create(w, h, type);
	}

	public this(int w, int h, void* img, TextureType type = TextureType.RGBA, bool genMip = true)
	{
		create(w, h, img, type,genMip);
	}

	/**
	 * Sets the texture image
	 */
	public void create(Image img, TextureType type = TextureType.RGBA, bool genMip = true)
	{
		if(type != TextureType.RGBA && type != TextureType.Cube) 
			throw new Exception("Unsupported texture type, only RGBA, or Cube are supported when createing a textue from an Image");
		create(img.Width, img.Height, img.Data.ptr, type, genMip);
	}

	/**
	 * Creates an empty texture
	 */
	public void create(int w, int h, TextureType type)
	{
		create(w,h,null, type, false);
	}


	public void create(int w, int h, void* img, TextureType type, bool genMip)
	{
		import util.debugger;
		import std.stdio;

		textureType = type;

		destroy();
		glGenTextures(1, &id);

		width = w;
		height = h;

		if(type == TextureType.RGBA)
		{
			oglTextureType = GL_TEXTURE_2D;
			partArangment = GL_RGBA;
			internalFormat = partArangment;
			partType = GL_UNSIGNED_BYTE;
			mag = GL_LINEAR;
			min = GL_LINEAR_MIPMAP_LINEAR;
		}
		else if(type == TextureType.RGBA_FLOAT)
		{
			oglTextureType = GL_TEXTURE_2D;
			partArangment = GL_RGBA;
			internalFormat = partArangment;
			partType = GL_FLOAT;
			mag = GL_LINEAR;
			min = GL_LINEAR_MIPMAP_LINEAR;

		}
		else if(type == TextureType.RED_FLOAT)
		{
			oglTextureType = GL_TEXTURE_2D;
			partArangment = GL_RED;
			internalFormat = GL_R32F;
			partType = GL_FLOAT;
			mag = GL_LINEAR;
			min = GL_LINEAR;
			
		}
		else if(type == TextureType.Depth)
		{
			oglTextureType = GL_TEXTURE_2D;
			partArangment = GL_DEPTH_COMPONENT;
			internalFormat = partArangment;
			partType = GL_FLOAT;
			mag = GL_LINEAR;
			min = GL_LINEAR;
		}
		else if(type == TextureType.Cube)
		{
			/*
			oglTextureType = GL_TEXTURE_CUBE_MAP;
			partArangment = GL_RGBA;
			partType = GL_UNSIGNED_BYTE;
			mag = GL_LINEAR;
			min = GL_LINEAR_MIPMAP_LINEAR;

			if(genMip == false) min = GL_LINEAR;


			w /= 3;
			h = w;
			width = w;
			height = h;

			if(img.Height != h*4) throw new Exception("ERROR: cube map can not be created from input image");
			Image sub = new Image(w,h);

			glBindTexture(oglTextureType, id);

			glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, partArangment, w, h, 0, partArangment, partType, getImageSubSection(w*0,h*1,img,sub).Data.ptr);
			glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, partArangment, w, h, 0, partArangment, partType, getImageSubSection(w*2,h*1,img,sub).Data.ptr);
			glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, partArangment, w, h, 0, partArangment, partType, getImageSubSection(w*1,h*2,img,sub).Data.ptr);
			glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, partArangment, w, h, 0, partArangment, partType, getImageSubSection(w*1,h*0,img,sub).Data.ptr);
			glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, partArangment, w, h, 0, partArangment, partType, getImageSubSection(w*1,h*3,img,sub).Data.ptr);
			glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, partArangment, w, h, 0, partArangment, partType, getImageSubSection(w*1,h*1,img,sub).Data.ptr);

			if(genMip) glGenerateMipmap(oglTextureType);
			glTexParameteri (GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri (GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
			glTexParameteri (GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri (GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			glBindTexture(oglTextureType, 0);

			return; // Cube map does its own data sending
			*/
			throw new Exception("Cube map not implimented"); // was done badly, need to fix for the future
		}


		if(img is null) genMip = false; // no mip maps to generate... 
		if(genMip == false) min = GL_LINEAR;

		glBindTexture(oglTextureType, id);
		glTexImage2D(oglTextureType, 0, internalFormat, w, h, 0, partArangment, partType, img);
		if(genMip) glGenerateMipmap(oglTextureType);
		glTexParameteri(oglTextureType, GL_TEXTURE_MAG_FILTER, mag);
		glTexParameteri(oglTextureType, GL_TEXTURE_MIN_FILTER, min);
		glBindTexture(oglTextureType, 0);

	}


	



	/**
	 * Deletes the texture data
	 */
	public void destroy()
	{
		if(id != 0)
		{
			glDeleteTextures(1, &id);
		}
		id = 0;
		width = 0;
		height = 0;
	}
}


private Image getImageSubSection(int x, int y, Image img, Image store)
{
	if(img is null) return store;
	for(int i = 0; i < store.Width; i++)
	{
		for(int j = 0; j < store.Height; j++)
		{
			store[i, j] = img[x+i, y+j];
		}
	}
	return store;
}