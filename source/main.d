﻿module main;
 
import std.stdio;
import std.string;


import graphics.Color;
import graphics.Image;
import math.matrix;
import graphics.render;


import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.freeimage.freeimage;

void main(string[] args)
{
	/* Initialize the librarys */
	DerelictGL3.load();
	DerelictGLFW3.load();
	DerelictFI.load();






	if (!glfwInit()) return;

	// Create a windowed mode window and its OpenGL context 
	GLFWwindow* window;
	window = glfwCreateWindow(640, 480, "Hello World", null, null);
	scope(exit) glfwTerminate();
	if (!window) return;
	glfwMakeContextCurrent(window);
	DerelictGL3.reload();

	writeln("OpenGl Version:", DerelictGL3.loadedVersion);

	// Enforce min gl version
	{
		import std.exception;
		enforce(DerelictGL3.loadedVersion >= GLVersion.GL43, "Min gl version is 4.3");
	}

	// Shader test
	{
		import graphics.shader;
		auto prog = shaderProgram(shader(vsSource, shaderStage.vertex), shader(fsSource, shaderStage.fragment));
	}




	// Loop until the user closes the window 
	while (!glfwWindowShouldClose(window))
	{
		// Render here 

		// Swap front and back buffers
		glfwSwapBuffers(window);
		glfwPollEvents();
	}

}



string vsSource = 
q{
#version 330
	
	uniform mat4 mvp;
	layout(location = 0) in vec4 pos;
	layout(location = 1) in vec4 col;
	out vec4 color;
	
	void main()
	{
		gl_Position = mvp*pos;
		color = col;
	}
	
};

string fsSource = 
q{
#version 330
	in vec4 color;
	out vec4 fragColor;
	void main()
	{
		fragColor = color;
	}
	
};