module graphics.gui.textbox;

import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;
import std.datetime;

class Textbox : div
{
	private bool showLine = false;
	private int insertLoc = 0;
	private SysTime lastBlink;
	private bool ignoreFalse = false;


	public dstring value = "";
	public bool border = true;
	public float defaultHeight = 0;
	public Color hintColor;

	enum styleMember[] style = super.style ~ [styleMember("hintColor", "t.hintColor = t.defaultHintColor(this.getStylizedProperty!\"foreground\")")];

	public Color defaultHintColor(Color f)
	{
		auto v = f.to!vec4;
		v = v + vec4(0.4f,0.4f,0.4f,0);
		return v.to!Color;
	}

	// TODO multi line
	// TODO click to move bar
	// TODO highlight
	// TODO copy, paste, cut
	// TODO shift+arows to hightlight
	// TODO delete key
	
	this()
	{
		canClick = true;
		canFocus = true;
	}

	override protected void initProc() {
		super.initProc;
		lastBlink = Clock.currTime;
		auto font = getGraphics().getFont();
		bounds.size.y = defaultHeight = (font.ascent - font.descent + 4);
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {

		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto font = g.getFont();
		g.drawRectangle(renderBounds, background);
		if(border)
		{
			Color darker;
			{
				auto v = background.to!vec4;
				v = v - vec4(0.1f,0.1f,0.1f,0);
				darker = v.to!Color;
			}
			
			Color lighter;
			{
				auto v = background.to!vec4;
				v = v + vec4(0.1f,0.1f,0.1f,0);
				lighter = v.to!Color;
			}

			auto v1 = renderBounds.loc;
			auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
			auto v3 = renderBounds.loc + vec2(0, rbm1.y);
			auto v4 = renderBounds.loc + rbm1;

			g.drawLine(v1, v2, darker,1);
			g.drawLine(v1, v3, darker,1);
			g.drawLine(v3, v4, lighter,1);
			g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
		}

		//auto tb =  font.measureString(text);
		vec2 p = renderBounds.loc + vec2(2, font.ascent + 2);//renderBounds.alignIn(tb, "left-center");
		if(value == "") g.drawString(text, p, hintColor); 
		else g.drawString(value, p, foreground);

		if(showLine)
		{
			auto lp = p + font.locateChar(value, insertLoc);
			auto start = lp + vec2(0, -font.ascent);
			auto end = lp + vec2(0, -font.descent);
			g.drawLine(start, end, foreground);
		}
	}

	override protected void thinkProc() {
		auto prev = showLine;

		if(hasFocus)
		{
			auto now = Clock.currTime;
			if((now - lastBlink).split().msecs > 500)
			{
				showLine = !showLine;
				lastBlink = now;
			}
		}
		else showLine = false;
		if(showLine != prev) invalidate();
	}

	override protected void keyProc(key k,keyModifier mods,bool down) {
		import std.stdio;
		if(down)
		{
			ignoreFalse = true;
		}
		else if(ignoreFalse)
		{
			ignoreFalse = false;
			return;
		}

		if(k == key.LEFT && insertLoc > 0) 
		{
			insertLoc--;
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate;
			return;
		}
		if(k == key.RIGHT && insertLoc < value.length) {

			insertLoc++;
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate;
			return;
		}
		if(k == key.BACKSPACE && insertLoc > 0)
		{
			value = value[0 .. insertLoc-1] ~ value[insertLoc .. $];
			insertLoc--;
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate();
		}
		if(k == key.TAB)
		{
			charProc('\t');
		}
	}

	override protected void charProc(dchar c) {
		if(insertLoc < 0) insertLoc = 0;
		if(insertLoc >= value.length) insertLoc = value.length;

		value = value[0 .. insertLoc] ~ c ~ value[insertLoc .. $];
		insertLoc++;
		showLine = true;
		lastBlink = Clock.currTime;
		invalidate();
	}
}


dchar convertKeyToChar(key k, bool shift)
{
	if(k >= key.A && k <= key.Z)
	{
		dchar dif = cast(dchar)(k-key.A);
		if(shift) return 'A' + dif;
		else return 'a' + dif;
	}

	if(k >= key.NUM_0 && k <= key.NUM_9)
	{
		dchar dif = cast(dchar)(k-key.NUM_0);
		if(!shift) return '0' + dif;

		switch(dif)
		{
			case 0: return ')';
			case 1: return '!';
			case 2: return '@';
			case 3: return '#';
			case 4: return '$';
			case 5: return '%';
			case 6: return '^';
			case 7: return '&';
			case 8: return '*';
			case 9: return '(';
			default: return 0;
		}
	}

	if(shift)
	{
		switch(k)
		{
			case key.SPACE: return ' ';
			case key.APOSTROPHE: return '\'';
			case key.COMMA: return ',';
			case key.MINUS: return '-';
			case key.PERIOD: return '.';
			case key.SLASH: return '/';
			case key.SEMICOLON: return ';';
			case key.EQUAL: return '=';
			case key.LEFT_BRACKET: return '[';
			case key.BACKSLASH: return '\\';
			case key.RIGHT_BRACKET: return ']';
			case key.GRAVE_ACCENT: return '`';
			case key.TAB: return '\t';
			default: return 0;
		}
	}
	else
	{
		switch(k)
		{
			case key.SPACE: return ' ';
			case key.APOSTROPHE: return '\"';
			case key.COMMA: return '<';
			case key.MINUS: return '_';
			case key.PERIOD: return '>';
			case key.SLASH: return '?';
			case key.SEMICOLON: return ':';
			case key.EQUAL: return '+';
			case key.LEFT_BRACKET: return '{';
			case key.BACKSLASH: return '|';
			case key.RIGHT_BRACKET: return '}';
			case key.GRAVE_ACCENT: return '~';
			case key.TAB: return '\t';
			default: return 0;
		}
	}
}