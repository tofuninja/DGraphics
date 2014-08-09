module graphics.Texture;

struct Texture
{
	import derelict.opengl3.gl3;
	import graphics.Image;

	private GLuint id = 0;
	private bool created = false;


	public this(Image img)
	{
		setImage(img);
	}

	public ~this()
	{
		deleteTexture();
	}

	/**
	 * Sets the texture image
	 */
	public void setImage(Image img)
	{
		if(created == false)
		{
			glGenTextures(1, &id);
			created = true;
		}

		glBindTexture(GL_TEXTURE_2D, id);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img.Width, img.Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, img.Data.ptr);
		glGenerateMipmap(GL_TEXTURE_2D);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	/**
	 * Deletes the texture data
	 */
	public void deleteTexture()
	{
		if(created)
		{
			glDeleteTextures(1, &id);
		}
		id = 0;
		created = false;
	}

	/**
	 * Get opnegl texture id
	 */
	@property public GLuint textureID()
	{
		return id;
	}

	/**
	 * Returns true if the texture can be used
	 */
	@property public bool valid()
	{
		return created;
	}
}