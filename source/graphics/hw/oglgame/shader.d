module graphics.hw.oglgame.shader;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
 
import graphics.hw.oglgame.state;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;

public struct shaderRef
{
	// ref type
	package GLuint id = 0;
}

public shaderRef createShader(shaderCreateInfo info) @nogc
{
	shaderRef r;
	
	GLuint[5] stages;
	stages[0] = oglgCreateStage(info.vertShader, oglgShaderStage.vertex);
	stages[1] = oglgCreateStage(info.fragShader, oglgShaderStage.fragment);
	stages[2] = oglgCreateStage(info.geomShader, oglgShaderStage.geometry);
	stages[3] = oglgCreateStage(info.tescShader, oglgShaderStage.tessControl);
	stages[4] = oglgCreateStage(info.teseShader, oglgShaderStage.tessEvaluation);
	
	r.id = glCreateProgram();
	
	foreach(GLuint s; stages)
	{
		if(s != 0) glAttachShader(r.id, s);
	}
	
	
	glLinkProgram(r.id);
	
	GLint status;
	glGetProgramiv(r.id, GL_LINK_STATUS, &status);
	if(status == GL_FALSE) assert(false, "Shader link failure");

	foreach(GLuint s; stages)
	{
		if(s == 0) continue;
		glDetachShader(r.id, s);
		glDeleteShader(s);
	}

	return r;
}

public void destroyShader(ref shaderRef obj) @nogc
{
	glDeleteProgram(obj.id);
	obj.id = 0;
}

/**
 * Shader stage types
 */
package enum oglgShaderStage
{
	invalid 		= 0,
	vertex 			= GL_VERTEX_SHADER,
	fragment 		= GL_FRAGMENT_SHADER,
	geometry 		= GL_GEOMETRY_SHADER,
	tessControl 	= GL_TESS_CONTROL_SHADER,
	tessEvaluation 	= GL_TESS_EVALUATION_SHADER,
	compute 		= GL_COMPUTE_SHADER
}

/**
 * Compile a shader stage from its glsl source
 */
package GLuint oglgCreateStage(string source, oglgShaderStage stage) @nogc
{
	assert(stage != oglgShaderStage.invalid, "Must be a valid shader stage");
	if(source is null) return 0;
	
	GLuint id = glCreateShader(stage);
	auto ptr = source.ptr;
	glShaderSource(id, 1, &ptr, null);
	glCompileShader(id);
	
	GLint status;
	glGetShaderiv(id, GL_COMPILE_STATUS, &status);
	if(status == false) assert(false, "Shader compile failure");
	
	return id;
}