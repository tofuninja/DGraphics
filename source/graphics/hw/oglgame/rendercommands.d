module graphics.hw.oglgame.rendercommands;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.oglgame.state;
import graphics.hw.oglgame.sampler;
import graphics.hw.oglgame.cursor;


import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.opengl3.gl3;

public void pollEvents() {
	glfwPollEvents();
	state.shouldClose = glfwWindowShouldClose(window) != 0;
}

public void swapBuffers() {
	glfwSwapBuffers(window);
	oglgCheckError();
}

public void cmd(hwDrawCommand command) @nogc
{
	glDrawArraysInstancedBaseInstance(
		primMode, 
		command.vertexOffset, 
		command.vertexCount, 
		command.instanceCount, 
		command.instanceOffset 
		);
	oglgCheckError();
}

public void cmd(hwDrawIndexedCommand command) @nogc
{
	glDrawElementsInstancedBaseVertexBaseInstance(
		primMode, 
		command.vertexCount, 
		glhwIndexSize, 
		cast(GLvoid*)(indexOffset + command.indexOffset*indexByteSize),
		command.instanceCount,
		command.vertexOffset,
		command.instanceOffset
		);
	oglgCheckError();
}                

public void cmd(hwUboCommand command) @nogc
{
	assert(command.offset%(uniformAlignment) == 0, "Invalid allignment");
	glBindBufferRange(GL_UNIFORM_BUFFER, command.location, command.ubo.id, command.offset, command.size);
	oglgCheckError();
}

public void cmd(hwVboCommand command) @nogc
{
	with(curRenderState) {
		glVertexArrayVertexBuffer(vao.id, command.location, command.vbo.id, command.offset, command.stride);
	}
	oglgCheckError();
}

public void cmd(hwIboCommand command) @nogc
{
	with(curRenderState) {
		glVertexArrayElementBuffer(vao.id, command.ibo.id);
	}
	
	switch(command.size) {
		case hwIndexSize.uint8: 	glhwIndexSize = GL_UNSIGNED_BYTE; 	indexByteSize = 1; break;
		case hwIndexSize.uint16: 	glhwIndexSize = GL_UNSIGNED_SHORT; 	indexByteSize = 2; break;
		case hwIndexSize.uint32: 	glhwIndexSize = GL_UNSIGNED_INT; 		indexByteSize = 4; break;
		default: assert(false, "Wut?");
	}
	
	indexOffset = command.offset;
	oglgCheckError();
}

public void cmd(hwTextureType T)(hwTexCommand!T command) @nogc
{
	glBindTextureUnit(command.location, command.texture.id);
	oglgCheckError();
}

public void cmd(hwSamplerCommand command) @nogc
{
	glBindSampler(command.location, command.sampler.id);
	oglgCheckError();
}

public void cmd(hwBlitCommand command) @nogc
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
		oglgFilter(command.filter, hwMipmapFilterMode.none)
		);
	oglgCheckError();
}

public void cmd(hwClearCommand command) @nogc
{
	import graphics.color;
	import math.matrix;
	
	vec4 c = command.colorClear.to!vec4();
	glClearColor(c.x, c.y, c.z, c.w);
	glClearDepth(command.depthClear);
	glClearStencil(command.stencilClear);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	oglgCheckError();
}

public void cmd(hwRenderStateInfo command) @nogc
{
	oglgApplyStateDif(command);
	oglgCheckError();
}

public void cmd(cursorRef command) @nogc
{
	static GLFWcursor* current = null;
	if(current == command.obj) return;
	current = command.obj;

	glfwSetCursor(window, command.obj);
	oglgCheckError();
}

public void cmd(hwMousePosCommand command) @nogc
{
	glfwSetCursorPos(window, command.loc.x, command.loc.y);	
}

public void cmd(hwCursorMode command) {
	if(command == hwCursorMode.normal)
		glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
	else if(command == hwCursorMode.hidden)
		glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
	else if(command == hwCursorMode.captured)
		glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
}

public void cmd(hwVisibilityCommand command) {
	if(command.visible) {
		glfwShowWindow(window);
	} else {
		glfwHideWindow(window);
	}
	state.visible = command.visible;
}

public void cmd(hwDoubleClickCommand cmd) {
	state.doubleClick = cmd.doubleClickTime;
}

public void cmd(hwICallback cmd) {
	callbacks = cmd;
}

/**
 * Apply the state, but only change the things that need to be changed
 */
