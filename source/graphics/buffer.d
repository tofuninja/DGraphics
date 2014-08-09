module graphics.buffer;

import std.traits;
import derelict.opengl3.gl3;

/**
 * Describes the usage pattern of a buffer
 */
enum bufferUsage
{
	streamDraw = GL_STREAM_DRAW,
	streamCopy = GL_STREAM_COPY,
	streamRead = GL_STREAM_READ,
	staticDraw = GL_STATIC_DRAW,
	staticCopy = GL_STATIC_COPY,
	staticRead = GL_STATIC_READ,
	dynamicDraw = GL_DYNAMIC_DRAW,
	dynamicCopy = GL_DYNAMIC_COPY,
	dynamicRead = GL_DYNAMIC_READ
}


/**
 * Stores vertex data for opengl
 * T is they type of vertex associated with the buffer
 * T must be a struct
 */
struct vertexBuffer(T)
{
	static assert(is(T == struct), "T must be a struct");
	private bool created = false;
	private GLuint id = 0;
	private int size = 0;

	/**
	 * Sets the contents of the buffer as well as the buffer useage
	 * If the buffer already had data in it, the data is replaced
	 */
	public this(T[] data, bufferUsage usage = bufferUsage.staticDraw)
	{
		setData(data, usage);
	}

	public ~this()
	{
		deleteBuffer();
	}

	/**
	 * Sets the contents of the buffer as well as the buffer useage
	 * If the buffer already had data in it, the data is replaced
	 */
	public void setData(T[] data, bufferUsage usage = bufferUsage.staticDraw)
	{
		if(created == false)
		{
			glGenBuffers(1,&id);
			created = true;
		}

		size = data.length;
		glBindBuffer(GL_ARRAY_BUFFER, id);
		glBufferData(GL_ARRAY_BUFFER, data.sizeof, data.ptr, usage);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	/**
	 * Replaces a subsection if the buffer with data
	 * Offset indicates the location in the buffer to begin the replacement
	 * Offset is defined in T units
	 */
	public void setSubData(T[] data, int offset = 0)
	{
		assert(created, "Can not setSubData on uninitialized buffer");
		assert(data.length + offset <= size && offset >= 0, "Bounds of buffer exceeded");
		glBindBuffer(GL_ARRAY_BUFFER, id);
		glBufferSubData(GL_ARRAY_BUFFER, offset*T.sizeof, data.sizeof, data.ptr);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	/**
	 * Reset the buffer to an uninitialized state deleteing the buffered data at the same time
	 */
	public void deleteBuffer()
	{
		if(created)
		{
			glDeleteBuffers(1,&id);
		}

		created = false;
		id = 0;
		size = 0;
	}

	/**
	 * Size of the buffer in T units
	 */
	@property public int bufferSize()
	{
		return size;
	}

	/**
	 * OpenGL Buffer ID
	 */
	@property public GLuint bufferID()
	{
		return id;
	}

	/**
	 * Returns true if the buffer can be used
	 */
	@property public bool valid()
	{
		return created;
	}
}