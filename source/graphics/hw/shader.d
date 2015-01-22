module graphics.hw.shader;

import derelict.opengl3.gl3;
import std.variant;
import graphics.hw.buffer;



// Todo: Try and turn shaders and buffers and textures back into structs, remove there destructors and make destruction of them explicit? Dont want to rely on GC but it might not matter for them 


/**
 * OpenGl graphics pipe line stages
 */
public enum ShaderStage
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
public struct Shader
{
	public ShaderStage stage = ShaderStage.invalid;
	public GLuint id = 0;

	public this(string source, ShaderStage stage)
	{
		setSource(source, stage);
	}

	/**
	 * Sets the shader source effectivly creating it
	 */
	public void setSource(string source, ShaderStage stage)
	{
		assert(stage != ShaderStage.invalid, "Must be a valid shader stage");

		destroy();

		id = glCreateShader(stage);
		auto ptr = source.ptr;
		glShaderSource(id, 1, &ptr, null);
		glCompileShader(id);

		GLint status;
		glGetShaderiv(id, GL_COMPILE_STATUS, &status);
		if(status == false)
		{
			GLint infoLogLength;
			glGetShaderiv(id, GL_INFO_LOG_LENGTH, &infoLogLength);
			GLchar strInfoLog[] = new GLchar[infoLogLength + 1];
			glGetShaderInfoLog(id, infoLogLength, null, strInfoLog.ptr);
			string errorMsg = strInfoLog.idup;
			glDeleteShader(id);
			id = 0;
			throw new Exception("Failed to compile shader:" ~ errorMsg);
		}
	}

	/**
	 * Deletes the contents of the shader
	 */
	public void destroy()
	{
		if(id != 0) glDeleteShader(id);
		stage = ShaderStage.invalid;
		id = 0;
	}

}

/**
 * Represents an openGl shader program
 */
public struct ShaderProgram
{
	public GLuint id = 0;
	public ShaderUniformInfo[string] uniforms;
	public ShaderInputInfo[string] inputs;

	public this(Shader[] shaders ...)
	{
		setShaders(shaders);
	}

