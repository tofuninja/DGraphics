module gui.keyboard;

import derelict.glfw3.glfw3;
import graphics.GraphicsState;

public bool[GLFW_KEY_LAST + 1] keyState;

public void setUpKeyboard()
{
	import graphics.GraphicsState;
	glfwSetKeyCallback(window, &keyCallBack);
	glfwSetCharCallback(window, &charCallBack);
}

extern(C) void keyCallBack(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
{
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
		try
		{
			basePan.keyPress(key, scancode, action, mods);
		}
		catch(Exception){}
	}
}

extern(C) void charCallBack(GLFWwindow* window, uint c) nothrow
{
	try
	{
		dchar dc = cast(dchar)c;
		basePan.focus.charPress(dc);
	}
	catch(Exception){}
}