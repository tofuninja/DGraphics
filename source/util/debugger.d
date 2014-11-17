module util.debugger;

void breakPoint()
{
	import std.stdio;
	writeln("Break Point Hit: Press Any Key To Continue"); 
	getchar();
}

void checkGlError(string f = __FILE__, int l = __LINE__) 
{
	import std.conv;
	import derelict.opengl3.gl3;
	import std.stdio;
	GLenum err = glGetError();
	
	while(err != GL_NO_ERROR) 
	{
		string error;
		
		switch(err) 
		{
			case GL_INVALID_OPERATION:      error="INVALID_OPERATION";      break;
			case GL_INVALID_ENUM:           error="INVALID_ENUM";           break;
			case GL_INVALID_VALUE:          error="INVALID_VALUE";          break;
			case GL_OUT_OF_MEMORY:          error="OUT_OF_MEMORY";          break;
			case GL_INVALID_FRAMEBUFFER_OPERATION:  error="INVALID_FRAMEBUFFER_OPERATION";  break;
			default: error = "UnknownError " ~ err.to!string;
		}
		
		writeln("GLERROR: ", error);
		writeln(f, ": ", l);
		err=glGetError();
	}
}