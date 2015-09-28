module graphics.hw.oglgame.state;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
import math.matrix;
import util.event;

import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;
import derelict.assimp3.assimp;



package oglgStateObj oglgState;
public gameStateInfo state;
public Event!(key, keyModifier, bool) onKey;
public Event!(dchar) onChar;
public Event!(vec2) onMouseMove;
public Event!(vec2, mouseButton, bool) onMouseClick;
public Event!(vec2) onWindowSize;
public Event!(int) onScroll;


private enum OPENGL_DEBUG = false;

 
version(Windows)
{
	enum glfw_dll 	= "glfw3.dll";
	enum fi_dll 	= "Freeimage.dll";
	enum ft_dll 	= "freetype.dll";
	enum assimp_dll	= "assimp.dll";
}
else version(linux)
{
	static assert(false); // TODO Not testsed
	enum glfw_dll 	= "libglfw3.so";
	enum fi_dll 	= "libfreeimage.so";
	enum ft_dll 	= "libfreetype.so";
	enum assimp_dll	= "libassimp.so";
}
else
{
	static assert(false);
}

/**
 * Keeps track of all oglg state
 */
package struct oglgStateObj
{
	import std.datetime;
	renderStateInfo curRenderState;
	GLenum primMode 	= GL_TRIANGLES;
	GLenum indexSize 	= GL_UNSIGNED_INT;
	uint uniformAlignment;
	uint indexByteSize 	= 4;
	uint indexOffset 	= 0;
	GLFWwindow* window 	= null;
	int frame = 0;
	SysTime lastTime;
	float fps = 0;
	uint totalFrames = 0;
	FT_Library ftlibrary;
}

/**
 * Init the game
 * 
 * For offscreen rendering, set show to false
 * Will simply make an inviable window for offscreen rendering
 */
public void init(gameInitInfo info)
{
	initLibs();
	intiWindow(info);
	initPrivateState();
	initPublicState();
}

public void deInit()
{
}

public renderStateInfo renderState()
{
	return oglgState.curRenderState;
}


/**
 * Init need libs for the game
 * 
 * GLFW for an opengl context/window
 * FreeImage to load and save images
 * FreeType to load and manip fonts
 * 
 */
private void initLibs()
{
	import graphics.image;
	import derelict.opengl3.gl;

	DerelictGL.load();
	DerelictGL3.load();
	DerelictGLFW3.load(["./libs/" ~ glfw_dll]);
	DerelictFI.load(["./libs/" ~ fi_dll]);
	DerelictFT.load(["./libs/" ~ ft_dll]);
	DerelictASSIMP3.load(["./libs/" ~ assimp_dll]);

	// set free image error handeler
	FreeImage_SetOutputMessage(&freeImgErrorHandler);

	
	// Init free type
	{
		import graphics.font;
		auto error = FT_Init_FreeType( &oglgState.ftlibrary);
		if ( error )
		{
			import std.conv;
			throw new Exception("Freetype faild to init: " ~ error.to!string);
		}
		Font.ftlibrary = oglgState.ftlibrary;
	}
	
	// Start GLFW3
	if (!glfwInit()) return;
}

/**
 * Init the glfw window
 * Set the init info.show = false for offscreen rendering
 * 
 */
private void intiWindow(gameInitInfo info)
{
	import derelict.opengl3.gl;

	glfwWindowHint(GLFW_RESIZABLE, info.resizeable?GL_TRUE:GL_FALSE);
	glfwWindowHint(GLFW_DECORATED, info.boarder?GL_TRUE:GL_FALSE);
	glfwWindowHint(GLFW_VISIBLE, info.show?GL_TRUE:GL_FALSE);
	auto window = glfwCreateWindow(info.size.x,info.size.y, info.title.ptr, info.fullscreen?(glfwGetPrimaryMonitor()):null, null);
	if (!window) return;
	glfwMakeContextCurrent(window);
	DerelictGL3.reload();
	DerelictGL.reload();
	oglgState.window = window;
	
	// Call backs
	{
		glfwSetWindowSizeCallback(window, &oglg_window_size_callback);
		glfwSetKeyCallback(window, &oglg_keyCallBack);
		glfwSetMouseButtonCallback(window, &oglg_mouse_button);
		glfwSetCursorPosCallback(window, &oglg_mouse_move_callback);
		glfwSetCharCallback(window, &oglg_character_callback);
		glfwSetScrollCallback(window, &oglg_mouse_scroll);
	}

	// Enforce required gl
	assert(DerelictGL3.loadedVersion >= GLVersion.GL45, "Min Gl version is 4.5");

	static if(OPENGL_DEBUG)
	{
		glEnable(GL_DEBUG_OUTPUT);
		glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, null, GL_TRUE);
		GLDEBUGPROC dbg = &olgl_errorCallBack;
		glDebugMessageCallback(dbg, cast(const(void)*)null);
	}
}

/**
 * Init the public game state visable oustside of the ogl game
 */
private void initPublicState()
{
	state.initialized = true;
	state.keyboard[] = false;
	state.uniformAlignment = oglgState.uniformAlignment;
	state.shouldClose = false;

	import math.geo.rectangle;
	int w,h;
	glfwGetFramebufferSize(oglgState.window, &w, &h);
	state.mainViewport = iRectangle(0,0,w,h);
}

/**
 * Init private game state not visable to the outside
 */
