module graphics.hw.oglgame.fbo;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;

public struct fboRef
{
	// ref type
	package GLuint id = 0;
	// TODO add a getter for getteing framebuffer contents
}

public fboRef createFbo(fboCreateInfo info) @nogc
{
	fboRef r;
	GLenum[8] DrawBuffers;
	
	glGenFramebuffers(1, &r.id);
	glBindFramebuffer(GL_FRAMEBUFFER, r.id);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	
	// Attach colors
	for(int i = 0; i < 8; i++)
	{
		if(info.colors[i].enabled == false)
		{
			DrawBuffers[i] = GL_NONE;
			continue;
		}

		auto id = info.colors[i].tex.id;
		
		if(!info.colors[i].tex.isRenderBuffer)
		{
			glNamedFramebufferTexture(r.id, GL_COLOR_ATTACHMENT0 + i, id, 0);
		}
		else 
		{
			glNamedFramebufferRenderbuffer(r.id, GL_COLOR_ATTACHMENT0 + i, GL_RENDERBUFFER, id);
		}
		
		DrawBuffers[i] = GL_COLOR_ATTACHMENT0 + i;
	}
	
	// Attach Depth and Stencil
	if(info.depthstencil.enabled)
	{
		// If depthstencil enabled, ignore the depth and stencil settings
		auto id = info.depthstencil.tex.id;
		if(!info.depthstencil.tex.isRenderBuffer)
			glNamedFramebufferTexture(r.id, GL_DEPTH_STENCIL_ATTACHMENT, id, 0);
		else 
			glNamedFramebufferRenderbuffer(r.id, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, id);
	}
	else
	{
		// Depth
		if(info.depth.enabled)
		{
			auto id = info.depth.tex.id;
			if(!info.depth.tex.isRenderBuffer)
				glNamedFramebufferTexture(r.id, GL_DEPTH_ATTACHMENT, id, 0);
			else 
				glNamedFramebufferRenderbuffer(r.id, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, id);
		}
		
		// Stencil
		if(info.depth.enabled)
		{
			auto id = info.stencil.tex.id;
			if(!info.stencil.tex.isRenderBuffer)
				glNamedFramebufferTexture(r.id, GL_STENCIL_ATTACHMENT, id, 0);
			else 
				glNamedFramebufferRenderbuffer(r.id, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, id);
		}
	}
	
	glNamedFramebufferDrawBuffers(r.id, DrawBuffers.length, DrawBuffers.ptr);

	auto error = glCheckNamedFramebufferStatus(r.id, GL_FRAMEBUFFER);
	if(error != GL_FRAMEBUFFER_COMPLETE)
	{
		switch(error)
		{
			case GL_FRAMEBUFFER_UNDEFINED : 						assert(false, "GL_FRAMEBUFFER_UNDEFINED");
			case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT : 			assert(false, "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT");
			case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT : 	assert(false, "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT");
			case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER : 			assert(false, "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER");		
			case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER : 			assert(false, "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER");
			case GL_FRAMEBUFFER_UNSUPPORTED : 						assert(false, "GL_FRAMEBUFFER_UNSUPPORTED");
			case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE : 			assert(false, "GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE");
			case GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS :  		assert(false, "GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS");
			default : 												assert(false, "Unknown framebuffer error");
		} 
	}

	return r;
}

public void destroyFbo(ref fboRef obj) @nogc
{
	glDeleteFramebuffers(1, &obj.id);
	obj.id = 0;
}
