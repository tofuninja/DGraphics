module graphics.shader;

import derelict.opengl3.gl3;
import std.variant;


enum shaderStage
{
	invalid = 0,
	vertex = GL_VERTEX_SHADER,
	fragment = GL_FRAGMENT_SHADER,
	geometry = GL_GEOMETRY_SHADER,
	tessControl = GL_TESS_CONTROL_SHADER,
	tessEvaluation = GL_TESS_EVALUATION_SHADER,
	compute = GL_COMPUTE_SHADER
}





struct shader
{
	private bool created = false;
	private shaderStage m_stage = shaderStage.invalid;
	private GLuint m_id = 0;

	public this(string source, shaderStage stage)
	{
		setSource(source, stage);
	}

	public ~this()
	{
		deleteShader();
	}

	/**
	 * Sets the shader source effectivly creating it
	 */
	public void setSource(string source, shaderStage stage)
	{
		assert(stage != shaderStage.invalid, "Must be a valid shader stage");

		deleteShader();
		m_id = glCreateShader(stage);
		auto ptr = source.ptr;
		glShaderSource(m_id, 1, &ptr, null);
		glCompileShader(m_id);

		GLint status;
		glGetShaderiv(m_id, GL_COMPILE_STATUS, &status);
		if(status == false)
		{
			GLint infoLogLength;
			glGetShaderiv(m_id, GL_INFO_LOG_LENGTH, &infoLogLength);
			GLchar strInfoLog[] = new GLchar[infoLogLength + 1];
			glGetShaderInfoLog(m_id, infoLogLength, null, strInfoLog.ptr);
			string errorMsg = strInfoLog.idup;
			glDeleteShader(m_id);
			m_id = 0;
			throw new Exception("Failed to compile shader:" ~ errorMsg);
		}

		created = true;
	}

	/**
	 * Deletes the contents of the shader
	 */
	public void deleteShader()
	{
		if(created) glDeleteShader(m_id);
		created = false;
		m_stage = shaderStage.invalid;
		m_id = 0;
	}

	/**
	 * Returns the shader id to be used with openGl
	 */
	@property public GLuint shaderID()
	{
		return m_id;
	}

	/**
	 * Returns true if the shader can be used
	 */
	@property public bool valid(){return created;}
}

struct shaderProgram
{
	private bool created = false;
	private GLuint id = 0;
	private shaderUniform[string] uniforms;


	public this(shader[] shaders ...)
	{
		setShaders(shaders);
	}

	public ~this()
	{
		deleteProgram();
	}

	/**
	 * Links all the shaders into a shader program
	 */
	public void setShaders(shader[] shaders ...)
	{
		deleteProgram();

		id = glCreateProgram();

		foreach(shader s; shaders)
		{
			glAttachShader(id, s.m_id);
		}

		glLinkProgram(id);

		GLint status;
		glGetProgramiv(id, GL_LINK_STATUS, &status);
		if(status == GL_FALSE)
		{
			GLint infoLogLength;
			glGetProgramiv(id, GL_INFO_LOG_LENGTH, &infoLogLength);

			GLchar strInfoLog[] = new GLchar[infoLogLength + 1];
			glGetProgramInfoLog(id, infoLogLength, null, strInfoLog.ptr);
			string errorMsg = strInfoLog.idup;
			glDeleteProgram(id);
			id = 0;
			throw new Exception("Failed to link shader program:" ~ errorMsg);

		}

		foreach(shader s; shaders)
		{
			glDetachShader(id, s.m_id);
		}

		created = true;
	}

	/**
	 * Deletes shader program
	 */
	public void deleteProgram()
	{
		if(created)
		{
			glDeleteProgram(id);
		}
		created = false;
		id = 0;
	}

	/**
	 * Returns true if the shader program can be used
	 */
	@property public bool valid()
	{
		return created;
	}

	/**
	 * Returns the program id to be used with OpenGl
	 */
	@property public GLuint programID()
	{
		return id;
	}

