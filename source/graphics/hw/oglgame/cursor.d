module graphics.hw.oglgame.cursor;
 
import derelict.glfw3.glfw3;
import graphics.hw.structs : hwCursorCreateInfo;
import graphics.hw.enums;
import graphics.color;
import math.matrix;

version(Windows) {
	import core.sys.windows.windows;

	struct glfw_cursor_layout{
		void* next;
		HCURSOR handle;
	}

	private bool makeWindowsCursor(HICON icon, ref cursorRef cursor) { 
		
		auto cursor_h = LoadCursor(null, cast(LPCTSTR)icon);
		auto succeed = cursor_h != null;
		if(succeed) {
			// Create a dummy glfw cursor, get the HCURSOR from it, delete it and replace it with my own, definitly a hack
			GLFWimage noCurs;
			noCurs.width  = 1;
			noCurs.height = 1;
			ubyte[4] data = [255,255,255,0];
			noCurs.pixels = data.ptr;
			GLFWcursor* c = glfwCreateCursor(&noCurs, 0,0);
			auto p = cast(glfw_cursor_layout*)c;
			DestroyCursor(p.handle);
			p.handle = cursor_h;
			cursor.obj = c;
		} 
		//else {
		//    mixin dump!("GetLastError()");
		//}
		return succeed; 
	}

} else version(linux) {
	static assert(false); // TODO

} else {
	static assert(false);
}


private cursorRef[hwSimpleCursor.count] simple;
public cursorRef getSimpleCursor(hwSimpleCursor cursor) {
	pragma(inline, true);
	return simple[cursor];
}

public struct cursorRef {
	package GLFWcursor* obj;
}

public cursorRef createCursor(hwCursorCreateInfo info) @nogc
{
	assert(info.pixels.length == info.size.x*info.size.y);
	GLFWimage curs;
	curs.width  = info.size.x;
	curs.height = info.size.y;
	curs.pixels = cast(ubyte*)(info.pixels.ptr);
	auto obj = glfwCreateCursor(&curs, info.hotspot.x, info.hotspot.y);
	return cursorRef(obj);
}

public void destroyCursor(ref cursorRef obj) {
	glfwDestroyCursor(obj.obj);
	obj.obj = null;
}

package void initCursors() {
	simple[hwSimpleCursor.arrow].obj 			= glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
	simple[hwSimpleCursor.i_bar].obj 			= glfwCreateStandardCursor(GLFW_IBEAM_CURSOR);
	simple[hwSimpleCursor.cross_hair].obj 	= glfwCreateStandardCursor(GLFW_CROSSHAIR_CURSOR);
	simple[hwSimpleCursor.hand].obj 			= glfwCreateStandardCursor(GLFW_HAND_CURSOR);
	simple[hwSimpleCursor.size_h].obj 		= glfwCreateStandardCursor(GLFW_HRESIZE_CURSOR);
	simple[hwSimpleCursor.size_v].obj 		= glfwCreateStandardCursor(GLFW_VRESIZE_CURSOR);

	// Creates a blank cursor 
	GLFWimage noCurs;
	noCurs.width  = 1;
	noCurs.height = 1;
	ubyte[4] data = [255,255,255,0];
	noCurs.pixels = data.ptr;
	simple[hwSimpleCursor.no_cursor].obj = glfwCreateCursor(&noCurs, 0,0);

	simple[hwSimpleCursor.hourglass].obj			= simple[hwSimpleCursor.arrow].obj;
	simple[hwSimpleCursor.arrow_and_hourglass].obj	= simple[hwSimpleCursor.arrow].obj;
	simple[hwSimpleCursor.arrow_and_question].obj	= simple[hwSimpleCursor.arrow].obj;
	simple[hwSimpleCursor.slash_circle].obj			= simple[hwSimpleCursor.arrow].obj;
	simple[hwSimpleCursor.size_all].obj				= simple[hwSimpleCursor.arrow].obj;
	simple[hwSimpleCursor.size_forward_arrow].obj	= simple[hwSimpleCursor.arrow].obj;
	simple[hwSimpleCursor.size_back_arrow].obj		= simple[hwSimpleCursor.arrow].obj;

	version(Windows) {
		makeWindowsCursor(IDC_WAIT,			simple[hwSimpleCursor.hourglass]);
		makeWindowsCursor(IDC_APPSTARTING,	simple[hwSimpleCursor.arrow_and_hourglass]);
		makeWindowsCursor(IDC_HELP,			simple[hwSimpleCursor.arrow_and_question]);
		makeWindowsCursor(IDC_NO,			simple[hwSimpleCursor.slash_circle]);
		makeWindowsCursor(IDC_SIZEALL,		simple[hwSimpleCursor.size_all]);
		makeWindowsCursor(IDC_SIZENESW,		simple[hwSimpleCursor.size_forward_arrow]);
		makeWindowsCursor(IDC_SIZENWSE,		simple[hwSimpleCursor.size_back_arrow]);
	} else version(linux) {
		// TODO
		static assert(false);
	}
}