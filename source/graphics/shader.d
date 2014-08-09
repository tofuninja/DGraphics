module graphics.shader;

import derelict.opengl3.gl3;

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

	public void printUniforms()
	{
		import std.stdio;
		GLint numUniforms = 0;
		glGetProgramInterfaceiv(id, GL_UNIFORM, GL_ACTIVE_RESOURCES, &numUniforms);
		const GLenum properties[4] = [GL_BLOCK_INDEX, GL_TYPE, GL_NAME_LENGTH, GL_LOCATION];
		for(int unif = 0; unif < numUniforms; unif++)
		{
			GLint values[4];
			glGetProgramResourceiv(id, GL_UNIFORM, unif, 4, properties.ptr, 4, null, values.ptr);
			
			//Skip any uniforms that are in a block.
			if(properties[0] != -1)
				continue;

			char[] nameData = new char[properties[2]];
			glGetProgramResourceName(id, GL_UNIFORM, unif, nameData.length, null, nameData.ptr);
			writeln(nameData.idup);
		}
	}
}