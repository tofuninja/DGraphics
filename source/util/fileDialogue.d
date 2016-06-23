module util.fileDialogue;

version(Windows) {
	pragma(lib, "Comdlg32.lib");
}

bool fileLoadDialogue(out string open_file, ExtensionFilter[] filters...) {
	open_file = "";
	version(Windows) {

		import core.sys.windows.windows;
		import std.string;
		import std.exception;

		OPENFILENAMEA file;

		file.lStructSize = OPENFILENAMEA.sizeof;
		file.hwndOwner = null;
		file.lpstrFilter = toFilterString(filters).ptr;
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

		if(GetOpenFileNameA(&file) == 0) return false;

		int z;
		for(z = 0; buffer[z] != 0 && z < 1000; z++) {}
		string filename = buffer[0 .. z].idup;
		open_file = filename;
		return true;
	} else {
		throw new Exception("Only Supported On Windows");
	}
}

bool fileSaveDialogue(out string open_file, ExtensionFilter[] filters...) {
	import std.file;
	open_file = "";

	// Make sure the CWD stays the same after the dialogue 
	string cwd = getcwd();
	scope(exit) chdir(cwd);

	version(Windows) {
		import core.sys.windows.windows;
		import std.string;
		import std.exception;

		OPENFILENAMEA file;

		file.lStructSize = OPENFILENAMEA.sizeof;
		file.hwndOwner = null;
		file.lpstrFilter = toFilterString(filters).ptr;
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

		if(GetSaveFileNameA(&file) == 0) return false;

		int z;
		for(z = 0; buffer[z] != 0 && z < 1000; z++) {}
		string filename = buffer[0 .. z].idup;
		open_file = filename;
		return true;
	} else {
		throw new Exception("Only Supported On Windows");
	}
}

struct ExtensionFilter
{
	string name;
	string filter;
}

private string toFilterString(ExtensionFilter[] filters) {
	string s;
	foreach(f; filters) {
		s ~= f.name ~ "\0" ~ f.filter ~ "\0";
	}
	s ~= "\0\0";
	return s;
}