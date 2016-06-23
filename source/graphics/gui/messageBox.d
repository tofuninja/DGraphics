module graphics.gui.messageBox;

import graphics.hw;
import graphics.gui.div;

import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

import graphics.gui.scrollbox;
import graphics.gui.label;
import graphics.gui.base;
import graphics.gui.window;

/// Opens a window with the message in it, blocks untill the message box is closed
public void msgbox(T...)(T args) {
	import std.format;
	import std.array;
	import std.traits;
	import std.range;
	auto w = appender!(dstring)();
	foreach (arg; args) {
		alias A = typeof(arg);
		static if (isAggregateType!A || is(A == enum)) {
			std.format.formattedWrite(&w, "%s", arg);
		} else static if (isSomeString!A) {
			import std.range : put;
			put(w, arg);
		} else static if (isIntegral!A) {
			import std.conv : toTextRange;
			toTextRange(arg, &w);
		} else static if (isBoolean!A) {
			put(w, arg ? "true" : "false");
		} else static if (isSomeChar!A) {
			import std.range : put;
			put(w, arg);
		} else {
			import std.format : formattedWrite;
			// Most general case
			std.format.formattedWrite(&w, "%s", arg);
		}
	}
	
	auto win = new Window();
	win.fillFirst = true;
	win.bounds.size = vec2(300,200);
	win.text = "Message Box";
	auto sb = new Scrollbox();
	auto l = new Label();
	l.text = w.data;
	l.bounds.loc = vec2(4,4);
	sb.border = false;
	sb.addDiv(l);
	win.addDiv(sb);
	win.waitOnClose();
}