	/**
	 * Links all the shaders into a shader program
	 */
	public void setShaders(Shader[] shaders ...)
	{
		destroy();

		id = glCreateProgram();

		foreach(Shader s; shaders)
		{
			glAttachShader(id, s.id);
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

		foreach(Shader s; shaders)
		{
			glDetachShader(id, s.id);
		}

		// Get info about shader
		getUniforms();
		getInputs();
	}

	/**
	 * Deletes shader program
	 */
	public void destroy()
	{
		if(id != 0)
		{
			glDeleteProgram(id);
		}
		id = 0;
		uniforms = null;
		inputs = null;
	}

	/**
	 * Set the value of a uniform variable
	 */
	public void setUniform(T)(string name, T value)
	{
		import math.matrix;
		import graphics.hw.texture;
		import graphics.hw.state;
		import std.exception;

		ShaderUniformInfo* uni = (name in uniforms);
		if(uni == null) return; // posible for this to not be an error if the uniform is not active so we will just treat it like nothing happened
		enforce(typeid(T) == uni.type, "Type of value does not match uniform type");

		// Not sure but this might need to change depending on how I set up my mats... 
		enum transposeMats = false;

		// upload uniform value into opengl based on type
		static if(is(T == float)) 	glProgramUniform1f(id, uni.location, value);
		else static if(is(T == vec2)) 		glProgramUniform2fv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == vec3)) 		glProgramUniform3fv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == vec4)) 		glProgramUniform4fv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == double)) 	glProgramUniform1d(id, uni.location, value);
		else static if(is(T == dvec2)) 	glProgramUniform2dv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == dvec3)) 	glProgramUniform3dv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == dvec4)) 	glProgramUniform4dv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == int)) 		glProgramUniform1i(id, uni.location, value);
		else static if(is(T == ivec2)) 	glProgramUniform2iv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == ivec3)) 	glProgramUniform3iv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == ivec4))		glProgramUniform4iv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == uint))		glProgramUniform1ui(id, uni.location, value);
		else static if(is(T == uvec2))		glProgramUniform2uiv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == uvec3))		glProgramUniform3uiv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == uvec4))		glProgramUniform4uiv(id, uni.location, 1, value.m_data.ptr);
		else static if(is(T == bool))		glProgramUniform1i(id, uni.location, cast(int)value);
		else static if(is(T == bvec2))		glProgramUniform2i(id, uni.location, cast(int)value.x,cast(int)value.y);
		else static if(is(T == bvec3))		glProgramUniform3i(id, uni.location, cast(int)value.x, cast(int)value.y, cast(int)value.z);
		else static if(is(T == bvec4))		glProgramUniform4i(id, uni.location, cast(int)value.x, cast(int)value.y, cast(int)value.z, cast(int)value.w);
		else static if(is(T == mat2))		glProgramUniformMatrix2fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == mat3))		glProgramUniformMatrix3fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == mat4))		glProgramUniformMatrix4fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(2,3,float))) glProgramUniformMatrix2x3fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(2,4,float))) glProgramUniformMatrix2x4fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(3,2,float))) glProgramUniformMatrix3x2fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(3,4,float))) glProgramUniformMatrix3x4fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(4,2,float))) glProgramUniformMatrix4x2fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(4,3,float))) glProgramUniformMatrix4x3fv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == dmat2)) 	glProgramUniformMatrix2dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == dmat3)) 	glProgramUniformMatrix3dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == dmat4))		glProgramUniformMatrix4dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(2,3,double))) glProgramUniformMatrix2x3dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(2,4,double))) glProgramUniformMatrix2x4dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(3,2,double))) glProgramUniformMatrix3x2dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(3,4,double))) glProgramUniformMatrix3x4dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(4,2,double))) glProgramUniformMatrix4x2dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == matrix!(4,3,double))) glProgramUniformMatrix4x3dv(id, uni.location, 1, transposeMats, value.m_data.ptr);
		else static if(is(T == TextureImageUnit)) glProgramUniform1i(id, uni.location, value.location);	
		else
		{
			static assert(false,"Unsuported Type " ~ T.stringof);
		}
	}

	/** 
	 * Grab info about each uniform, requires GL4.3 or ARB_PROGRAM_INTERFACE_QUERY
	 */
	private void getUniforms()
	{
		// TODO: Detect uniform blocks
		
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
			uniforms[uniformName.idup] = ShaderUniformInfo(type, loc, tag);
		}
	}
	
	private void getInputs()
	{
		// Empty out uniforms array
		foreach (key; inputs.keys) 
		{
			inputs.remove(key);
		}
		
		GLint numIns = 0;
		glGetProgramInterfaceiv(id, GL_PROGRAM_INPUT, GL_ACTIVE_RESOURCES, &numIns);
		
		const GLenum properties[4] = [GL_TYPE, GL_NAME_LENGTH, GL_LOCATION, GL_ARRAY_SIZE];
		for(int input = 0; input < numIns; input++)
		{
			GLint values[4];
			glGetProgramResourceiv(id, GL_PROGRAM_INPUT, input, 4, properties.ptr, 4, null, values.ptr);
			
			char[] inputName = new char[values[1]]; 	// input name
			TypeInfo type = toTypeInfo(values[0]);		// input type
			GLint loc = values[2];						// input location
			GLint arraySize = values[3];				// input array size
			int tag = 0; 								// input tag to add any extrea info to the input
			
			glGetProgramResourceName(id, GL_PROGRAM_INPUT, input, inputName.length, null, inputName.ptr);
			inputName.length--; // We dont need the terminating zero, this is D!
			inputs[inputName.idup] = ShaderInputInfo(type, loc, arraySize, tag);
		}
		
	}

}

/**
 * Represents the location and type information of a shader uniform
 */
public struct ShaderUniformInfo
{
	TypeInfo type;
	GLint location;
	int tag;
}

/**
 * Represents the location and type information of a shader input
 */
public struct ShaderInputInfo
{
	TypeInfo type;
	GLint location;
	GLint arraySize;
	int tag;
}

/**
 * Represents a set of inputs to a shader
 */
public struct ShaderInput
{
	public ShaderProgram program;
	public GLuint id = 0;

	public this(ShaderProgram shaderProg)
	{
		setShaderProgram(shaderProg);
	}

	void destroy()
	{
		if(id != 0) glDeleteVertexArrays(1, &id);
		id = 0;
		program = ShaderProgram.init;
	}

	void setShaderProgram(ShaderProgram shaderProg)
	{
		destroy();
		program = shaderProg;
		glGenVertexArrays(1, &id);
	}

	public void draw(int start, int count)
	{
		import std.stdio;
		glUseProgram(program.id);
		glBindVertexArray(id);
		glDrawArrays(GL_TRIANGLES, start, count);
		glBindVertexArray(0);
		glUseProgram(0);
	}
	