package void oglgApplyStateDif(hwRenderStateInfo state) @nogc
{
	with(curRenderState) {
		if(state.mode != mode) {
			switch(state.mode) {
				case hwRenderMode.points: 		primMode = GL_POINTS;			break;
				case hwRenderMode.lines: 			primMode = GL_LINES;			break;
				case hwRenderMode.triangles: 		primMode = GL_TRIANGLES;		break;
				case hwRenderMode.patches: 		primMode = GL_PATCHES;		break;
				case hwRenderMode.lineStrip: 		primMode = GL_LINE_STRIP;		break;
				case hwRenderMode.triangleStrip:	primMode = GL_TRIANGLE_STRIP;	break;
				default: assert(false, "Wut?");
			}
		}
		if(state.vao != vao) {
			glBindVertexArray(state.vao.id);
		}
		if(state.shader != shader) {
			glUseProgram(state.shader.id);
		}
		if(state.fbo != fbo) {
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, state.fbo.id);
		}
		if(state.depthTest != depthTest) {
			if(state.depthTest) glEnable(GL_DEPTH_TEST);
			else glDisable(GL_DEPTH_TEST);
		}
		if(state.depthFunction != depthFunction) {
			switch(state.depthFunction) {
				case hwCmpFunc.always:		glDepthFunc(GL_ALWAYS); 	break;
				case hwCmpFunc.never:			glDepthFunc(GL_NEVER); 		break;
				case hwCmpFunc.less:			glDepthFunc(GL_LESS); 		break;
				case hwCmpFunc.lessEqual:		glDepthFunc(GL_LEQUAL); 	break;
				case hwCmpFunc.greater:		glDepthFunc(GL_GREATER); 	break;
				case hwCmpFunc.greaterEqual:	glDepthFunc(GL_GEQUAL); 	break;
				case hwCmpFunc.equal:			glDepthFunc(GL_EQUAL); 		break;
				case hwCmpFunc.notEqual:		glDepthFunc(GL_NOTEQUAL); 	break;
				default: assert(false, "Wut?");
			}
		}
		if(state.viewport != viewport) {
			glViewport(state.viewport.loc.x, state.viewport.loc.y, state.viewport.size.x, state.viewport.size.y);
		}
		if(state.blend != blend) {
			if(state.blend) glEnable(GL_BLEND);
			else glDisable(GL_BLEND);
		}
		if(state.blendState != blendState) {
			glBlendEquationSeparate(
				hwBlendModeToEnum(state.blendState.colorBlend),
				hwBlendModeToEnum(state.blendState.alphaBlend)
				);

			glBlendFuncSeparate(
				blendParamToEnum(state.blendState.srcColor),
				blendParamToEnum(state.blendState.dstColor),
				blendParamToEnum(state.blendState.srcAlpha),
				blendParamToEnum(state.blendState.dstAlpha)
				);
		}
		for(int i = 0; i < 8; i++) {
			if(state.enableClip[i] != enableClip[i]) {
				if(state.enableClip[i]) {
					glEnable(GL_CLIP_DISTANCE0 + i);
				} else {
					glDisable(GL_CLIP_DISTANCE0 + i);
				}
			}
		}
		if(state.backFaceCulling != backFaceCulling) {
			if(state.backFaceCulling) glEnable(GL_CULL_FACE);
			else glDisable(GL_CULL_FACE);
		}
		if(state.frontOrientation != frontOrientation) {
			if(state.frontOrientation == hwFrontFaceMode.clockwise) glFrontFace(GL_CW);
			else glFrontFace(GL_CCW);
		}
	}

	curRenderState = state;
	oglgCheckError();
}

private GLenum hwBlendModeToEnum(hwBlendMode mode) @nogc
{
	switch(mode) {
		case hwBlendMode.add: 			return GL_FUNC_ADD;
		case hwBlendMode.subtract:		return GL_FUNC_SUBTRACT;
		case hwBlendMode.rev_subtract:	return GL_FUNC_REVERSE_SUBTRACT;
		case hwBlendMode.min:				return GL_MIN;
		case hwBlendMode.max:				return GL_MAX;
		default: assert(false);
	}
}


private GLenum blendParamToEnum(hwBlendParameter param) @nogc
{
	switch(param) {
		case hwBlendParameter.zero:					return GL_ZERO;
		case hwBlendParameter.one:					return GL_ONE;
		case hwBlendParameter.src_color:				return GL_SRC_COLOR;
		case hwBlendParameter.dst_color:				return GL_DST_COLOR;
		case hwBlendParameter.src_alpha:				return GL_SRC_ALPHA;
		case hwBlendParameter.dst_alpha:				return GL_DST_ALPHA;
		case hwBlendParameter.one_minus_src_color:	return GL_ONE_MINUS_SRC_COLOR;
		case hwBlendParameter.one_minus_dst_color:	return GL_ONE_MINUS_DST_COLOR;
		case hwBlendParameter.one_minus_src_alpha:	return GL_ONE_MINUS_SRC_ALPHA;
		case hwBlendParameter.one_minus_dst_alpha:	return GL_ONE_MINUS_DST_ALPHA;
		default: assert(false);
	}
}