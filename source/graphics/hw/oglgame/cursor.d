module graphics.hw.oglgame.cursor;
 
import derelict.glfw3.glfw3;

// TODO custom cursors 

final abstract class SimpleCursors
{
	static:
	cursorRef arrow;
	cursorRef i_bar;
	cursorRef cross_hair;
	cursorRef hand;
	cursorRef h_size;
	cursorRef v_size;
}

public struct cursorRef 
{
	package GLFWcursor* obj;
}

package void initCursors()
{
	SimpleCursors.arrow.obj 		= glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
	SimpleCursors.i_bar.obj 		= glfwCreateStandardCursor(GLFW_IBEAM_CURSOR);
	SimpleCursors.cross_hair.obj 	= glfwCreateStandardCursor(GLFW_CROSSHAIR_CURSOR);
	SimpleCursors.hand.obj 			= glfwCreateStandardCursor(GLFW_HAND_CURSOR);
	SimpleCursors.h_size.obj 		= glfwCreateStandardCursor(GLFW_HRESIZE_CURSOR);
	SimpleCursors.v_size.obj 		= glfwCreateStandardCursor(GLFW_VRESIZE_CURSOR);
}