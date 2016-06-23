module graphics.hw.oglgame.state;

import graphics.hw.enums;
import graphics.hw.structs;
import graphics.hw.oglgame.cursor;
import math.matrix;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.datetime;

// TODO WINDOWING IS COMPLEATLY WRONG!
// I am really just lucky it is working how it is
// but the multi threding is wrong as fuck... 
// To fix it, I guess I will have to have some kind of window manager on the main thread and a thread per window
// most of the GLFW functions say they can only be called from the main thread
// Actually it can be simpler, I liked the idea of a thread per window, but its not needed, a windowRef and a setWindowCmd is enough... 
// ACTUALLY.... its even more complicated than that, glfw assigns each window a new context, so we would need to deal with multiple contexts as well.... 
// I am just going to give up on multi-windowing for now... Will make a divWindow for internal sub-windows and use that in the editor... 


package hwStateInfo state;
package hwICallback callbacks;
package hwRenderStateInfo curRenderState;
package GLenum primMode 		= GL_TRIANGLES;
package GLenum glhwIndexSize 	= GL_UNSIGNED_INT;
package uint uniformAlignment;
package uint indexByteSize 	= 4;
package uint indexOffset 	= 0;
package GLFWwindow* window 	= null;
package SysTime double_click_timer;
package bool oglg_inited = false;
package shared bool libs_loaded = false;

private enum OPENGL_DEBUG = false;
private shared bool oglgERROR = false;
private Exception oglgException;

package void oglgCheckError() @nogc
{
	pragma(inline, true);
	static if(OPENGL_DEBUG) {
		if(oglgERROR) {
			throw oglgException;
		}
	}
}


 
version(Windows) {
	package enum glfw_dll 	= "glfw3.dll";
} else version(linux) {
	static assert(false); // TODO Not testsed
	package enum glfw_dll 	= "libglfw3.so";
} else {
	static assert(false);
}

version(X86_64) {
	package enum lib_folder = "./libs/libs64/";
} else {
	package enum lib_folder = "./libs/";
}

static ~this() {
	deInit();
}

/**
 * Init the game
 * 
 * For offscreen rendering, set show to false
 * Will simply make an inviable window for offscreen rendering
 */
public void init(hwInitInfo info) {
	oglgException = new Exception("OGLG ERROR");
	initLibs();
	intiWindow(info);
	initCursors();
	initPrivateState();
	initPublicState();
	oglg_inited = true;
}

public void deInit() {
	import std.stdio;
	import std.concurrency;
	import derelict.opengl3.gl;
	if(!oglg_inited) return;
	glfwDestroyWindow(window);
	//DerelictGLFW3.unload();
	//DerelictGL3.unload();
	//DerelictGL.unload();
}

public hwRenderStateInfo currentRenderState() {
	pragma(inline, true);
	return curRenderState;
}

public hwStateInfo currentState() {
	pragma(inline, true);
	return state;
}

/**
 * Init needed libs for hw interaction
 */
private void initLibs() {
	if(!libs_loaded) {
		DerelictGL3.load();
		DerelictGLFW3.load([lib_folder ~ glfw_dll]);
		libs_loaded = true;
	}
	// Start GLFW3
	if(!glfwInit()) 
		throw new Exception("GLFW faild to init");
	oglgCheckError();
}

/**
 * Init the glfw window
 * Set the init info.show = false for offscreen rendering
 * 
 */
private void intiWindow(hwInitInfo info) {
	//import derelict.opengl3.gl;
	import std.string;

	glfwWindowHint(GLFW_RESIZABLE, info.resizeable?GL_TRUE:GL_FALSE);
	glfwWindowHint(GLFW_DECORATED, info.boarder?GL_TRUE:GL_FALSE);
	glfwWindowHint(GLFW_VISIBLE, info.show?GL_TRUE:GL_FALSE);
	state.visible = info.show;

	auto win = glfwCreateWindow(info.size.x,info.size.y, toStringz(info.title), info.fullscreen?(glfwGetPrimaryMonitor()):null, null);
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

	static if(OPENGL_DEBUG) {
		glEnable(GL_DEBUG_OUTPUT);
		glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, null, GL_TRUE);
		GLDEBUGPROC dbg = &olgl_errorCallBack;
		glDebugMessageCallback(dbg, cast(const(void)*)null);
	}

	oglgCheckError();
}

/**
 * Init the public game state visable oustside of the ogl game
 */
