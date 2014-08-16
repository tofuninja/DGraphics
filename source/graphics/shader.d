module graphics.shader;

import derelict.opengl3.gl3;
import std.variant;

/**
 * OpenGl graphics pipe line stages
 */
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

/**
 * Represents an openGl shader
 */
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

/**
 * Represents an openGl shader program
 */
struct shaderProgram
{
	private bool created = false;
	private GLuint id = 0;
	public shaderUniform[string] uniforms;

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

		// Get info about shader
		getUniforms();

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

	/** 
	 * Grab info about each uniform, requires GL4.3 or ARB_PROGRAM_INTERFACE_QUERY
	 */
	private void getUniforms()
	{
		//import std.stdio;
		import graphics.Texture;

		// Empty out uniforms array
		foreach (key; uniforms.keys) 
		{
			uniforms.remove(key);
		}

		// Get current program's uniform count
		GLint numUniforms = 0;
		glGetProgramInterfaceiv(id, GL_UNIFORM, GL_ACTIVE_RESOURCES, &numUniforms);


		const GLenum properties[4] = [GL_BLOCK_INDEX, GL_TYPE, GL_NAME_LENGTH, GL_LOCATION];
		for(int unif = 0; unif < numUniforms; unif++)
		{
			GLint values[4];
			glGetProgramResourceiv(id, GL_UNIFORM, unif, 4, properties.ptr, 4, null, values.ptr);

			//Skip any uniforms that are in a block.
			if(values[0] != -1) continue;

			char[] uniformName = new char[values[2]]; 	// uniform name
			TypeInfo type = toTypeInfo(values[1]);		// uniform type
			GLint loc = values[3];						// uniform location
			int tag = 0; 								// uniform tag to add any extrea info to the uniform

			glGetProgramResourceName(id, GL_UNIFORM, unif, uniformName.length, null, uniformName.ptr);
			uniformName.length--; // We dont need the terminating zero, this is D!
			uniforms[uniformName.idup] = shaderUniform(type, loc, tag);
		}
	}

	// TODO: Detect uniform blocks

	public void setUniform(T)(string name, T value)
	{
		import math.matrix;
		import graphics.Texture;
		import graphics.GraphicsState;

		shaderUniform* uni = (name in uniforms);
		if(uni == null) return; // posible for this to not be an error if the uniform is not active so we will just treat it like nothing happened
		enforce(typeid(T) == uni.type, "Type of value does not match uniform type");

		// Not sure but this might need to change depending on how I set up my mats... 
		enum transposeMats = false;

		// upload uniform value into opengl based on type
		static if(is(T == float)) 	glProgramUniform1f(id, uni.location, value);
		else if(is(T == vec2)) 		glProgramUniform2fv(id, 6i.location, 1, value.m_data.ptr);
		else if(is(T == vec3)) 		glProgramUniform3fv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == vec4)) 		glProgramUniform4fv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == double)) 	glProgramUniform1d(id, uni.location, value);
		else if(is(T == dvec2)) 	glProgramUniform2dv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == dvec3)) 	glProgramUniform3dv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == dvec4)) 	glProgramUniform4dv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == int)) 		glProgramUniform1i(id, uni.location, value);
		else if(is(T == ivec2)) 	glProgramUniform2iv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == ivec3)) 	glProgramUniform3iv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == ivec4))		glProgramUniform4iv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == uint))		glProgramUniform1ui(id, uni.location, value);
		else if(is(T == uvec2))		glProgramUniform2uiv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == uvec3))		glProgramUniform3uiv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == uvec4))		glProgramUniform4uiv(id, uni.location, 1, value.m_data.ptr);
		else if(is(T == bool))		glProgramUniform1i(id, uni.location, cast(int)value);
		else if(is(T == bvec2))		glProgramUniform2i(id, uni.location, cast(int)value.x,cast(int)value.y);
		else if(is(T == bvec3))		glProgramUniform3i(id, uni.location, cast(int)value.x, cast(int)value.y, cast(int)value.z);
		else if(is(T == bvec4))		glProgramUniform4i(id, uni.location, cast(int)value.x, cast(int)value.y, cast(int)value.z, cast(int)value.w);
		else if(is(T == mat2))		glProgramUniformMatrix2fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == mat3))		glProgramUniformMatrix3fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == mat4))		glProgramUniformMatrix4fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(2,3,float))) glProgramUniformMatrix2x3fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(2,4,float))) glProgramUniformMatrix2x4fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(3,2,float))) glProgramUniformMatrix3x2fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(3,4,float))) glProgramUniformMatrix3x4fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(4,2,float))) glProgramUniformMatrix4x2fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(4,3,float))) glProgramUniformMatrix4x3fv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == dmat2)) 	glProgramUniformMatrix2dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == dmat3)) 	glProgramUniformMatrix3dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == dmat4))		glProgramUniformMatrix4dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(2,3,double))) glProgramUniformMatrix2x3dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(2,4,double))) glProgramUniformMatrix2x4dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(3,2,double))) glProgramUniformMatrix3x2dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(3,4,double))) glProgramUniformMatrix3x4dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(4,2,double))) glProgramUniformMatrix4x2dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == matrix!(4,3,double))) glProgramUniformMatrix4x3dv(id, uni.location, 1, transposeMats, m_data.ptr);
		else if(is(T == TextureImageUnit)) glProgramUniform1i(id, uni.location, value.location);	
		else
		{
			static assert(false,"Unsuported Type " ~ T.stringof);
		}
	}
}

/**
 * Represents the location and type information of a shader uniform
 */
public struct shaderUniform
{
	import math.matrix;
	import graphics.Texture;

	TypeInfo type;
	GLint location;
	int tag;
}

/**
 * Converts the type enum returned from openGl program interface query to the type info of the corisponding D type
 */
private TypeInfo toTypeInfo(GLint gl_type)
{
	import math.matrix;
	import graphics.Texture;
	import graphics.GraphicsState;

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
		
		case GL_SAMPLER_2D:			return typeid(TextureImageUnit);

		// TODO: Add more smapler types

		default:					throw new Exception("Invalid or unsuported type identifier");
	}
}