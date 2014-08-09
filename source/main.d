module main;
 
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

	writeln(DerelictGL3.loadedVersion);


	struct vertex
	{
		vec4 pos;
		vec4 color;
	}
	vertex[7] data;

	data[0].pos = vec4(0,0,0,1);
	data[0].color = vec4(1,0,0,1);

	data[1].pos = vec4(1,0,0,1);
	data[1].color = vec4(1,0,0,1);

	data[2].pos = vec4(0,1,0,1);
	data[2].color = vec4(0,1,0,1);

	data[3].pos = vec4(1,1,0,1);
	data[3].color = vec4(0,1,0,1);

	data[4].pos = vec4(1,1,1,1);
	data[4].color = vec4(0,0,1,1);

	data[5].pos = vec4(0,1,1,1);
	data[5].color = vec4(0,0,1,1);

	data[6].pos = vec4(0,1,0,1);
	data[6].color = vec4(0,1,0,1);



	GLuint vbo;
	glGenBuffers(1,&vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, data.sizeof, data.ptr, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	GLuint vs = glCreateShader(GL_VERTEX_SHADER);
	GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);

	const char* vsc = vsSource.toStringz;
	const char* fsc = fsSource.toStringz;

	glShaderSource(vs,1, &vsc, null);
	glCompileShader(vs);
	GLint isCompiled = 0;
	glGetShaderiv(vs, GL_COMPILE_STATUS, &isCompiled);
	if(isCompiled == GL_FALSE)
	{
		GLint maxLength = 0;
		glGetShaderiv(vs, GL_INFO_LOG_LENGTH, &maxLength);
		char[] log = new char[maxLength];
		glGetShaderInfoLog(vs, maxLength, &maxLength, log.ptr);
		writeln(log);
		glDeleteShader(vs);
	}

	glShaderSource(fs,1, &fsc, null);
	glCompileShader(fs);
	isCompiled = 0;
	glGetShaderiv(fs, GL_COMPILE_STATUS, &isCompiled);
	if(isCompiled == GL_FALSE)
	{
		GLint maxLength = 0;
		glGetShaderiv(fs, GL_INFO_LOG_LENGTH, &maxLength);
		char[] log = new char[maxLength];
		glGetShaderInfoLog(fs, maxLength, &maxLength, log.ptr);
		writeln(log);
		glDeleteShader(fs);
	}

	GLuint program = glCreateProgram();
	
	//Attach our shaders to our program
	glAttachShader(program, vs);
	glAttachShader(program, fs);
	
	//Link our program
	glLinkProgram(program);
	
	//Note the different functions here: glGetProgram* instead of glGetShader*.
	GLint isLinked = 0;
	glGetProgramiv(program, GL_LINK_STATUS, &isLinked);
	if(isLinked == GL_FALSE)
	{
		GLint maxLength = 0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &maxLength);
		char[] log = new char[maxLength];
		glGetProgramInfoLog(program, maxLength, &maxLength, log.ptr);
		writeln(log);
		glDeleteProgram(program);
		glDeleteShader(vs);
		glDeleteShader(fs);
	}
	
	//Always detach shaders after a successful link.
	glDetachShader(program, vs);
	glDetachShader(program, fs);
	glDeleteShader(vs);
	glDeleteShader(fs);


	GLuint mvpUniform = glGetUniformLocation(program, "mvp\0");






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