private void initPublicState() {
	state.initialized = true;
	state.keyboard[] = false;
	state.uniformAlignment = uniformAlignment;
	state.shouldClose = false;

	import math.geo.rectangle;
	int w,h;
	glfwGetFramebufferSize(window, &w, &h);
	state.mainViewport = iRectangle(0,0,w,h);
	oglgCheckError();
}

/**
 * Init private game state not visable to the outside
 */
private void initPrivateState() {
	with(curRenderState) {
		import math.geo.rectangle : iRectangle;
		mode 			= hwRenderMode.triangles;
		vao.id 			= 0;
		shader.id 		= 0;
		fbo.id 			= 0;
		depthTest		= false;
		depthFunction 	= hwCmpFunc.less;
		viewport 		= iRectangle(ivec2(0,0), ivec2(1,1));
	}
	
	// Set up state info
	{
		import std.datetime;
		int ualign = 0;
		glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &ualign);
		if(ualign <= 0) {
			uniformAlignment = 1;
		} else {
			uniformAlignment = ualign;
		}
		double_click_timer = Clock.currTime;
	}
	
	glViewport(0, 0, 1, 1);
	oglgCheckError();
}

string getVersionString() {
	import std.conv:to;
	string r = "";
	// print ogl version
	{
		r ~= "OpenGl Version: " ~ DerelictGL3.loadedVersion.to!string ~ "\n";
	}

	// print glfw version
	{
		int maj, min, pat;
		glfwGetVersion (&maj, &min, &pat);
		r ~= "GLFW Version: " ~ maj.to!string ~ "." ~ min.to!string ~ "." ~ pat.to!string;
	}
	oglgCheckError();
	return r;
}

public string getClipboard() {
	auto p = glfwGetClipboardString(window);
	if(p is null) return "";
	
	uint count;
	for(count = 0; p[count] != 0; count++) {}

	const(char)[] arr = p[0 .. count];
	return arr.idup;
}

public void setClipboard(string text) {
	import std.string;
	glfwSetClipboardString(window, toStringz(text));	
}






/*
 * GLFW Call Backs
 */
private extern(C) void oglg_mouse_scroll(GLFWwindow* window, double x, double y) nothrow
{
	try{
		//import std.stdio;
		//writeln("scroll ", x, " ", y);
		if(callbacks !is null) callbacks.onScroll(state.mousePos, cast(int)y);
	}
	catch(Exception e) {}
}

private extern(C) void oglg_mouse_button(GLFWwindow* window, int button, int action, int mods) nothrow
{
	try{
		import std.conv;
		state.mouseButtons[button] = (action == GLFW_PRESS);

		if(action == GLFW_PRESS && button == GLFW_MOUSE_BUTTON_LEFT) {
			if(Clock.currTime - double_click_timer < state.doubleClick) {
				if(callbacks !is null) callbacks.onMouseClick(state.mousePos, hwMouseButton.MOUSE_DOUBLE, true);
				return;
			}
			double_click_timer = Clock.currTime;
		}

		if(callbacks !is null) callbacks.onMouseClick(state.mousePos, cast(hwMouseButton)button, action == GLFW_PRESS);
	}
	catch(Exception e) {}
}

private extern(C) void oglg_mouse_move_callback(GLFWwindow* window, double x, double y) nothrow
{
	try{
		auto v = vec2(cast(float)x, cast(float)y);
		state.mousePos = v;
		if(callbacks !is null) callbacks.onMouseMove(v);
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
		if(callbacks !is null) callbacks.onWindowResize(vec2(w,h));
	}
	catch(Exception e) {}
}

private extern(C) void oglg_keyCallBack(GLFWwindow* window, int keycode, int scancode, int action, int mods) nothrow
{
	if(keycode >= 0 && keycode <= GLFW_KEY_LAST) {
		state.keyboard[keycode] = (action == GLFW_PRESS || action == GLFW_REPEAT);
		try
		{
			if(callbacks !is null) callbacks.onKey(cast(hwKey)keycode,cast(hwKeyModifier)mods, action == GLFW_PRESS || action == GLFW_REPEAT);
		}
		catch(Exception e) {}
	}
}

private extern(C) void oglg_character_callback(GLFWwindow* window, uint codepoint) nothrow
{
	try
	{
		dchar c = codepoint;
		if(callbacks !is null) callbacks.onChar(c);
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
				oglgERROR = true;
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
		switch(source) {
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
		switch (severity) {
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
	catch(Exception e) {

	}
}