	private void getUniforms()
	{
		import std.stdio;
		GLint numUniforms = 0;
		glGetProgramInterfaceiv(id, GL_UNIFORM, GL_ACTIVE_RESOURCES, &numUniforms);

		writeln("Uniform Count:", numUniforms);

		const GLenum properties[4] = [GL_BLOCK_INDEX, GL_TYPE, GL_NAME_LENGTH, GL_LOCATION];
		for(int unif = 0; unif < numUniforms; unif++)
		{
			GLint values[4];
			glGetProgramResourceiv(id, GL_UNIFORM, unif, 4, properties.ptr, 4, null, values.ptr);

			//writeln("GL_BLOCK_INDEX\t", values[0]);
			//writeln("GL_TYPE\t\t", values[1]);
			//writeln("GL_NAME_LENGTH\t", values[2]);
			//writeln("GL_LOCATION\t", values[3]);

			//writeln("Type:", toTypeInfo(values[1]));

			//Skip any uniforms that are in a block.
			if(values[0] != -1) continue;

			char[] nameData = new char[values[2]];
			glGetProgramResourceName(id, GL_UNIFORM, unif, nameData.length, null, nameData.ptr);
			//writeln(nameData);
		}
	}



}

private struct shaderUniform
{
	TypeInfo type;

}

private TypeInfo toTypeInfo(GLint gl_type)
{
	import math.matrix;
	import graphics.Texture;

	switch(gl_type)
	{
		case GL_FLOAT: 				return typeid(float);
		case GL_FLOAT_VEC2:			return typeid(vec2);
		case GL_FLOAT_VEC3:			return typeid(vec3);
		case GL_FLOAT_VEC4:			return typeid(vec4);
		
		case GL_DOUBLE:				return typeid(double);
		case GL_DOUBLE_VEC2:		return typeid(dvec2);
		case GL_DOUBLE_VEC3:		return typeid(dvec3);
		case GL_DOUBLE_VEC4:		return typeid(dvec4);
		
		case GL_INT: 				return typeid(int);
		case GL_INT_VEC2:			return typeid(ivec2);
		case GL_INT_VEC3:			return typeid(ivec3);
		case GL_INT_VEC4:			return typeid(ivec4);
		
		case GL_UNSIGNED_INT: 		return typeid(uint);
		case GL_UNSIGNED_INT_VEC2:	return typeid(uvec2);
		case GL_UNSIGNED_INT_VEC3:	return typeid(uvec3);
		case GL_UNSIGNED_INT_VEC4:	return typeid(uvec4);
		
		case GL_BOOL: 				return typeid(bool);
		case GL_BOOL_VEC2:			return typeid(bvec2);
		case GL_BOOL_VEC3:			return typeid(bvec3);
		case GL_BOOL_VEC4:			return typeid(bvec4);
		
		case GL_FLOAT_MAT2:			return typeid(mat2);
		case GL_FLOAT_MAT3:			return typeid(mat3);
		case GL_FLOAT_MAT4:			return typeid(mat4);
		case GL_FLOAT_MAT2x3:		return typeid(matrix!(2,3,float));
		case GL_FLOAT_MAT2x4:		return typeid(matrix!(2,4,float));
		case GL_FLOAT_MAT3x2:		return typeid(matrix!(3,2,float));
		case GL_FLOAT_MAT3x4:		return typeid(matrix!(3,4,float));
		case GL_FLOAT_MAT4x2:		return typeid(matrix!(4,2,float));
		case GL_FLOAT_MAT4x3:		return typeid(matrix!(4,3,float));

		case GL_DOUBLE_MAT2:		return typeid(dmat2);
		case GL_DOUBLE_MAT3:		return typeid(dmat3);
		case GL_DOUBLE_MAT4:		return typeid(dmat4);
		case GL_DOUBLE_MAT2x3:		return typeid(matrix!(2,3,double));
		case GL_DOUBLE_MAT2x4:		return typeid(matrix!(2,4,double));
		case GL_DOUBLE_MAT3x2:		return typeid(matrix!(3,2,double));
		case GL_DOUBLE_MAT3x4:		return typeid(matrix!(3,4,double));
		case GL_DOUBLE_MAT4x2:		return typeid(matrix!(4,2,double));
		case GL_DOUBLE_MAT4x3:		return typeid(matrix!(4,3,double));
		
		case GL_SAMPLER_2D:			return typeid(Texture);

		// TODO: Add more smapler types

		default:					throw new Exception("Invalid or unsuported type identifier");
	}
}