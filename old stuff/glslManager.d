module resources.glslManager;

import graphics.hw.shader;

// TODO this is shit, need something better



// For now, just stacicly include the glsl code into the program
// Maybe this could be changed later to load at run time but I dont really see a benifit
public alias simpleShader = importShader!"simpleShader";
public alias softShadow = importShader!"soft_shadows";
public alias depthReflect = importShader!"depthReflect";
public alias checker = importShader!"checker";
public alias simple_depthimage = importShader!"simple_depthimage";
public alias simple_texture = importShader!"simple_texture";
public alias terain_shader = importShader!"terain";
public alias terain_wire_shader = importShader!"terainWire";
public alias tree_shader = importShader!"tree";
public alias water_fade = importShader!"waterFade";
public alias cloud_plane_shader = importShader!"cloud";


 

















/**
 * Compile all shader program being managed by the glslManager
 */
public void compileShaders()
{
	import std.traits;
	foreach(string s; __traits(allMembers, resources.glslManager))
	{
		static if(__traits(compiles, __traits(getMember, resources.glslManager, s).getShaderProgram()))
		{
			__traits(getMember, resources.glslManager, s).getShaderProgram();
		}
	}
}



/** 
 * Loads the different files of the shader with text imports
 * All text imports are located in the views folder
 */
template importShader(string name)
{
	public ShaderProgram program;

	// Vertex Shader Source
	static if(__traits(compiles, import(name ~ ".vertex.glsl")))
	{
		public enum vertex = import(name ~ ".vertex.glsl")[3..$];
		public enum hasVertex = true;
	}
	else
	{
		public enum vertex = "NOT AVLIBLE";
		public enum hasVertex = false;
	}

	// Fragment Shader Source
	static if(__traits(compiles, import(name ~ ".fragment.glsl")))
	{
		public enum fragment = import(name ~ ".fragment.glsl")[3..$];
		public enum hasFragment = true;
	}
	else
	{
		public enum fragment = "NOT AVLIBLE";
		public enum hasFragment = false;
	}

	// Geometry Shader Source
	static if(__traits(compiles, import(name ~ ".geometry.glsl")))
	{
		public enum geometry = import(name ~ ".geometry.glsl")[3..$];
		public enum hasGeometry = true;
	}
	else
	{
		public enum geometry = "NOT AVLIBLE";
		public enum hasGeometry = false;
	}

	// Tessalation Control Shader Source
	static if(__traits(compiles, import(name ~ ".tessControl.glsl")))
	{
		public enum tessControl = import(name ~ ".tessControl.glsl")[3..$];
		public enum hasTessControl = true;
	}
	else
	{
		public enum tessControl = "NOT AVLIBLE";
		public enum hasTessControl = false;
	}

	// Tessalation Evaluation Shader Source
	static if(__traits(compiles, import(name ~ ".tessEvaluation.glsl")))
	{
		public enum tessEvaluation = import(name ~ ".tessEvaluation.glsl")[3..$];
		public enum hasTessEvaluation = true;
	}
	else
	{
		public enum tessEvaluation = "NOT AVLIBLE";
		public enum hasTessEvaluation = false;
	}

	// Compute Shader Source
	static if(__traits(compiles, import(name ~ ".compute.glsl")))
	{
		public enum compute = import(name ~ ".compute.glsl")[3..$];
		public enum hasCompute = true;
	}
	else
	{
		public enum compute = "NOT AVLIBLE";
		public enum hasCompute = false;
	}

	/**
	 * Generates a ShaderProgram from the glsl files
	 */
	public void getShaderProgram()
	{
		Shader[10] shaders;
		int count = 0;

		static if(hasVertex)
		{
			shaders[count] = Shader(vertex, ShaderStage.vertex);
			count++;
		}

		static if(hasFragment)
		{
			shaders[count] = Shader(fragment, ShaderStage.fragment);
			count++;
		}

		static if(hasGeometry)
		{
			shaders[count] = Shader(geometry, ShaderStage.geometry);
			count++;
		}

		static if(hasTessControl)
		{
			shaders[count] = Shader(tessControl, ShaderStage.tessControl);
			count++;
		}

		static if(hasTessEvaluation)
		{
			shaders[count] = Shader(tessEvaluation, ShaderStage.tessEvaluation);
			count++;
		}

		static if(hasCompute)
		{
			shaders[count] = Shader(compute, ShaderStage.compute);
			count++;
		}


		import std.stdio;
		writeln("Load Shader: ", name);

		program = new ShaderProgram(shaders[0 .. count]);
	}
}