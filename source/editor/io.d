module editor.io;
import editor.ui;
import graphics.gui;
import std.stdio;

void writeln(T...)(T args)
{
	if(editor_ui is null) std.stdio.writeln(args);
	else editor_ui.get!"console".writeln(args);
}

void write(T...)(T args)
{
	if(editor_ui is null) std.stdio.write(args);
	else editor_ui.get!"console".write(args);
}

