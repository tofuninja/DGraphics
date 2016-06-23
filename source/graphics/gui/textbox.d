module graphics.gui.textbox;

import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
//import util.event;
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
	private bool clicked = false;

	private bool showLine = false;
	private SysTime lastBlink;
	private bool ignoreFalse = false;
	private int defaultHeight = 0;

	public dstring value = "";
	public bool border = true;
	public bool back = true;
	public bool allowEdit = true;

	public int insertLoc = 0;
	public int highlightStart = -1;
	
	this() {
		canClick = true;
		canFocus = true;
		cursor = hwGetSimpleCursor(hwSimpleCursor.i_bar);
	}

	protected void onChange() {}

	override protected void stylizeProc() {
		bounds.size.y = defaultHeight;
		fixInsert();
	}

	override protected void initProc() {
		super.initProc;
		lastBlink = Clock.currTime;
		auto font = getGraphics().getFont();
		defaultHeight = (font.ascent - font.descent + 4);
		bounds.size.y = defaultHeight;
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {

		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto font = g.getFont();
		fixInsert();

		if(back) {
			if(allowEdit)
				g.drawRectangle(renderBounds, style.lower);
			else
				g.drawRectangle(renderBounds, style.disabled);
		}

		if(border) {
			Color darker = style.border_shadow;
			Color lighter = style.border;

			auto v1 = renderBounds.loc;
			auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
			auto v3 = renderBounds.loc + vec2(0, rbm1.y);
			auto v4 = renderBounds.loc + rbm1;

			g.drawLine(v1, v2, darker,1);
			g.drawLine(v1, v3, darker,1);
			g.drawLine(v3, v4, lighter,1);
			g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
		}

		vec2 locateChar(int index) {
			int i = 0;
			vec2 r = vec2(0,0);
			foreach(LayoutPos g; font.textLayout(value, vec2(0,0))) {
				if(i == index) return g.loc;
				i++;
				if(g.glyph == null) r = g.loc;
				else r = g.loc + cast(vec2)g.glyph.advance;
			}
			return r;
		}

		//auto tb =  font.measureString(text);
		vec2 p = renderBounds.loc + vec2(2, font.ascent + 2);//renderBounds.alignIn(tb, "left-center");

		// render higlight
		if(highlightStart != -1 && highlightStart != insertLoc) {
			import std.algorithm : swap;
			auto start = p + locateChar(insertLoc);
			auto end   = p + locateChar(highlightStart);
			if(end.x < start.x) swap(start,end);

			start = start + vec2(0, -font.ascent);
			end   = end   + vec2(0, -font.descent);

			auto loc = start;
			auto size = end - start;

			g.drawRectangle(Rectangle(loc, size), style.highlight);
		}

		if(value == "") g.drawString(text, p, style.text_hint); 
		else g.drawString(value, p, style.text);

		if(showLine) {
			auto lp = p + locateChar(insertLoc);
			auto start = lp + vec2(0, -font.ascent);
			auto end = lp + vec2(0, -font.descent);
			g.drawLine(start, end, style.text);
		}
	}

	override protected void thinkProc() {
		auto prev = showLine;


		if(clicked) {
			if(!hwState().mouseButtons[hwMouseButton.MOUSE_LEFT]) { 
				clicked = false;
				if(highlightStart == insertLoc) highlightStart = -1;
			} else {
				uint index = posToIndex(screenToLocal(hwState().mousePos));
				insertLoc = index;
				showLine = true;
				lastBlink = Clock.currTime;
				invalidate;
			}
		}


		fixInsert();
		if(hasFocus) {
			auto now = Clock.currTime;
			if((now - lastBlink).split().msecs > 500) {
				showLine = !showLine;
				lastBlink = now;
			}
		} else showLine = false;
		if(showLine != prev) invalidate();
	}

	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		auto font = getGraphics().getFont();
		if(!down || btn != hwMouseButton.MOUSE_LEFT) return;
		uint index = posToIndex(loc);
		highlightStart = index;
		insertLoc = index;
		showLine = true;
		lastBlink = Clock.currTime;
		invalidate;
		fixInsert();
		clicked = true;
	}

	private uint posToIndex(vec2 loc) {
		auto font = getGraphics().getFont();
		float dist = 9999;
		uint index = 0;
		uint i = 0;
		vec2 r = vec2(0,0);
		foreach(LayoutPos g; font.textLayout(value, vec2(2, font.ascent + 2))) {
			auto d = (loc - g.loc).length;
			if(d < dist) {
				dist = d;
				index = i;
			}
			i++;
			r = g.loc + cast(vec2)g.glyph.advance;
		}
		auto d = (loc - r).length;
		if(d < dist) index = i;
		return index;
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		import std.stdio;
		if(down) {
			ignoreFalse = true;
		} else if(ignoreFalse) {
			ignoreFalse = false;
			return;
		}

		fixInsert();

		if(k == hwKey.LEFT && insertLoc > 0) {

			if(mods == hwKeyModifier.shift) {
				if(highlightStart == -1) highlightStart = insertLoc;
			} else highlightStart = -1;

			insertLoc--;
			showLine = true;
			lastBlink = Clock.currTime;

			invalidate();
			return;
		} else if(k == hwKey.RIGHT && insertLoc < value.length) {

			if(mods == hwKeyModifier.shift) {
				if(highlightStart == -1) highlightStart = insertLoc;
			} else highlightStart = -1;

			insertLoc++;
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate();
			return;
		} else if(k == hwKey.BACKSPACE && insertLoc >= 0) {
			if(!allowEdit) return;
			if(deleteSelect()) return;
			value = value[0 .. insertLoc-1] ~ value[insertLoc .. $];
			insertLoc--;
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate();

			changeEvent();
		} else if(k == hwKey.DELETE && insertLoc < value.length) {
			if(!allowEdit) return;
			if(deleteSelect()) return;
			value = value[0 .. insertLoc] ~ value[insertLoc+1 .. $];
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate();

			changeEvent();
		} else if(k == hwKey.TAB) {
			charProc('\t');
		} else if(k == hwKey.V && mods == hwKeyModifier.ctrl) {
			// Paste text ctrl+v
			import std.conv;
			if(!allowEdit) return;
			auto paste = hwGetClipboard().to!dstring;

			deleteSelect();
			value = value[0 .. insertLoc] ~ paste ~ value[insertLoc .. $];
			insertLoc += paste.length;
			showLine = true;
			lastBlink = Clock.currTime;
			invalidate();

			changeEvent();
		} else if(k == hwKey.C && mods == hwKeyModifier.ctrl) {
			import std.algorithm: swap;
			import std.conv;
			auto start = insertLoc;
			auto end = highlightStart;
			if(start == end || highlightStart == -1) return;
			if(end < start) swap(start, end);
			auto copy = value[start .. end].to!string;
			hwSetClipboard(copy);
		}

	}

	private bool deleteSelect() {
		import std.algorithm: swap;
		auto start = insertLoc;
		auto end = highlightStart;
		if(!allowEdit) return false;

		if(end < start) swap(start, end);
		if(start < 0) start = 0;
		if(end > value.length) end = cast(int)value.length;
		if(start == end || highlightStart == -1) return false;


		value = value[0 .. start] ~ value[end .. $];
		insertLoc = start;
		highlightStart = -1;
		showLine = true;
		lastBlink = Clock.currTime;
		invalidate();
		changeEvent();

		return true;
	}

	private void fixInsert() {
		if(insertLoc < 0) insertLoc = 0;
		if(insertLoc > value.length) insertLoc = cast(int)value.length;
		if(highlightStart > value.length || value.length == 0) highlightStart = -1;
	}

	override protected void charProc(dchar c) {
		if(!allowEdit) return;
		fixInsert();
		deleteSelect();

		value = value[0 .. insertLoc] ~ c ~ value[insertLoc .. $];
		insertLoc++;
		showLine = true;
		lastBlink = Clock.currTime;
		invalidate();

		changeEvent();
	}

	private void changeEvent() {
		EventArgs e = { type:EventType.ValueChange };
		e.svalue = value;
		doEvent(e);
		onChange();
	}
}

