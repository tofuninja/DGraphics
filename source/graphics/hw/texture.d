module graphics.hw.texture;

struct Texture
{
	import derelict.opengl3.gl3;
	import graphics.Image;

	public GLuint id = 0;

	// TODO: Support other texture types
	public GLenum textureType = GL_TEXTURE_2D;

	public this(Image img)
	{
		setImage(img);
	}

	/**
	 * Sets the texture image
	 */
	public void setImage(Image img)
	{
		import util.debugger;
		import std.stdio;
		if(id == 0)
		{
			glGenTextures(1, &id);
		}

		glBindTexture(GL_TEXTURE_2D, id);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img.Width, img.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, img.Data.ptr);
		glGenerateMipmap(GL_TEXTURE_2D);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glBindTexture(GL_TEXTURE_2D, 0);
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
	}
}




