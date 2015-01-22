module graphics.hw.texture;

public enum TextureType
{
	RGBA,
	Depth,
}

struct Texture
{
	import derelict.opengl3.gl3;
	import graphics.image;

	public GLuint id = 0;
	public int width = 0;
	public int height = 0;

	// TODO: Support other texture types
	public TextureType textureType;
	public GLenum oglTextureType;
	public GLenum partArangment;
	public GLenum partType;
	public GLenum min;
	public GLenum mag;

	public this(Image img)
	{
		create(img);
	}

	public this(int w, int h, TextureType type = TextureType.RGBA)
	{
		create(w, h, type);
	}

	/**
	 * Sets the texture image
	 */
	public void create(Image img)
	{
		create(img.Width, img.Height, img.Data.ptr, TextureType.RGBA);
	}

	/**
	 * Creates an empty texture
	 */
	public void create(int w, int h, TextureType type)
	{
		create(w,h,null, type);
	}


	private void create(int w, int h, void* p, TextureType type)
	{
		import util.debugger;
		import std.stdio;

		textureType = type;

		destroy();
		glGenTextures(1, &id);

		width = w;
		height = h;

		bool genMip = false;

		if(type == TextureType.RGBA)
		{
			oglTextureType = GL_TEXTURE_2D;
			partArangment = GL_RGBA;
			partType = GL_UNSIGNED_BYTE;
			mag = GL_LINEAR;
			min = GL_LINEAR_MIPMAP_LINEAR;
			genMip = true;

		}
		else if(type == TextureType.Depth)
		{
			oglTextureType = GL_TEXTURE_2D;
			partArangment = GL_RED;
			partType = GL_FLOAT;
			mag = GL_LINEAR;
			min = GL_LINEAR;
		}


		glBindTexture(oglTextureType, id);
		glTexImage2D(oglTextureType, 0, partArangment, w, h, 0, partArangment, partType, p);
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




