module util.fileDialogue;

string fileLoadDialogue(string fileTypes, string fileTypeName)
{
	import core.sys.windows.windows;
	import std.string;
	import std.exception;
	
	OPENFILENAMEA file;
	
	file.lStructSize = OPENFILENAMEA.sizeof;
	file.hwndOwner = null;
	file.lpstrFilter = (fileTypeName ~ "\0" ~ fileTypes ~ "\0\0").toStringz;
	file.lpstrCustomFilter = null;
	file.nFilterIndex = 1;
	char[1000] buffer;
	buffer[0] = 0;
	file.lpstrFile = buffer.ptr;
	file.nMaxFile = 1000;
	file.nMaxFileTitle = 0;
	file.lpstrInitialDir = null;
	file.lpstrTitle = null;
	file.Flags = 0;

	enforce(GetOpenFileNameA(&file) != 0, "Failded to open file");
	
	int z;
	for(z = 0; buffer[z] != 0 && z < 1000; z++) {}
	string filename = buffer[0 .. z].idup;
	return filename;
}

string fileSaveDialogue(string fileTypes, string fileTypeName)
{
	import core.sys.windows.windows;
	import std.string;
	import std.exception;

	OPENFILENAMEA file;

	file.lStructSize = OPENFILENAMEA.sizeof;
	file.hwndOwner = null;
	file.lpstrFilter = (fileTypeName ~ "\0" ~ fileTypes ~ "\0\0").toStringz;
	file.lpstrCustomFilter = null;
	file.nFilterIndex = 1;
	char[1000] buffer;
	buffer[0] = 0;
	file.lpstrFile = buffer.ptr;
	file.nMaxFile = 1000;
	file.nMaxFileTitle = 0;
	file.lpstrInitialDir = null;
	file.lpstrTitle = null;
	file.Flags = 0;
	
	enforce(GetSaveFileNameA(&file) != 0, "Failded to open file");

	int z;
	for(z = 0; buffer[z] != 0 && z < 1000; z++) {}
	string filename = buffer[0 .. z].idup;
	return filename;
}