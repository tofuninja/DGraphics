module graphics.hw.oglgame.buffer;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;

public struct bufferRef
{
	// ref type
	package GLuint id = 0;
	
	public void subData(bufferSubDataInfo info) @nogc
	{
		oglgBufferSubData(this, info);
	}
	
	public void invalidate() @nogc
	{
		assert(id != 0, "Invalid buffer");
		glInvalidateBufferData(id);
	}
}

public bufferRef createBuffer(bufferCreateInfo info) @nogc
{
	bufferRef r;
	GLbitfield flags = 0;
	if(info.data !is null) assert(info.data.length == info.size, "Size and data length mismatch");
	if(info.dynamic) flags |= GL_DYNAMIC_STORAGE_BIT;
	GLenum target = oglgVertexUsageToEnum(info.usage);
	glGenBuffers(1, &r.id);
	glBindBuffer(target, r.id);
	glBindBuffer(target, 0);
	glNamedBufferStorage(r.id, info.size, info.data.ptr, flags);
	return r;
}

public void destroyBuffer(ref bufferRef obj) @nogc
{
	glDeleteBuffers(1, &obj.id);
	obj.id = 0;
}

package void oglgBufferSubData(bufferRef obj, bufferSubDataInfo info) @nogc
{
	glNamedBufferSubData(obj.id, info.offset, info.data.length, info.data.ptr);
}

package GLenum oglgVertexUsageToEnum(bufferUsage use) @nogc
{
	switch(use)
	{
		case bufferUsage.vertex:	return GL_ARRAY_BUFFER;
		case bufferUsage.uniform: 	return GL_UNIFORM_BUFFER;
		case bufferUsage.index: 	return GL_ELEMENT_ARRAY_BUFFER;
		default: assert(false, "Unsupported vertex usage type");
	}
	
}

