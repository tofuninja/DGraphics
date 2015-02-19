module main;
 
import std.stdio;
import std.string;

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



/* 	MAIN  */
void main(string[] args)
{
	gameMain(args);
}


/* GAME MAIN */
void gameMain(string[] args)
{
	import math.conversion;
	import util.gcTracker;
	import std.datetime;
	import graphics.fpsTracker;
	import std.conv;

	// Init Graphics State
	initializeGraphicsState(args);
	 

	// Main renderer
	auto pan = new oglRender(vec2(0,0),vec2(500,500),basePan);

	new label(vec2(510,340), "Hello :D\nUse WASD to move camera\nUse arrow keys to rotate\nUse Q and E to zoom");
	auto fpsLabel = new label(vec2(510,400), vec2(200,25));
	fpsLabel.setText("FPS:");


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
	auto fps = FPSTracker(); // Track fps
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
		fps.postFrame();
		if(fps.totalFrames % 100 == 0) fpsLabel.setText("FPS: " ~ fps.fps.to!string);
	}
}




/* OPENGL RENDERER */
class oglRender : Panel
{
	import graphics.camera;	
	import graphics.mesh;
	import graphics.frameBuffer;
	import graphics.hw.shader;
	import graphics.hw.buffer;
	import graphics.hw.renderTarget;
	import graphics.hw.texture;

	import resources.glslManager;


	camera cam;
	model[] mArr;
	int time = 0;
	ShaderProgram renderShader;

	vec3 light_loc;
	float light_intensity;
	float light_size;


	public this(vec2 loc, vec2 size, Panel owner)
	{
		import math.conversion;

		// Get Shader
		renderShader = softShadow.program;

		// Set up cam
		cam = camera(toRad(60), size.x/size.y);
		cam.rot = vec3(toRad(200), toRad(40),0);
		cam.eye = vec3(10,50,0);

		// Create a box mesh and a shader input for it.
		auto b_mesh = boxMesh();
		ShaderInput box = ShaderInput(renderShader);
		box.attachMesh(b_mesh);


		// Create box models 
		auto m1 = model(box);
		auto m2 = model(box);
		auto m3 = model(box);
		auto plane = model(box);

		m1.setModelMatrix(vec3(0,30,-30),vec3(0,0,0), vec3(5,5,5));
		m2.setModelMatrix(vec3(5,10,-40),vec3(0,0,0), vec3(5,5,5));
		m3.setModelMatrix(vec3(-20,20,-40),vec3(0,0,0), vec3(5,5,5));
		plane.setModelMatrix(vec3(0,0,-40),vec3(0,0,0), vec3(30,0.1,30));


		// Add models to model list 
		mArr = [m1,m2,m3,plane];


		// Set light values
		light_loc = vec3(0, 50, -20);
		light_intensity = 0.01;
		light_size = 0.1;

		super(loc, null, owner);
	}
	
	override public void tick() 
	{
		import math.conversion;
		import gui.keyboard;
		import std.conv;
		
		enum camSpeed = 0.01f;
		enum camMovSpeed = 0.1f;
		enum camZoomSpeed = 0.1f;
		if(keyState[GLFW_KEY_UP]) cam.rot.y -= camSpeed;
		if(keyState[GLFW_KEY_DOWN]) cam.rot.y += camSpeed;
		if(keyState[GLFW_KEY_LEFT]) cam.rot.x -= camSpeed;
		if(keyState[GLFW_KEY_RIGHT]) cam.rot.x += camSpeed;
		auto rotMat = rotationMatrix(cam.rot);
		if(keyState[GLFW_KEY_W]) cam.eye = cam.eye + (rotMat*vec4(0,0, camMovSpeed,1)).xyz;
		if(keyState[GLFW_KEY_S]) cam.eye = cam.eye + (rotMat*vec4(0,0,-camMovSpeed,1)).xyz;
		if(keyState[GLFW_KEY_A]) cam.eye = cam.eye + (rotMat*vec4(-camMovSpeed,0,0,1)).xyz;
		if(keyState[GLFW_KEY_D]) cam.eye = cam.eye + (rotMat*vec4( camMovSpeed,0,0,1)).xyz;
		if(keyState[GLFW_KEY_Q]) cam.zoom -= camZoomSpeed;
		if(keyState[GLFW_KEY_E]) cam.zoom += camZoomSpeed;
		cam.invalidate();


		// movement 
		if(time < 1100)
		{
			int s = (time/100)%2;
			int p;
			if(s)
				p = time%100;
			else
				p = 100 - time%100;

			mArr[0].setModelMatrix(vec3(0,30,-30   + p/10.0f),vec3(0,0,0), vec3(5,5,5));
			mArr[1].setModelMatrix(vec3(5,10,-40   - p/10.0f),vec3(0,0,0), vec3(5,5,5));
			mArr[2].setModelMatrix(vec3(-20,20,-40 - p/10.0f),vec3(0,0,0), vec3(5,5,5));
		}
		else if(time < 2000)
		{
			int s = (time/100)%2;
			int p;
			if(s)
				p = time%100;
			else
				p = 100 - time%100;

			light_size = 0.1 + p/200.0f;
		}


		// Pass in box locations
		renderShader.setUniform("box1", (mArr[0].modelMatrix*vec4(0,0,0,1)).xyz);
		renderShader.setUniform("box2", (mArr[1].modelMatrix*vec4(0,0,0,1)).xyz);
		renderShader.setUniform("box3", (mArr[2].modelMatrix*vec4(0,0,0,1)).xyz);
		renderShader.setUniform("box_size", 5.0f);

		// Pass in light information
		renderShader.setUniform("light_loc", light_loc);
		renderShader.setUniform("light_intensity", light_intensity);
		renderShader.setUniform("light_size", light_size);

		// Render to sceen 
		foreach(model m; mArr)
		{
			renderShader.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*m.modelMatrix));
			renderShader.setUniform("mMat", m.modelMatrix);
			m.shaderInput.draw();
		}

		checkGlError();
		time ++;
	}
}