	public void drawIndexed(int start, int count)
	{
		import std.stdio;
		glUseProgram(program.id);
		glBindVertexArray(id);
		glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_INT, cast(void*)(start*uint.sizeof));
		glBindVertexArray(0);
		glUseProgram(0);
	}

	public void attachIndexBuffer(IndexBuffer buf)
	{
		glBindVertexArray(id);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buf.id);
		glBindVertexArray(0);
	}

	public void attachBuffer(V : VertexBuffer!(T), T)(V vbo)
	{
		import std.traits;
		import std.stdio;

		glBindVertexArray(id);
		glBindBuffer(GL_ARRAY_BUFFER, vbo.id);

		static if(!vbo.isSingleAttrib)
		{
			int stride = T.sizeof;
			foreach(mem; __traits(allMembers, T))
			{
				ShaderInputInfo* input = (mem in prog.inputs);
				if(input != null)  // Posible for this to not be an error if the input is not active so we will just treat it like nothing happened
				{
					int offset = __traits(getMember, T, mem).offsetof;
					alias mem_T = typeof(__traits(getMember, T, mem));
					
					// TODO: handle arrays in attach buffer for shaders 

					attachAtrib!(mem_T)(input.location, stride, offset, input.type);
				}
			}
		}
		else
		{
			int stride = 0;
			ShaderInputInfo* input = (vbo.name in program.inputs);
			if(input != null)// Posible for this to not be an error if the input is not active so we will just treat it like nothing happened
			{
				int offset = 0;
				
				// TODO: handle arrays in attach buffer for shaders 
				
				attachAtrib!(T)(input.location, stride, offset, input.type);
			}
		}

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindVertexArray(0);
	}
	
	private void attachAtrib(T)(int index, int stride, int offset, TypeInfo destType)
	{
		import graphics.color;
		import math.matrix;
		glEnableVertexAttribArray(index);

		static if(is(T == Color))
		{
			alias DT = vec4;
		}
		else
		{
			alias DT = T;
		}

		if(typeid(DT) != destType) return;

		import std.stdio;

		static if(is(T == Color)) 			glVertexAttribPointer(index, 4, GL_BYTE, GL_TRUE, stride, cast(void*)offset);
		else static if(is(T == float)) 		glVertexAttribPointer(index, 1, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == vec2)) 		glVertexAttribPointer(index, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == vec3)) 		glVertexAttribPointer(index, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == vec4))		glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == int)) 		glVertexAttribPointer(index, 1, GL_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == ivec2)) 		glVertexAttribPointer(index, 2, GL_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == ivec3)) 		glVertexAttribPointer(index, 3, GL_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == ivec4))		glVertexAttribPointer(index, 4, GL_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == uint))		glVertexAttribPointer(index, 1, GL_UNSIGNED_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == uvec2))		glVertexAttribPointer(index, 2, GL_UNSIGNED_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == uvec3))		glVertexAttribPointer(index, 3, GL_UNSIGNED_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == uvec4))		glVertexAttribPointer(index, 4, GL_UNSIGNED_INT, GL_FALSE, stride, cast(void*)offset);
		else static if(is(T == mat2))
		{
			glVertexAttribPointer(index, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
			glVertexAttribPointer(index + 1, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)(offset + vec2.sizeof));
		}
		else static if(is(T == mat3))
		{
			glVertexAttribPointer(index, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
			glVertexAttribPointer(index + 1, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)(offset + vec3.sizeof));
			glVertexAttribPointer(index + 2, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)(offset + 2*vec3.sizeof));
		}
		else static if(is(T == mat4))
		{
			glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
			glVertexAttribPointer(index + 1, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)(offset + vec4.sizeof));
			glVertexAttribPointer(index + 2, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)(offset + 2*vec4.sizeof));
			glVertexAttribPointer(index + 3, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)(offset + 3*vec4.sizeof));
		}
		else
		{
			static assert(false,"Unsuported Type " ~ T.stringof);
		}
		//else if(is(T == matrix!(2,3,float))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(2,4,float))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(3,2,float))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(3,4,float))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);	// Not going to worry about these right now, dont really every see my self using them
		//else if(is(T == matrix!(4,2,float))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(4,3,float))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == dmat2)) 	glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == dmat3)) 	glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == dmat4))		glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(2,3,double))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(2,4,double))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(3,2,double))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(3,4,double))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(4,2,double))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == matrix!(4,3,double))) glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);


		//else if(is(T == bool))		glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset); 
		//else if(is(T == bvec2))		glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);		// Bool not supported right now because it would require conversions as far as I can tell
		//else if(is(T == bvec3))		glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == bvec4))		glVertexAttribPointer(index, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)offset);

		//else if(is(T == double)) 	glVertexAttribLPointer(index, 1, GL_DOUBLE, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == dvec2)) 	glVertexAttribLPointer(index, 2, GL_DOUBLE, GL_FALSE, stride, cast(void*)offset); 		// Deal with doubles later
		//else if(is(T == dvec3)) 	glVertexAttribLPointer(index, 3, GL_DOUBLE, GL_FALSE, stride, cast(void*)offset);
		//else if(is(T == dvec4)) 	glVertexAttribLPointer(index, 4, GL_DOUBLE, GL_FALSE, stride, cast(void*)offset);
		// TODO add rest of buffer attachment types
	}
}

/**
 * Converts the type enum returned from openGl program interface query to the type info of the corisponding D type
 */
private TypeInfo toTypeInfo(GLint gl_type)
{
	import math.matrix;
	import graphics.hw.texture;
	import graphics.hw.state;

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
		case GL_SAMPLER_2D_SHADOW:	return typeid(TextureImageUnit);

		// TODO: Add more smapler types

		default:					throw new Exception("Invalid or unsuported type identifier");
	}
}