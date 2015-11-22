module graphics.hw.oglgame.state;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.renderlist;
import graphics.hw.oglgame.cursor;
import math.matrix;
import util.event;
import derelict.glfw3.glfw3;
import derelict.freeimage.freeimage;
import derelict.freetype.ft;
import derelict.opengl3.gl3;
import derelict.assimp3.assimp;
import std.datetime;


public gameStateInfo state;
public Event!(key, keyModifier, bool) onKey;
public Event!(dchar) onChar;
public Event!(vec2) onMouseMove;
public Event!(vec2, mouseButton, bool) onMouseClick;
public Event!(vec2) onWindowSize;
public Event!(int) onScroll;

package renderStateInfo curRenderState;
package GLenum primMode 	= GL_TRIANGLES;
package GLenum glindexSize 	= GL_UNSIGNED_INT;
package uint uniformAlignment;
package uint indexByteSize 	= 4;
package uint indexOffset 	= 0;
package GLFWwindow* window 	= null;
package int frame = 0;
package SysTime lastTime;
package float fps = 0;
package uint totalFrames = 0;
package FT_Library ftlibrary;
package SysTime double_click_timer;
package bool oglg_inited = false;
package shared bool libs_loaded = false;

private enum OPENGL_DEBUG = false;


 
version(Windows)
{
	package enum glfw_dll 	= "glfw3.dll";
	package enum fi_dll 	= "Freeimage.dll";
	package enum ft_dll 	= "freetype.dll";
	package enum assimp_dll	= "assimp.dll";
}
else version(linux)
{
	static assert(false); // TODO Not testsed
	package enum glfw_dll 	= "libglfw3.so";
	package enum fi_dll 	= "libfreeimage.so";
	package enum ft_dll 	= "libfreetype.so";
	package enum assimp_dll	= "libassimp.so";
}
else
{
	static assert(false);
}

static ~this()
{
	deInit();
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
	initCursors();
	initPrivateState();
	initPublicState();
	oglg_inited = true;
}

public void deInit()
{
	import std.stdio;
	import std.concurrency;
	import derelict.opengl3.gl;
	if(!oglg_inited) return;
	glfwDestroyWindow(window);
	//DerelictASSIMP3.unload();
	//DerelictFT.unload();
	//DerelictFI.unload();
	//DerelictGLFW3.unload();
	//DerelictGL3.unload();
	//DerelictGL.unload();
}

public renderStateInfo renderState()
{
	return curRenderState;
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

	if(!libs_loaded)
	{
		DerelictGL3.load();
		DerelictGLFW3.load(["./libs/" ~ glfw_dll]);
		DerelictFI.load(["./libs/" ~ fi_dll]);
		DerelictFT.load(["./libs/" ~ ft_dll]);
		DerelictASSIMP3.load(["./libs/" ~ assimp_dll]);
		libs_loaded = true;
	}

	// set free image error handeler
	FreeImage_SetOutputMessage(&freeImgErrorHandler);

	
	// Init free type
	{
		import graphics.font;
		auto error = FT_Init_FreeType( &ftlibrary);
		if ( error )
		{
			import std.conv;
			throw new Exception("Freetype faild to init: " ~ error.to!string);
		}
		Font.ftlibrary = ftlibrary;
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
	//import derelict.opengl3.gl;

	glfwWindowHint(GLFW_RESIZABLE, info.resizeable?GL_TRUE:GL_FALSE);
	glfwWindowHint(GLFW_DECORATED, info.boarder?GL_TRUE:GL_FALSE);
	glfwWindowHint(GLFW_VISIBLE, info.show?GL_TRUE:GL_FALSE);
	auto win = glfwCreateWindow(info.size.x,info.size.y, info.title.ptr, info.fullscreen?(glfwGetPrimaryMonitor()):null, null);
	if (!win) return;
	glfwMakeContextCurrent(win);
	DerelictGL3.reload();
	window = win;
	
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
	state.uniformAlignment = uniformAlignment;
	state.shouldClose = false;

	import math.geo.rectangle;
	int w,h;
	glfwGetFramebufferSize(window, &w, &h);
	state.mainViewport = iRectangle(0,0,w,h);
}

/**
 * Init private game state not visable to the outside
 */
private void initPrivateState()
{
	with(curRenderState)
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
			uniformAlignment = 1;
		}
		else 
		{
			uniformAlignment = ualign;
		}
		lastTime = Clock.currTime;
		double_click_timer = Clock.currTime;
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
		FT_Library_Version(ftlibrary, &maj, &min, &pat);
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
		import std.conv;
		state.mouseButtons[button] = (action == GLFW_PRESS);

		if(action == GLFW_PRESS && button == GLFW_MOUSE_BUTTON_LEFT)
		{
			if(Clock.currTime - double_click_timer < state.doubleClick)
			{
				onMouseClick(state.mousePos, mouseButton.MOUSE_DOUBLE, true);
				return;
			}
			double_click_timer = Clock.currTime;
		}

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
		glfwGetFramebufferSize(window, &w, &h);
		state.mainViewport = iRectangle(0,0,w,h);
		onWindowSize(vec2(w,h));
	}
	catch(Exception e) {}
}

private extern(C) void oglg_keyCallBack(GLFWwindow* window, int keycode, int scancode, int action, int mods) nothrow
{
	if(keycode >= 0 && keycode <= GLFW_KEY_LAST)
	{
		state.keyboard[keycode] = (action == GLFW_PRESS || action == GLFW_REPEAT);
		try
		{
			onKey(cast(key)keycode,cast(keyModifier)mods, action == GLFW_PRESS || action == GLFW_REPEAT);
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