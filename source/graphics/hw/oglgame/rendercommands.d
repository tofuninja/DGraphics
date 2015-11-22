module graphics.hw.oglgame.rendercommands;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
import graphics.hw.oglgame.state;
import graphics.hw.oglgame.sampler;
import graphics.hw.oglgame.cursor;


import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;

public void swapBuffers()
{
	 
	glfwSwapBuffers(window);
	state.shouldClose = glfwWindowShouldClose(window) != 0;
	
	// Calc fps
	{
		import std.datetime;
		frame++;
		totalFrames++;
		if((Clock.currTime - lastTime).total!"msecs" > 1000)
		{
			fps = frame*(1000.0/(Clock.currTime - lastTime).total!"msecs");
			lastTime = Clock.currTime;
			frame = 0;
		}
		
		state.fps = fps;
		state.totalFrames = totalFrames;
	}
	
	glfwPollEvents();
}

public void cmd(drawCommand command) @nogc
{
	glDrawArraysInstancedBaseInstance(
		primMode, 
		command.vertexOffset, 
		command.vertexCount, 
		command.instanceCount, 
		command.instanceOffset 
		);
}

public void cmd(drawIndexedCommand command) @nogc
{
	glDrawElementsInstancedBaseVertexBaseInstance(
		primMode, 
		command.vertexCount, 
		glindexSize, 
		cast(GLvoid*)(indexOffset + command.indexOffset*indexByteSize),
		command.instanceCount,
		command.vertexOffset,
		command.instanceOffset
		);
}                

public void cmd(uboCommand command) @nogc
{
	assert(command.offset%(uniformAlignment) == 0, "Invalid allignment");
	glBindBufferRange(GL_UNIFORM_BUFFER, command.location, command.ubo.id, command.offset, command.size);
}

public void cmd(vboCommand command) @nogc
{
	with(curRenderState)
	{
		glVertexArrayVertexBuffer(vao.id, command.location, command.vbo.id, command.offset, command.stride);
	}
}

public void cmd(iboCommand command) @nogc
{
	with(curRenderState)
	{
		glVertexArrayElementBuffer(vao.id, command.ibo.id);
	}
	
	switch(command.size)
	{
		case indexSize.uint8: 	glindexSize = GL_UNSIGNED_BYTE; 	indexByteSize = 1; break;
		case indexSize.uint16: 	glindexSize = GL_UNSIGNED_SHORT; 	indexByteSize = 2; break;
		case indexSize.uint32: 	glindexSize = GL_UNSIGNED_INT; 		indexByteSize = 4; break;
		default: assert(false, "Wut?");
	}
	
	indexOffset = command.offset;
}

public void cmd(textureType T)(texCommand!T command) @nogc
{
	glBindTextureUnit(command.location, command.texture.id);
}

public void cmd(samplerCommand command) @nogc
{
	glBindSampler(command.location, command.sampler.id);
}

public void cmd(blitCommand command) @nogc
{
	/*
	void glBlitNamedFramebuffer(
		GLuint readFramebuffer,
	 	GLuint drawFramebuffer,
	 	GLint srcX0,
	 	GLint srcY0,
	 	GLint srcX1,
	 	GLint srcY1,
	 	GLint dstX0,
	 	GLint dstY0,
	 	GLint dstX1,
	 	GLint dstY1,
	 	GLbitfield mask,
	 	GLenum filter);
	*/
	GLbitfield mask = 0;
	if(command.blitColor) 	mask |= GL_COLOR_BUFFER_BIT;
	if(command.blitDepth) 	mask |= GL_DEPTH_BUFFER_BIT;
	if(command.blitStencil) mask |= GL_STENCIL_BUFFER_BIT;
	
	glBlitNamedFramebuffer(
		command.fbo.id, 
		curRenderState.fbo.id, 
		command.source.loc.x, 
		command.source.loc.y, 
		command.source.loc.x + command.source.size.x,
		command.source.loc.y + command.source.size.y,
		command.destination.loc.x, 
		command.destination.loc.y, 
		command.destination.loc.x + command.destination.size.x,
		command.destination.loc.y + command.destination.size.y,
		mask,
		oglgFilter(command.filter, mipmapFilterMode.none)
		);
}

public void cmd(clearCommand command) @nogc
{
	import graphics.color;
	import math.matrix;
	
	vec4 c = command.colorClear.to!vec4();
	glClearColor(c.x, c.y, c.z, c.w);
	glClearDepth(command.depthClear);
	glClearStencil(command.stencilClear);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
}

public void cmd(renderStateInfo command) @nogc
{
	oglgApplyStateDif(command);
}

public void cmd(cursorRef command) @nogc
{
	glfwSetCursor(window, command.obj);
}


/**
 * Apply the state, but only change the things that need to be changed
 */
