module graphics.hw.oglgame.vao;

import graphics.hw.enums;
import graphics.hw.structs;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.opengl3.gl3;

public struct vaoRef
{
	// ref type
	package GLuint id = 0;
}

public vaoRef createVao(hwVaoCreateInfo info) @nogc
{
	vaoRef r;
	
	glCreateVertexArrays(1, &r.id);
	
	for(int i = 0; i < 16; i++) {
		auto a = info.attachments[i];
		if(a.enabled) {
			glEnableVertexArrayAttrib(r.id, i);
			glVertexArrayAttribFormat(r.id, i, a.elementCount, oglgVertTypeToOglenum(a.elementType), GL_FALSE, a.offset);
			glVertexArrayAttribBinding(r.id, i, a.bindIndex);
		}
	}
	
	for(int i = 0; i < 16; i++) {
		auto d = info.bindPointDivisors[i];
		if(d != 0) {
			glVertexArrayBindingDivisor(r.id, i, d);
		}
	}
	oglgCheckError();
	return r;
}

public void destroyVao(ref vaoRef obj) @nogc
{
	glDeleteVertexArrays(1, &obj.id);
	obj.id = 0;
	oglgCheckError();
}

/**
 * Convert a vertex type to its corresponding ogl enum
 */
package GLenum oglgVertTypeToOglenum(hwVertexType t) @nogc
{
	with(hwVertexType) {
		switch(t) {
			case int8:		return GL_BYTE;
			case int16:		return GL_SHORT;
			case int32:		return GL_INT;
			case uint8:		return GL_UNSIGNED_BYTE;
			case uint16:	return GL_UNSIGNED_SHORT;
			case uint32:	return GL_UNSIGNED_INT;
			case float16:	return GL_HALF_FLOAT;
			case float32:	return GL_FLOAT;
			default: assert(false, "Invalid vertex type");
		}
	}
}