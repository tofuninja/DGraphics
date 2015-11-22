module graphics.gui.textbox;

import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;
import std.datetime;
import graphics.font;

// TODO multi line
// TODO click to move bar
// TODO highlight
// TODO copy, paste, cut
// TODO shift+arows to hightlight
// TODO delete key

class Textbox : div
{
	private bool showLine = false;
	public int insertLoc = 0;
	private SysTime lastBlink;
	private bool ignoreFalse = false;

	public dstring value = "";
	public bool border = true;
	public float defaultHeight = 0;
	public Color hintColor;

	mixin(customStyleMixin(`
			hintColor = defaultHintColor(textcolor);
			bounds.size.y = defaultHeight;
		`));

	public Color defaultHintColor(Color f)
	{
		auto v = f.to!vec4;
		v = v + vec4(0.4f,0.4f,0.4f,0);
		return v.to!Color;
	}
	
	this()
	{
		canClick = true;
		canFocus = true;
		cursor = Game.SimpleCursors.i_bar;
	}

	override protected void initProc() {
		super.initProc;
		lastBlink = Clock.currTime;
		auto font = getGraphics().getFont();
		defaultHeight = (font.ascent - font.descent + 4);
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
		else g.drawString(value, p, textcolor);

		if(showLine)
		{
			vec2 locateChar(int index)
			{
				int i = 0;
				vec2 r = vec2(0,0);
				foreach(LayoutPos g; font.textLayout(value, vec2(0,0)))
				{
					if(i == index) return g.loc;
					i++;
					r = g.loc + g.glyph.advance;
				}
				return r;
			}

			auto lp = p + locateChar(insertLoc);
			auto start = lp + vec2(0, -font.ascent);
			auto end = lp + vec2(0, -font.descent);
			g.drawLine(start, end, textcolor);
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

	override protected void clickProc(vec2 loc, mouseButton btn, bool down)
	{
		auto font = getGraphics().getFont();
		if(!down || btn != mouseButton.MOUSE_LEFT) return;
		float dist = 9999;
		uint index = 0;
		uint i = 0;
		vec2 r = vec2(0,0);
		foreach(LayoutPos g; font.textLayout(value, vec2(2, font.ascent + 2)))
		{
			auto d = (loc - g.loc).length;
			if(d < dist) {
				dist = d;
				index = i;
			}
			i++;
			r = g.loc + g.glyph.advance;
		}
		auto d = (loc - r).length;
		if(d < dist) index = i;

		insertLoc = index;
		showLine = true;
		lastBlink = Clock.currTime;
		invalidate;
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
		if(k == key.DELETE && insertLoc < value.length)
		{
			value = value[0 .. insertLoc] ~ value[insertLoc+1 .. $];
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

