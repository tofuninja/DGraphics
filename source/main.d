module main;
 
import std.stdio;
import std.string;

pragma(lib, "Comdlg32.lib");

import math.matrix;

import graphics.color;
import graphics.image;
import graphics.render;
import graphics.hw.state;

import gui.panel;
import gui.font;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.opengl3.gl;
import derelict.freeimage.freeimage;
import util.debugger;

void main(string[] args)
{
	import math.conversion;
	import util.gcTracker;


	// Init Graphics State
	initializeGraphicsState(args);
	 
	auto pan = new testPan(vec2(0,0),vec2(500,500),basePan);

	void loadMesh()
	{
		import util.fileDialogue;
		import graphics.mesh;
		import graphics.hw.buffer;
		string file = fileLoadDialogue("*.bin", "Mesh Data");
		auto mdat = loadMesh(file);
		mdat.normilize();
		pan.drawBuffers.attachBuffer(VertBuffer(mdat.vectors , "pos"));
		pan.drawBuffers.attachBuffer(VertBuffer(mdat.vcolors , "col"));
		pan.drawBuffers.attachBuffer(VertBuffer(mdat.texCords, "uv"));
		pan.drawBuffers.attachBuffer(VertBuffer(mdat.normals , "norm"));
		pan.drawBuffers.attachIndexBuffer(IndexBuffer(mdat.indices));
		pan.bufLen = mdat.indices.length;
	}

	void sawpCam()
	{
		import graphics.camera;
		import std.algorithm;
		swap(pan.cam, pan.cam2);
	}

	void loadTex()
	{
		import graphics.hw.texture;
		Image img;
		img.loadImageDialog();
		auto t = Texture(img);
		checkGlError();
		TextureBindPoints[0].bind(t);
	}



	new Button(vec2(510,10),vec2(100,30),"Load Mesh", &loadMesh);
	new Button(vec2(510,50),vec2(160,30),"Load Texture", &loadTex);
	new Button(vec2(510,90),vec2(100,30),"Sawp Cam", &sawpCam);
	pan.blendFactor = new ValueSlider(vec2(510,130),300,"BlendFactor", 0, 1);
	pan.blendFactor.value = 0.5f;

	new label(vec2(510,370), "Hello :D\nUse WASD to move camera\nUse arrow keys to rotate\nUse Q and E to zoom");


	checkGlError();

	glRasterPos2f(-1,1);
	glPixelZoom(1,-1);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glClearColor(0.7f,0.7f,1,1);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);

	// Loop until the user closes the window 
	debug auto tracker = GCTracker(); // Monitor gc activity 
	debug writeln("Enter Main Loop");
	while (!glfwWindowShouldClose(window))
	{
		// Render here 
		glClearColor(0.7f,0.7f,1,1);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		basePan.featchMouse(window);
		basePan.sendTick();
		basePan.composit();

		// Swap front and back buffers
		glfwSwapBuffers(window);
		glfwPollEvents();
		checkGlError();
	}


}




string vsSource = 
q{
#version 330
	
	uniform mat4 mvp;
	uniform mat4 mMat;
	uniform int mode;
	
	in vec3 pos;
	in vec3 norm;
	in vec3 col;
	in vec2 uv;
	
	out vec4 color;
	out vec2 texUV;
	out vec3 n;
	out vec3 worldPos;
	
	void main()
	{
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		gl_Position = mvp*p;
		color.xyz = col;
		color.w = 1;
		texUV = uv;
		n = norm;
		worldPos = pos;
	}
	
};

string fsSource = 
q{
#version 330
	

	uniform sampler2D tex;
	uniform mat4 mvpCam2;
	
	in vec4 color;
	in vec2 texUV;
	in vec3 n;
	in vec3 worldPos;
	out vec4 fragColor;
	void main()
	{
		vec4 p;
		p.xyz = worldPos;
		p.w = 1;
		vec4 proj = mvpCam2*p; 
		proj = proj / proj.w;
		vec2 uv = (proj.xy + vec2(1,1))/2.0f;
		float vis = texture(tex, uv).x;
		if(vis > proj.z - 0.001 && uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1)
			fragColor = vec4(1,1,1,1);
		else fragColor = vec4(0,0,0,1);
		//fragColor = vec4(texture(tex, texUV).x,0,0,1);
	}
	
};



string vsSourceShadow = 
q{
#version 330
	
	uniform mat4 mvp;

	
	in vec3 pos;
	in vec3 norm;
	in vec3 col;
	in vec2 uv;

	out float depth;
	void main()
	{
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		vec4 proj = mvp*p;
		gl_Position = proj;
		depth = (proj.z/proj.w);
	}
	
};

