module graphics.gui.div;

//import util.event;
//import graphics.gui.parser.ast.astNode;
import graphics.hw;
import graphics.simplegraphics;
import graphics.color;
import graphics.gui.base;
import math.matrix;
import math.geo.rectangle;
import container.clist;
import std.range : retro;

import std.stdio;

//	 _____  _       
//	|  __ \(_)      
//	| |  | |___   __
//	| |  | | \ \ / /
//	| |__| | |\ V / 
//	|_____/|_| \_/  
//	                
//	                

// TODO force re draw with out re stylize
// TODO make shadows more noticeable
// TODO maybe have a value for shadow intensity?  

// TODO remove as much allocations as possible, try to use mallocator as much as possible
// TODO switch strings over to rstring

/// Color scheme for the ui, initied to a high contrast theme
struct Style {
	Color background 		= RGB(255,255,255);
	Color foreground 		= RGB(0,0,0);
	Color contrast			= RGB(255,255,255);
	Color button			= RGB(255,255,255);
	Color lower				= RGB(240,240,240);
	Color disabled			= RGB(200,200,200);
	Color highlight			= RGB(180,180,180);
	Color highlight_contrast= RGB(210,210,210);

	Color text 				= RGB(0,0,0);
	Color text_hint 		= RGB(100,100,100);
	Color text_contrast 	= RGB(0,0,0);
	Color text_hover 		= RGB(0,120,155);

	Color border			= RGB(100,100,100);
	Color border_shadow		= RGB(0,0,0);
	Color border_contrast	= RGB(0,0,0);

	Color scroll				= RGB(200,200,200);
	Color border_scroll			= RGB(100,100,100);
	Color border_scroll_shadow	= RGB(0,0,0);

	Color split					= RGB(255,255,255);
	Color border_split			= RGB(100,100,100);
	Color border_split_shadow	= RGB(0,0,0);
}

struct EventArgs
{
	EventType 	type 		= EventType.Other;
	div 		origin		= null;
	vec2 		loc 		= vec2(0,0);
	bool 		down		= false;
	hwMouseButton mouse;
	hwKey 		key_value;
	hwKeyModifier mods;
	dchar		cvalue	 	= '\0';
	dstring 	svalue		= "";
	int			ivalue		= 0;
	float 		fvalue		= 0.0f;
}

enum EventType
{
	Init,
	Think,
	Stylize,
	Click,
	Key,
	Char,
	Enter,
	Hover,
	Focus,
	Scroll,
	Action,
	ValueChange,
	Menu,

	Other
}

class div
{
	protected bool initialized = false;
	package div parent;
	package Base base;
	package CList!(div).Node* myNode;
	Rectangle bounds;
	dstring text = "";
	bool canFocus = false;
	bool canClick = false;
	bool canScroll = false;
	bool hasFocus = false;
	protected CList!div childrenList;

	hwCursorRef cursor;
	Style style;
	void delegate(EventArgs event) eventHandeler; 

	protected void initProc() {} 
	protected void thinkProc() {}
	protected void stylizeProc() {}
	protected void drawProc(simplegraphics g, Rectangle renderBounds) {}
	protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {}
	protected void keyProc(hwKey k, hwKeyModifier mods, bool down) {}
	protected void charProc(dchar c) {} 
	protected void clickProc(vec2 loc, hwMouseButton button, bool down) {}
	protected void enterProc(bool enter) {}
	protected void hoverProc(vec2 pos) {}
	protected void focusProc(bool hasFocus) {}
	protected void scrollProc(vec2 loc, int scroll) {}
	protected void menuProc(int index, dstring text) {}
	void invalidate() { if(base) base.invalidate(); }

	final void doEvent(EventArgs event) {
		if(eventHandeler !is null) {
			event.origin = this;
			eventHandeler(event);
		}
	}

	final void doEventInit() {
		EventArgs e = { type:EventType.Init };
		doEvent(e);
	}

	final void doEventThink() {
		EventArgs e = { type:EventType.Think };
		doEvent(e);
	}

	final void doEventStylize() {
		EventArgs e = { type:EventType.Stylize };
		doEvent(e);
	}

	final void doEventClick(vec2 loc, hwMouseButton btn, bool down) {
		EventArgs e = { type:EventType.Click, loc:loc, down:down, mouse:btn};
		doEvent(e);
	}

	final void doEventKey(hwKey k, hwKeyModifier mod, bool down) {
		EventArgs e = { type:EventType.Key, key_value:k, mods:mod, down:down };
		doEvent(e);
	}

	final void doEventChar(dchar c) {
		EventArgs e = { type:EventType.Char, cvalue:c };
		doEvent(e);
	}

	final void doEventEnter(bool down) {
		EventArgs e = { type:EventType.Enter, down:down };
		doEvent(e);
	}

	final void doEventHover(vec2 loc) {
		EventArgs e = { type:EventType.Hover, loc:loc };
		doEvent(e);
	}

	final void doEventFocus(bool down) {
		EventArgs e = { type:EventType.Focus, down:down };
		doEvent(e);
	}