package void oglgApplyStateDif(renderStateInfo state) @nogc
{
	with(curRenderState)
	{
		if(state.mode != mode)
		{
			switch(state.mode)
			{
				case renderMode.points: 		primMode = GL_POINTS;			break;
				case renderMode.lines: 			primMode = GL_LINES;			break;
				case renderMode.triangles: 		primMode = GL_TRIANGLES;		break;
				case renderMode.patches: 		primMode = GL_PATCHES;		break;
				case renderMode.lineStrip: 		primMode = GL_LINE_STRIP;		break;
				case renderMode.triangleStrip:	primMode = GL_TRIANGLE_STRIP;	break;
				default: assert(false, "Wut?");
			}
		}
		if(state.vao != vao)
		{
			glBindVertexArray(state.vao.id);
		}
		if(state.shader != shader)
		{
			glUseProgram(state.shader.id);
		}
		if(state.fbo != fbo)
		{
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, state.fbo.id);
		}
		if(state.depthTest != depthTest)
		{
			if(state.depthTest) glEnable(GL_DEPTH_TEST);
			else glDisable(GL_DEPTH_TEST);
		}
		if(state.depthFunction != depthFunction)
		{
			switch(state.depthFunction)
			{
				case cmpFunc.always:		glDepthFunc(GL_ALWAYS); 	break;
				case cmpFunc.never:			glDepthFunc(GL_NEVER); 		break;
				case cmpFunc.less:			glDepthFunc(GL_LESS); 		break;
				case cmpFunc.lessEqual:		glDepthFunc(GL_LEQUAL); 	break;
				case cmpFunc.greater:		glDepthFunc(GL_GREATER); 	break;
				case cmpFunc.greaterEqual:	glDepthFunc(GL_GEQUAL); 	break;
				case cmpFunc.equal:			glDepthFunc(GL_EQUAL); 		break;
				case cmpFunc.notEqual:		glDepthFunc(GL_NOTEQUAL); 	break;
				default: assert(false, "Wut?");
			}
		}
		if(state.viewport != viewport)
		{
			glViewport(state.viewport.loc.x, state.viewport.loc.y, state.viewport.size.x, state.viewport.size.y);
		}
		if(state.blend != blend)
		{
			if(state.blend) glEnable(GL_BLEND);
			else glDisable(GL_BLEND);
		}
		if(state.blendState != blendState)
		{
			glBlendEquationSeparate(
				blendModeToEnum(state.blendState.colorBlend),
				blendModeToEnum(state.blendState.alphaBlend)
				);

			glBlendFuncSeparate(
				blendParamToEnum(state.blendState.srcColor),
				blendParamToEnum(state.blendState.dstColor),
				blendParamToEnum(state.blendState.srcAlpha),
				blendParamToEnum(state.blendState.dstAlpha)
				);
		}
		for(int i = 0; i < 8; i++)
		{
			if(state.enableClip[i] != enableClip[i])
			{
				if(state.enableClip[i])
				{
					glEnable(GL_CLIP_DISTANCE0 + i);
				}
				else
				{
					glDisable(GL_CLIP_DISTANCE0 + i);
				}
			}
		}
		if(state.backFaceCulling != backFaceCulling)
		{
			if(state.backFaceCulling) glEnable(GL_CULL_FACE);
			else glDisable(GL_CULL_FACE);
		}
		if(state.frontOrientation != frontOrientation)
		{
			if(state.frontOrientation == frontFaceMode.clockwise) glFrontFace(GL_CW);
			else glFrontFace(GL_CCW);
		}
	}

	curRenderState = state;
}

private GLenum blendModeToEnum(blendMode mode) @nogc
{
	switch(mode)
	{
		case blendMode.add: 			return GL_FUNC_ADD;
		case blendMode.subtract:		return GL_FUNC_SUBTRACT;
		case blendMode.rev_subtract:	return GL_FUNC_REVERSE_SUBTRACT;
		case blendMode.min:				return GL_MIN;
		case blendMode.max:				return GL_MAX;
		default: assert(false);
	}
}


private GLenum blendParamToEnum(blendParameter param) @nogc
{
	switch(param)
	{
		case blendParameter.zero:					return GL_ZERO;
		case blendParameter.one:					return GL_ONE;
		case blendParameter.src_color:				return GL_SRC_COLOR;
		case blendParameter.dst_color:				return GL_DST_COLOR;
		case blendParameter.src_alpha:				return GL_SRC_ALPHA;
		case blendParameter.dst_alpha:				return GL_DST_ALPHA;
		case blendParameter.one_minus_src_color:	return GL_ONE_MINUS_SRC_COLOR;
		case blendParameter.one_minus_dst_color:	return GL_ONE_MINUS_DST_COLOR;
		case blendParameter.one_minus_src_alpha:	return GL_ONE_MINUS_SRC_ALPHA;
		case blendParameter.one_minus_dst_alpha:	return GL_ONE_MINUS_DST_ALPHA;
		default: assert(false);
	}
}