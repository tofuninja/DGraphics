module main;
 
import std.stdio;
import std.string;

pragma(lib, "Comdlg32.lib");

import math.matrix;

import graphics.Color;
import graphics.Image;
import graphics.render;
import graphics.GraphicsState;

import gui.Panel;
import gui.Font;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.opengl3.gl;
import derelict.freeimage.freeimage;



void main(string[] args)
{
	// Init Graphics State
	initializeGraphicsState();


	new testPan(vec2(0,0),vec2(500,500),basePan);

	glRasterPos2f(-1,1);
	glPixelZoom(1,-1);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glClearColor(1,1,1,1);
	// Loop until the user closes the window 
	while (!glfwWindowShouldClose(window))
	{
		// Render here 
		glClear(GL_COLOR_BUFFER_BIT);
		basePan.featchMouse(window);
		basePan.sendTick();
		basePan.composit();
		// Swap front and back buffers
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
}


class testPan : Panel
{
	import graphics.camera;	
	import graphics.mesh;

	camera cam;
	model m;
	int time = 0;

	public this(vec2 loc, vec2 size, Panel owner)
	{
		import math.conversion;
		cam = camera(toRad(60), size.x/size.y);
		m = model(boxMesh);

		super(loc, size, owner);
	}

	override public void tick() 
	{
		import math.conversion;
		img.clear(Color(0,0,0,255));
		m.modelMatrix = translationMatrix(0,0,-60)*rotationMatrix(vec3(0,1,0), toRad(time))*scalingMatrix(vec3(5,5,5));
		img.drawWireModel(m, cam);
		time ++;
	}
}

