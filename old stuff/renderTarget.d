module graphics.hw.renderTarget;

import std.exception;
import derelict.opengl3.gl3;
import graphics.hw.texture;

// TODO add render buffers
// TODO make it handle different textures better
// TODO make a render target attahcment stack, probably in state 


class RenderTarget
{
	public GLuint id = 0;
	private int w;
	private int h;


	public this(int Width, int Height)
	{
		create(Width, Height);
	}


	public void create(int W, int H)
	{
		w = W;
		h = H;

		glGenFramebuffers(1, &id);
		glBindFramebuffer(GL_FRAMEBUFFER, id);

		glFramebufferParameteri(GL_DRAW_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_WIDTH , w);
		glFramebufferParameteri(GL_DRAW_FRAMEBUFFER, GL_FRAMEBUFFER_DEFAULT_HEIGHT, h);

		/*
		if(depth)
		{
			glGenRenderbuffers(1, &depthId);
			glBindRenderbuffer(GL_RENDERBUFFER, depthId);
			glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, w, h);
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthId);

			glEnable(GL_DEPTH_TEST);
			glDepthFunc(GL_LESS);

			glBindRenderbuffer(GL_RENDERBUFFER, 0);
		}*/

		enforce(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Render Target failed to create.");

		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	// TODO change this....  dont know why I made it take an array, just attach each color seperately 
	public void attachTextures(Texture[] t...)
	{
		GLenum[] DrawBuffers = new GLenum[t.length];
		glBindFramebuffer(GL_FRAMEBUFFER, id);
		for(int i = 0; i < t.length; i++)
		{
			if(t[i] is null)
			{
				DrawBuffers[i] = GL_NONE;
				continue;
			}

			enforce(w == t[i].width, "Width mismatch");
			enforce(h == t[i].height, "Height mismatch");

			glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i, t[i].id, 0);
			DrawBuffers[i] = GL_COLOR_ATTACHMENT0 + i;
		}

		glDrawBuffers(DrawBuffers.length, DrawBuffers.ptr); // "1" is the size of DrawBuffers
		enforce(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Render Target failed to create.");
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	public void attachDepth(Texture t)
	{
		enforce(w == t.width, "Width mismatch");
		enforce(h == t.height, "Height mismatch");
		assert(t.textureType == TextureType.Depth);
		glBindFramebuffer(GL_FRAMEBUFFER, id);
		glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, t.id, 0);
		enforce(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Render Target failed to create.");
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	// TODO add attachStencil and attachDepthStencil 

	public void destroy()
	{
		if(id != 0) glDeleteFramebuffers(1, &id);
		id = 0;
	}

	public void bind()
	{
		glBindFramebuffer(GL_FRAMEBUFFER, id);
		glViewport(0,0,w,h);
	}
}

// Todo, do a better job of this to allow nested render targets 
public void resetRenderTarget()
{
	import graphics.hw.state;
	import derelict.glfw3.glfw3;
	int width, height;
	glfwGetFramebufferSize(window, &width, &height);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glViewport(0, 0, width, height);
}
