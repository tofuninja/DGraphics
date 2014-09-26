module gui.keyboard;

import derelict.glfw3.glfw3;

public bool[GLFW_KEY_LAST + 1] keyState;

public void setUpKeyboard()
{
	import graphics.GraphicsState;
	glfwSetKeyCallback(window, &keyCallBack);
}

extern(C) void keyCallBack(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
{
	try
	{
		import std.stdio;
		writeln(key);
	}
	catch(Exception){}
	if(key >= 0 && key <= GLFW_KEY_LAST)
	{
		if(action == GLFW_PRESS)
		{
			keyState[key] = true;
		}
		else if(action == GLFW_RELEASE)
		{
			keyState[key] = false;
		}
	}
}