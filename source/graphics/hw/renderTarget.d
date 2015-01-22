module graphics.hw.renderTarget;

import derelict.opengl3.gl3;
import graphics.hw.texture;

struct RenderTarget
{
	public GLuint id = 0;
	public GLuint depthId = 0;
	private int w;
	private int h;


	public this(Texture tex, int layer = -1, bool depth = true)
	{
		create(tex, layer, depth);
	}


	public void create(Texture tex, int layer = -1, bool depth = true)
	{
		glGenFramebuffers(1, &id);
		glBindFramebuffer(GL_FRAMEBUFFER, id);

		w = tex.width;
		h = tex.height;

		if(depth)
		{
			glGenRenderbuffers(1, &depthId);
			glBindRenderbuffer(GL_RENDERBUFFER, depthId);
			glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, w, h);
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthId);
		}

		if(tex.textureType == TextureType.Depth)
		{
			glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, tex.id, 0);
			GLenum DrawBuffers[1] = [GL_COLOR_ATTACHMENT0];
			glDrawBuffers(1, DrawBuffers.ptr); // "1" is the size of DrawBuffers
		}
		else 
		{
			glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, tex.id, 0);
			GLenum DrawBuffers[1] = [GL_COLOR_ATTACHMENT0];
			glDrawBuffers(1, DrawBuffers.ptr); // "1" is the size of DrawBuffers
		}




		assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Render Target failed to create.");

		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	public void destroy()
	{
		if(id != 0) glDeleteFramebuffers(1, &id);
		id = 0;
		depthId = 0;
	}

	public void bind()
	{
		glBindFramebuffer(GL_FRAMEBUFFER, id);
		glViewport(0,0,w,h);
	}
}

public void resetRenderTarget()
{
	import graphics.hw.state;
	import derelict.glfw3.glfw3;
	int width, height;
	glfwGetFramebufferSize(window, &width, &height);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glViewport(0, 0, width, height);
}
