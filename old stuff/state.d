module graphics.hw.state;
// Global Graphics State

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.opengl3.gl;
import derelict.freeimage.freeimage;
import gui.panel;
import std.stdio; 
import math.matrix;
import util.debugger;



// TODO after conversion to new rendering system in game.d, trash this!
// State
private int texUnitCount;
public TextureImageUnit[] TextureBindPoints;
public GLFWwindow* window;
private enum aspect = 0.5625;
public enum windowW = 1280;
public enum windowH = windowW*aspect;
public BasePanel basePan;
public string baseDirectory;


// Info Console 
// TODO this really needs to be redone
enum infowindowW = windowW/3.2;
enum infowindowH = windowH/1.35;
private enum infoLineCount = cast(int)(infowindowH/10 - 4);
public int infoTime = 0;
private string[infoLineCount] infoLines;
private int infoBot = 0;
public label infoBox;

/**
 * Init Graphics State after openGl has been inited
 */
public void initializeGraphicsState()
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
		// TODO either make linux support better or just remove it
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

	// TODO have windowing settings passed in 
	// Create a windowed mode window and its OpenGL context 
	//glfwWindowHint(GLFW_RESIZABLE, 0);
	//glfwWindowHint(GLFW_FLOATING, GL_TRUE);
	//glfwWindowHint(GLFW_DECORATED, GL_FALSE);
	window = glfwCreateWindow(cast(int)windowW, cast(int)windowH, "Hello World",   glfwGetPrimaryMonitor(), null);
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
	int maxTexSize = -1;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTexSize);
	writeln("Texture max size: ", maxTexSize);

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
		basePan = new BasePanel(cast(int)windowW,cast(int)windowH);

		// Info Console
		infoLines[] = "";
		infoBox = new label(vec2(windowW/2 - infowindowW/2,windowH/2 - infowindowH/2), vec2(infowindowW,infowindowH));
		infoBox.setVisable(false);
	}


	// Set up inital opengl settings
	glRasterPos2f(-1,1);
	glPixelZoom(1,-1);
	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glClearColor(0.7f,0.7f,1,1);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	checkGlError();
}

/**
 * The number of Texture Image Units avalible for binding
 */
public int TextureUnitCount() { return texUnitCount; }

public void writeinfoln(T...)(T args)
{
	import std.algorithm;
	string s = writelnstring(args);
	foreach(string p; splitter(s, '\n'))
	{
		infoLines[infoBot] = p;
		infoBot++;
		infoBot%=infoLineCount;
	}
	
	infoBox.setVisable(true);
	infoTime = 100;
	
	string text = "";
	for(int i = infoLineCount; i >= 1; i--)
	{
		int id = (infoBot-i);
		if(id < 0) id+=infoLineCount; 
		if(infoLines[id] !is null)
			text ~= infoLines[id]~"\n";
	}
	
	infoBox.setText(text);
	glClearColor(0.6f,0.8f,1.0f,1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	infoBox.composit();
	glfwSwapBuffers(window);
	checkGlError();
}


private string writelnstring(T...)(T args)
{
	import std.format;
	import std.array;
	import std.traits;
	
	auto w = appender!string();
	foreach (arg; args)
	{
		alias A = typeof(arg);
		static if (isAggregateType!A || is(A == enum))
		{
			std.format.formattedWrite(w, "%s", arg);
		}
		else static if (isSomeString!A)
		{
			import std.range : put;
			put(w, arg);
		}
		else static if (isIntegral!A)
		{
			import std.conv : toTextRange;
			toTextRange(arg, w);
		}
		else static if (isBoolean!A)
		{
			put(w, arg ? "true" : "false");
		}
		else static if (isSomeChar!A)
		{
			import std.range : put;
			put(w, arg);
		}
		else
		{
			import std.format : formattedWrite;
			// Most general case
			std.format.formattedWrite(w, "%s", arg);
		}
	}
	return w.data;
}

/**
 * Represents a bind point for Textures
 */
public struct TextureImageUnit
{
	import graphics.hw.texture;
	private int loc = 0;
	private GLenum prevType; 
	public Texture boundTex;
	
	private this(int bindLoc)
	{
		loc = bindLoc;
		boundTex = null;
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
		boundTex = tex;
		glActiveTexture(GL_TEXTURE0 + loc);
		glBindTexture(tex.oglTextureType, tex.id);
		prevType = tex.oglTextureType;
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(tex.oglTextureType, 0);
	}
	
	public void unbind()
	{
		glActiveTexture(GL_TEXTURE0 + loc);
		glBindTexture(prevType, 0);
		boundTex = null;
	}
}