private void initPrivateState()
{
	with(oglgState.curRenderState)
	{
		import math.geo.rectangle : iRectangle;
		mode 			= renderMode.triangles;
		vao.id 			= 0;
		shader.id 		= 0;
		fbo.id 			= 0;
		depthTest		= false;
		depthFunction 	= cmpFunc.less;
		viewport 		= iRectangle(ivec2(0,0), ivec2(1,1));
	}
	
	// Set up state info
	{
		import std.datetime;
		int ualign = 0;
		glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &ualign);
		if(ualign <= 0)
		{
			oglgState.uniformAlignment = 1;
		}
		else 
		{
			oglgState.uniformAlignment = ualign;
		}
		oglgState.lastTime = Clock.currTime;
	}
	
	glViewport(0, 0, 1, 1);
}

/**
 * Print lib version numbers
 */
public void printLibVersions(alias writeln)()
{
	import std.conv;
	// print ogl version
	{
		writeln("OpenGl Version: ", DerelictGL3.loadedVersion);
	}
	// print glfw version
	{
		int maj, min, pat;
		glfwGetVersion (&maj, &min, &pat);
		writeln("GLFW Version: ", maj, ".", min, ".", pat);
	}
	// print free image version
	{
		auto fiv = FreeImage_GetVersion();
		int z;
		for(z = 0; fiv[z] != 0; z++) {}
		auto ver = fiv[0 .. z].to!string;
		writeln("FreeImage Version: ", ver);
	}
	// print freetype version
	{
		int maj, min, pat;
		FT_Library_Version(oglgState.ftlibrary, &maj, &min, &pat);
		writeln("FreeType Version: ", maj, ".", min, ".", pat);
	}
}






/*
 * GLFW Call Backs
 */
private extern(C) void oglg_mouse_scroll(GLFWwindow* window, double x, double y) nothrow
{
	try{
		//import std.stdio;
		//writeln("scroll ", x, " ", y);
		onScroll(cast(int)y);
	}
	catch(Exception e) {}
}

private extern(C) void oglg_mouse_button(GLFWwindow* window, int button, int action, int mods) nothrow
{
	try{
		state.mouseButtons[button] = (action == GLFW_PRESS);
		onMouseClick(state.mousePos, cast(mouseButton)button, action == GLFW_PRESS);
	}
	catch(Exception e) {}
}

private extern(C) void oglg_mouse_move_callback(GLFWwindow* window, double x, double y) nothrow
{
	try{
		auto v = vec2(cast(float)x, cast(float)y);
		state.mousePos = v;
		onMouseMove(v);
	}
	catch(Exception e) {}
}

private extern(C) void oglg_window_size_callback(GLFWwindow* window, int width, int height) nothrow
{
	import std.stdio;
	import math.geo.rectangle;
	try{
		int w,h;
		glfwGetFramebufferSize(oglgState.window, &w, &h);
		state.mainViewport = iRectangle(0,0,w,h);
		onWindowSize(vec2(w,h));
	}
	catch(Exception e) {}
}

private extern(C) void oglg_keyCallBack(GLFWwindow* window, int keycode, int scancode, int action, int mods) nothrow
{
	if(keycode >= 0 && keycode <= GLFW_KEY_LAST)
	{
		state.keyboard[keycode] = (action == GLFW_PRESS);
		try
		{
			onKey(cast(key)keycode,cast(keyModifier)mods, action == GLFW_PRESS);
		}
		catch(Exception e) {}
	}
}

private extern(C) void oglg_character_callback(GLFWwindow* window, uint codepoint) nothrow
{
	try
	{
		dchar c = codepoint;
		onChar(c);
	}
	catch(Exception e) {}
}

private extern(Windows) void olgl_errorCallBack(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(GLchar)* message, void* userParam) nothrow
{
	import std.stdio;
	try
	{
		writeln("------GL ERROR CALLBACK------");
		write("Error Type: ");
		switch (type) {
			case GL_DEBUG_TYPE_ERROR:
				writeln("Error");
				break;
			case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
				writeln("Deprecated Behavior");
				break;
			case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
				writeln("Undefined Behavior");
				break;
			case GL_DEBUG_TYPE_PORTABILITY:
				writeln("Portability");
				break;
			case GL_DEBUG_TYPE_PERFORMANCE:
				writeln("Performance");
				break;
			case GL_DEBUG_TYPE_OTHER:
			default:
				writeln("Other");
				break;
		}

		write("Source: ");
		switch(source)
		{
			case GL_DEBUG_SOURCE_API:
				writeln("API");
				break;
			case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
				writeln("Window System");
				break;
			case GL_DEBUG_SOURCE_SHADER_COMPILER:
				writeln("Compiler");
				break;
			case GL_DEBUG_SOURCE_THIRD_PARTY:
				writeln("Thrird Party");
				break;
			case GL_DEBUG_SOURCE_APPLICATION:
				writeln("Application");
				break;
			case GL_DEBUG_SOURCE_OTHER:
			default:
				writeln("Other");
				break;
		}

		write("Severity: ");
		switch (severity){
			case GL_DEBUG_SEVERITY_LOW:
				writeln("Low");
				break;
			case GL_DEBUG_SEVERITY_MEDIUM:
				writeln("Medium");
				break;
			case GL_DEBUG_SEVERITY_HIGH:
				writeln("High");
				break;
			case GL_DEBUG_SEVERITY_NOTIFICATION:
				writeln("Notification");
				break;
			default:
				writeln("Other");
				break;
		}
		writeln("Id: ", id);
		writeln("Message:\n", message[0 .. length]);
	}
	catch(Exception e)
	{

	}
}