string fsSourceShadow = 
q{
#version 330
	in float depth;
	layout(location = 0) out float fragColor;
	void main()
	{
		fragColor = depth;
	}
	
};




























// Software Shaders

// Basic Shader
struct basicVertexShader
{
	mat4 mvp;
	vertOut opCall(vec3 pos)
	{
		vertOut rtn;
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		rtn.pos = mvp*p;
		return rtn;
	}
}

struct vertOut
{
	vec4 pos;
}

struct basicPixelShader
{
	Color opCall(vertOut vout)
	{
		return ((vout.pos.zzz + vec3(1,1,1)) * 255/2).to!Color;
		//return Color(0,0,0);
	}
}

// Textured Shader
struct texVertShader
{
	mat4 mvp;
	texShaderOut opCall(vec3 pos, vec2 uv)
	{
		texShaderOut rtn;

		vec4 p;
		p.xyz = pos;
		p.w = 1;
		rtn.pos = mvp*p;

		rtn.texCord = uv;

		return rtn;
	}
}

struct texPixelShader
{
	Image tex;
	Color opCall(texShaderOut vout)
	{
		//if(useMirror.value) vout.texCord = uvMirror(vout.texCord);

		//if(!useBilin.value) return textureLookupNearest(tex, vout.texCord);
		//else 
		return textureLookupBilinear(tex, vout.texCord);
	}
}

struct texShaderOut
{
	vec4 pos;
	vec2 texCord;
}


// Shadow mapped shader
struct shadowVertShader
{
	mat4 mvp;
	mat4 light_mvp;
	shadowShaderOut opCall(vec3 pos)
	{
		shadowShaderOut rtn;
		
		vec4 p;
		p.xyz = pos;
		p.w = 1;
		rtn.pos = mvp*p;

		// calc shadow map lookup values
		rtn.shadow = light_mvp*p;
		
		return rtn;
	}
}

struct shadowPixelShader
{
	import graphics.frameBuffer;
	FrameBuffer tex;
	Image tex2;
	float epsilon;
	Color opCall(shadowShaderOut vout)
	{
		vout.shadow = vout.shadow / vout.shadow.w;
		if(vout.shadow.z > tex.depthLookupNearest(vout.shadow.xy)-epsilon) 
		{
			return tex2.textureLookupNearest((vout.shadow.xy + vec2(1,1))/2.0f);
		}
		else return Color(0, 0,0);
	}
}

struct shadowShaderOut
{
	vec4 pos;
	vec4 shadow;
}


class testPan : Panel
{
	import graphics.camera;	
	import graphics.mesh;
	import graphics.frameBuffer;
	import graphics.hw.shader;
	import graphics.hw.buffer;
	import graphics.hw.renderTarget;
	import graphics.hw.texture;

	camera cam;
	camera cam2;
	model[] mArr;
	int time = 0;

	ShaderInput drawBuffers;
	ShaderInput drawBuffers2;
	ShaderInput drawBuffersShadow;
	mat4 planeMat;
	int bufLen;
	enum planeSize = 40.0f;
	ValueSlider blendFactor;
	RenderTarget rTarget;
	Texture renderTar;

	public this(vec2 loc, vec2 size, Panel owner)
	{
		import math.conversion;


		cam = camera(toRad(60), size.x/size.y);
		cam.rot = vec3(toRad(180),0,0);
		cam2 = camera(toRad(60), size.x/size.y);
		cam2.eye = vec3(0,10,-70);
		cam2.rot = vec3(0,toRad(-20),0);
		//cam2.far = -50;
		cam2.invalidate();
		auto m = boxMesh();
		mArr ~= model(boxMesh);
		mArr[0].setModelMatrix(vec3(0,20,-40),vec3(0,0,0), vec3(5,5,5));


		auto vs = Shader(vsSource, ShaderStage.vertex);
		auto fs = Shader(fsSource, ShaderStage.fragment);
		auto prog = ShaderProgram(vs, fs);



		auto vsShadow = Shader(vsSourceShadow, ShaderStage.vertex);
		auto fsShadow = Shader(fsSourceShadow, ShaderStage.fragment);
		auto progShadow = ShaderProgram(vsShadow, fsShadow);






		prog.setUniform("tex", TextureBindPoints[0]);
		prog.setUniform("mMat", (mArr[0].modelMatrix));
		
		drawBuffers = ShaderInput(prog);
		drawBuffers.attachBuffer(VertBuffer(m.vectors, "pos"));
		drawBuffers.attachBuffer(VertBuffer(m.vcolors, "col"));
		drawBuffers.attachBuffer(VertBuffer(m.normals, "norm"));
		drawBuffers.attachBuffer(VertBuffer(m.texCords, "uv"));
		drawBuffers.attachIndexBuffer(IndexBuffer(m.indices));

		drawBuffers2 = ShaderInput(prog);
		drawBuffers2.attachBuffer(VertBuffer(m.vectors, "pos"));
		drawBuffers2.attachBuffer(VertBuffer(m.vcolors, "col"));
		drawBuffers2.attachBuffer(VertBuffer(m.normals, "norm"));
		drawBuffers2.attachBuffer(VertBuffer(m.texCords, "uv"));
		drawBuffers2.attachIndexBuffer(IndexBuffer(m.indices));


		drawBuffersShadow = ShaderInput(progShadow);
		drawBuffersShadow.attachBuffer(VertBuffer(m.vectors, "pos"));
		drawBuffersShadow.attachBuffer(VertBuffer(m.vcolors, "col"));
		drawBuffersShadow.attachBuffer(VertBuffer(m.normals, "norm"));
		drawBuffersShadow.attachBuffer(VertBuffer(m.texCords, "uv"));
		drawBuffersShadow.attachIndexBuffer(IndexBuffer(m.indices));


		bufLen = m.indices.length;

		planeMat = modelMatrix(vec3(0,0,-40),vec3(toRad(180),toRad(90),0), vec3(-planeSize/2,planeSize/2,0.01f));

		renderTar = Texture(1024, 1024,TextureType.Depth);
		TextureBindPoints[0].bind(renderTar);
		rTarget = RenderTarget(renderTar);

		super(loc, null, owner);
	}
	