	final void doEventScroll(vec2 loc, int value) {
		EventArgs e = { type:EventType.Scroll, loc:loc, ivalue:value };
		doEvent(e);
	}

	final void doEventMenu(int index, dstring text) {
		EventArgs e = { type:EventType.Menu, ivalue:index, svalue:text };
		doEvent(e);
	}

	this() {
		cursor = hwGetSimpleCursor(hwSimpleCursor.arrow);
	}

	package final void doInit() {
		initProc();
		doEventInit();
	}

	void doThink() {
		thinkProc();
		doEventThink();
		foreach(div d; childrenList[]) {
			d.doThink();
		}
	}

	void doStylize() {
		stylizeProc();
		doEventStylize();
		
		foreach(div d; childrenList[]) {
			d.doStylize();
		}
	}

	void doDraw(simplegraphics g, Rectangle renderBounds) {
		vec2 roundVec2(vec2 v) {
			import std.math;
			return vec2(round(v.x), round(v.y));
		}

		renderBounds.loc = roundVec2(renderBounds.loc);
		renderBounds.size = roundVec2(renderBounds.size);

		auto t = g.addScissor(renderBounds);
		drawProc(g, renderBounds);
		g.setScissor(t);

		t = g.addScissor(renderBounds);
		g.setScissor(t);


		foreach(div d; childrenList[].retro) {
			t = g.addScissor(renderBounds);
			d.doDraw(g, Rectangle(renderBounds.loc + d.bounds.loc, d.bounds.size));
			g.setScissor(t);
		}

		t = g.addScissor(renderBounds);
		afterDrawProc(g, renderBounds);
		g.setScissor(t);
	}

	void doKey(hwKey k, hwKeyModifier mods, bool down) {
		keyProc(k, mods, down);
		doEventKey(k, mods, down);
	}

	void doChar(dchar c) {
		charProc(c);
		doEventChar(c);
	}
	
	div doClick(vec2 loc, hwMouseButton button, bool down) {
		div last = getChildAt(loc);
		if(last !is null) last = last.doClick(loc-last.bounds.loc, button, down);

		if(canClick && last is null) {
			clickProc(loc, button, down);
			doEventClick(loc, button, down);
			return this;
		}
		return last;
	}

	div doScroll(vec2 loc, int scroll) {
		div last = getChildAt(loc);
		if(last !is null) last = last.doScroll(loc-last.bounds.loc, scroll);
		
		if(canScroll && last is null) {
			scrollProc(loc, scroll);
			doEventScroll(loc, scroll);
			return this;
		}
		
		return last;
	}

	div doHover(vec2 loc) {
		div last = getChildAt(loc);
		if(last is null) {
			hoverProc(loc);
			doEventHover(loc);
			return this;
		}
		return last.doHover(loc-last.bounds.loc);
	}

	void doEnter(bool enter) {
		if(enter) hwCmd(cursor);
		enterProc(enter);
		doEventEnter(enter);
	}

	void doFocus(bool hasFocus) {
		this.hasFocus = hasFocus;
		focusProc(hasFocus);
		doEventFocus(hasFocus);
	}

	void doMenu(int index, dstring text) {
		menuProc(index, text);
		doEventMenu(index, text);
	}

	void openContextMenu(dstring[] items) {
		base.openMenu(&(this.doMenu), hwState().mousePos, items);
	}
	
	void addDiv(div d) {
		assert(d.parent is null, "Child of another div");
		d.myNode	= childrenList.insertFront(d);
		d.parent	= this;
		d.setStyle(this.style);

		if(this.base !is null) {
			d.setBase(this.base);
		}
		this.invalidate();
	}

	void moveBack() {
		parent.childrenList.moveBack(this.myNode);
	}

	void moveFront() {
		parent.childrenList.moveFront(this.myNode);
	}

	void moveTowardsBack() {
		parent.childrenList.moveTowardsBack(this.myNode);
	}

	void moveTowardsFront() {
		parent.childrenList.moveTowardsFront(this.myNode);
	}

	void removeDiv(div d) {
		childrenList.removeNode(d.myNode);
		d.parent = null;
		invalidate();
	}

	package void setBase(Base b) {
		this.base = b; 
		doInit();
		foreach(c; childrenList[]) c.setBase(b);
	}

	CList!div children() {
		return childrenList;
	}

	simplegraphics getGraphics() {
		return parent.getGraphics();
	}

	void setStyle(Style s) {
		style = s;
		foreach(d; childrenList[]) d.setStyle(s);
		invalidate();
	}

	vec2 screenToLocal(vec2 point) {
		auto orig = localToScreen(vec2(0,0));
		return point - orig;
	}

	vec2 localToScreen(vec2 point) {
		if(parent) {
			return point + parent.localToScreen(bounds.loc);
		} else {
			return point;
		}
	}

	div getChildAt(vec2 loc){
		foreach(c; childrenList[]) {
			if(c.bounds.contains(loc)) return c;
		}
		return null;
	}
}



