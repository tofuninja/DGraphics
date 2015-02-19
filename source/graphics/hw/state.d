module graphics.hw.state;
// Global Graphics State

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.opengl3.gl;
import derelict.freeimage.freeimage;
import gui.panel;
import std.stdio; 


// State
private int texUnitCount;
public TextureImageUnit[] TextureBindPoints;
public GLFWwindow* window;
public enum windowW = 900;
public enum windowH = 500;
public BasePanel basePan;
public string baseDirectory;


/**
 * Init Graphics State after openGl has been inited
 */
public void initializeGraphicsState(string[] args)
{
	/* Initialize the librarys */
	DerelictGL.load();
	DerelictGL3.load();

	version(Windows)
	{
		DerelictGLFW3.load(["./libs/glfw3.dll"]);
		DerelictFI.load(["./libs/Freeimage.dll"]);
	}
	version(linux)
	{
		DerelictGLFW3.load(["./libs/libglfw3.so"]);
		DerelictFI.load(["./libs/libfreeimage.so"]);
	}

	// set free image error handeler
	{
		import graphics.image;
		FreeImage_SetOutputMessage(&freeImgErrorHandler);
	}


	// Grab current directory
	{
		import std.file;
		baseDirectory = getcwd();
	}


	// Start GLFW3
	if (!glfwInit()) return;


	// Create a windowed mode window and its OpenGL context 
	glfwWindowHint(GLFW_RESIZABLE, 0);
	window = glfwCreateWindow(windowW, windowH, "Hello World", null, null);
	//scope(exit) glfwTerminate();
	if (!window) return;
	glfwMakeContextCurrent(window);
	DerelictGL3.reload();
	DerelictGL.reload();


	debug
	{
		import std.conv;

		// print ogl version
		writeln("OpenGl Version: ", DerelictGL3.loadedVersion);

		// print free image version
		auto fiv = FreeImage_GetVersion();
		int z;
		for(z = 0; fiv[z] != 0; z++) {}
		auto ver = fiv[0 .. z].to!string;
		writeln("FreeImage Version: ", ver);
	}


	// Enforce required gl
	{
		import std.exception;
		enforce(DerelictGL3.loadedVersion >= GLVersion.GL40, "Min Gl version is 4.0");
		enforce(ARB_program_interface_query, "Requires either ARB_program_interface_query or Gl version 4.3");
		enforce(ARB_separate_shader_objects, "Requires either ARB_separate_shader_objects or Gl version 4.1");
	}


	// Set up texture units 
	glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &texUnitCount);
	TextureBindPoints = new TextureImageUnit[texUnitCount];
	foreach(int i; 0 .. texUnitCount)
	{
		TextureBindPoints[i] = TextureImageUnit(i);
	}
	debug writeln("Texture Unit Count: ", texUnitCount);


	// Load all shaders
	{
		import resources.glslManager;
		compileShaders();
	}


	// Set up gui
	{
		import gui.keyboard;
		import gui.panel;
		import gui.font;
		setUpKeyboard();
		initFont();
		basePan = new BasePanel(windowW,windowH);
	}
}

/**
 * The number of Texture Image Units avalible for binding
 */
public int TextureUnitCount() { return texUnitCount; }

/**
 * Represents a bind point for Textures
 */
public struct TextureImageUnit
{
	import graphics.hw.texture;
	private int loc = 0;
	private GLenum prevType; 

	private this(int bindLoc)
	{
		loc = bindLoc;
	}

	/**
	 * Location of bind point
	 */
	@property public int location() { return loc; }

	/**
	 * Bind texture to this texture bind point
	 */
	public void bind(Texture tex)
	{
		glActiveTexture(GL_TEXTURE0 + loc);
		glBindTexture(tex.oglTextureType, tex.id);
		prevType = tex.oglTextureType;
	}

	public void unbind()
	{
		glActiveTexture(GL_TEXTURE0 + loc);
		glBindTexture(prevType, 0);
	}
}