	override public void tick() 
	{
		import math.conversion;
		import gui.keyboard;
		import std.conv;
		
		enum camSpeed = 0.001f;
		enum camMovSpeed = 0.01f;
		enum camZoomSpeed = 0.01f;
		if(keyState[GLFW_KEY_UP]) cam.rot.y -= camSpeed;
		if(keyState[GLFW_KEY_DOWN]) cam.rot.y += camSpeed;
		if(keyState[GLFW_KEY_LEFT]) cam.rot.x += camSpeed;
		if(keyState[GLFW_KEY_RIGHT]) cam.rot.x -= camSpeed;
		auto rotMat = rotationMatrix(cam.rot);
		if(keyState[GLFW_KEY_W]) cam.eye = cam.eye + (rotMat*vec4(0,0, camMovSpeed,1)).xyz;
		if(keyState[GLFW_KEY_S]) cam.eye = cam.eye + (rotMat*vec4(0,0,-camMovSpeed,1)).xyz;
		if(keyState[GLFW_KEY_A]) cam.eye = cam.eye + (rotMat*vec4( camMovSpeed,0,0,1)).xyz;
		if(keyState[GLFW_KEY_D]) cam.eye = cam.eye + (rotMat*vec4(-camMovSpeed,0,0,1)).xyz;
		
		if(keyState[GLFW_KEY_Q]) cam.zoom -= camZoomSpeed;
		if(keyState[GLFW_KEY_E]) cam.zoom += camZoomSpeed;
		cam.invalidate();

		checkGlError();
		TextureBindPoints[0].unbind();
		rTarget.bind();

		checkGlError();
		// Render to render target
		glClearColor(1,1,1,1);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		drawBuffers.program.setUniform("mode", 0);
		checkGlError();
		foreach(model m; mArr)
		{
			drawBuffersShadow.program.setUniform("mvp", (cam2.projMatrix*cam2.viewMatrix*m.modelMatrix));
			drawBuffersShadow.drawIndexed(0, bufLen*3);
		}

		//drawBuffers2.program.setUniform("mvp", (cam2.projMatrix*cam2.viewMatrix*planeMat));
		//drawBuffers2.drawIndexed(0, bufLen*3);

		checkGlError();
		// Render real sceen 
		TextureBindPoints[0].bind(renderTar);
		resetRenderTarget();

		drawBuffers2.program.setUniform("mode", 1);
		checkGlError();
		foreach(model m; mArr)
		{
			drawBuffers.program.setUniform("mvpCam2", (cam2.projMatrix*cam2.viewMatrix*m.modelMatrix));
			drawBuffers.program.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*m.modelMatrix));
			drawBuffers.program.setUniform("camLoc", cam.eye);
			drawBuffers.drawIndexed(0, bufLen*3);
		}
		checkGlError();
		drawBuffers.program.setUniform("mvpCam2", (cam2.projMatrix*cam2.viewMatrix*planeMat));
		drawBuffers2.program.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*planeMat));
		drawBuffers2.program.setUniform("camLoc", cam.eye);
		drawBuffers2.drawIndexed(0, bufLen*3);

		checkGlError();
		time ++;
	}
}