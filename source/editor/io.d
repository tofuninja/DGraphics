module editor.io;
import editor.ui;
import graphics.gui;
import std.stdio;

Console editor_con = null;

void writeln(T...)(T args) {
	if(editor_con is null) std.stdio.writeln(args);
	else editor_con.writeln(args);
}

void write(T...)(T args) {
	if(editor_con is null) std.stdio.write(args);
	else editor_con.write(args);
}

