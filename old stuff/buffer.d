module graphics.hw.buffer;

import std.traits;
import derelict.opengl3.gl3;

/**
 * Describes the usage pattern of a buffer
 */
public enum BufferUsage
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


// TODO remove this dumb name system! 

/**
 * Stores vertex data for opengl
 * T is they type of vertex associated with the buffer
 * T must be a struct
 */
public class VertexBuffer(T)
	if(__traits(isPOD, T))
{
	public enum isSingleAttrib = (!is(T == struct)) || isOpenGlCompatibleStruct!T();
	public alias type = T;

	static if(isSingleAttrib) public string name = "";
	public GLuint id = 0;
	public int size = 0;

	// TODO: Check if T is actually supported 


	static if(isSingleAttrib)
	{
		/**
		* Sets the contents of the buffer as well as the buffer useage
		* If the buffer already had data in it, the data is replaced
		*/
		public this(T[] data, string attributeName, BufferUsage usage = BufferUsage.staticDraw)
		{
			setData(data, usage);
			name = attributeName;
		}

		public this(string attributeName)
		{
			reserve();
			name = attributeName;
		}
	}
	else
	{
		/**
		* Sets the contents of the buffer as well as the buffer useage
		* If the buffer already had data in it, the data is replaced
		*/
		public this(T[] data, BufferUsage usage = BufferUsage.staticDraw)
		{
			setData(data, usage);
		}

		public this()
		{
			reserve();
		}
	}



	/**
	 * Sets the contents of the buffer as well as the buffer useage
	 * If the buffer already had data in it, the data is replaced
	 */
	public void setData(T[] data, BufferUsage usage = BufferUsage.staticDraw)
	{
		if(id == 0)
		{
			glGenBuffers(1,&id);
		}

		size = cast(int)data.length;
		glBindBuffer(GL_ARRAY_BUFFER, id); 
		glBufferData(GL_ARRAY_BUFFER, size * T.sizeof, data.ptr, usage);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	/**
	 * Replaces a subsection if the buffer with data
	 * Offset indicates the location in the buffer to begin the replacement
	 * Offset is defined in T units
	 */
	public void setSubData(T[] data, int offset = 0)
	{
		assert(id != 0, "Can not setSubData on uninitialized buffer");
		assert(data.length + offset <= size && offset >= 0, "Bounds of buffer exceeded");
		glBindBuffer(GL_ARRAY_BUFFER, id);
		glBufferSubData(GL_ARRAY_BUFFER, offset*T.sizeof, data.sizeof, data.ptr);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	/**
	 * Reserves a buffer id
	 */
	public void reserve()
	{
		if(id == 0)
		{
			glGenBuffers(1,&id);
		}
	}

	/**
	 * Reset the buffer to an uninitialized state deleteing the buffered data at the same time
	 */
	public void destroy()
	{
		if(id != 0)
		{
			glDeleteBuffers(1,&id);
		}

		id = 0;
		size = 0;
	}
}

auto VertBuffer(T)(T[] data, string attributeName, BufferUsage usage = BufferUsage.staticDraw)
{
	return VertexBuffer!T(data, attributeName, usage);
}

auto VertBuffer(T)(T[] data, BufferUsage usage = BufferUsage.staticDraw)
{
	return VertexBuffer!T(data, usage);
}

/**
 * Stores index data for opengl
 */
public class IndexBuffer
{
	import math.matrix;
	public GLuint id = 0;
	public int size = 0;
	
	/**
	 * Sets the contents of the buffer as well as the buffer useage
	 * If the buffer already had data in it, the data is replaced
	 */
	public this(uvec3[] data, BufferUsage usage = BufferUsage.staticDraw)
	{
		setData(data, usage);
	}

	
	/**
	 * Sets the contents of the buffer as well as the buffer useage
	 * If the buffer already had data in it, the data is replaced
	 */
	public void setData(uvec3[] data, BufferUsage usage = BufferUsage.staticDraw)
	{
		if(id == 0)
		{
			glGenBuffers(1,&id);
		}
		
		size = cast(int)data.length;
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id); 
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, size * uvec3.sizeof, data.ptr, usage);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
	
	/**
	 * Reset the buffer to an uninitialized state deleteing the buffered data at the same time
	 */
	public void destroy()
	{
		if(id != 0)
		{
			glDeleteBuffers(1,&id);
		}
		id = 0;
		size = 0;
	}
}

/**
 * Returns true if the struct can be treated as a basic type as far as openGL is concerned
 */
public bool isOpenGlCompatibleStruct(T)()
{
	import math.matrix;
	import graphics.color;
	if(isMatrix!T) return true;
	else if(is(T == Color)) return true;
	else return false;
}