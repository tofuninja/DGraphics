module graphics.gui.messageBox;

import graphics.hw.game;
import graphics.gui.div;

import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

import graphics.gui.scrollbox;
import graphics.gui.label;
import graphics.gui.base;
import std.concurrency;


mixin loadUIString!(`
Base msgbox_base
{
	fontSize = 15;
	Scrollbox msg_holder
	{
		background = RGB(240,240,240);
		foreground = RGB(130, 130, 130);
		bounds = fill;
		border = false;
		
		Label msg
		{
			textcolor = RGB(0,0,0);
			bounds.loc = vec2(4,4);
		}
	}
}
`);

/// Opens a window with the message in it, blocks untill the message box is closed
public void msgbox(T...)(T args)
{
	import std.format;
	import std.array;
	import std.traits;
	import std.range.primitives;
	auto w = appender!(dstring)();
	foreach (arg; args)
	{
		alias A = typeof(arg);
		static if (isAggregateType!A || is(A == enum))
		{
			std.format.formattedWrite(&w, "%s", arg);
		}
		else static if (isSomeString!A)
		{
			import std.range.primitives : put;
			put(w, arg);
		}
		else static if (isIntegral!A)
		{
			import std.conv : toTextRange;
			toTextRange(arg, &w);
		}
		else static if (isBoolean!A)
		{
			put(w, arg ? "true" : "false");
		}
		else static if (isSomeChar!A)
		{
			import std.range.primitives : put;
			put(w, arg);
		}
		else
		{
			import std.format : formattedWrite;
			// Most general case
			std.format.formattedWrite(&w, "%s", arg);
		}
	}

	auto childTid = spawn(&msg_thread, w.data, thisTid);
	auto wasSuccessful = receiveOnly!(bool);
    assert(wasSuccessful);
}

private void msg_thread(dstring text, Tid ownerTid)
{
	// Make window
	{
		gameInitInfo info;
		info.fullscreen = false;
		info.size = ivec2(300,100);
		info.title = "Message Box";
		Game.init(info);
	}
	
	auto box = startUI!msgbox_base();
	
	box.msg_holder.msg.text = text;
	box.invalidate();
	box.run();
	send(ownerTid, true);
}