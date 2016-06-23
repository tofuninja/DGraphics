module graphics.gui.base;

import graphics.gui.div;
import graphics.gui.window;
import graphics.hw;
import graphics.simplegraphics;
import graphics.font;
import math.matrix;
import math.geo.rectangle;
import tofuEngine;

/**
 * Base div, contains its own render buffer where all divs are rendered to
 * 
 */
class Base : div {
	private hwTextureRef!(hwTextureType.tex2D) color;
	private hwTextureRef!(hwTextureType.tex2D) depth;
	private simplegraphics graph;
	private hwFboRef renderTarget;
	private bool invalid 		= true;
	private div focus 			= null;
	private div hover 			= null;
	private Window activeWindow = null;
	private Window waitWindow	= null;
	private menuDiv currentMenu = null;
	bool back					= false;
	uint fboWidth 				= 1920;
	uint fboHeight 				= 1080;
	float fontSize 				= 12.0f;
	bool fillFirst				= false;
	Engine engine				= null;

	this(Engine e) {
		engine = e;
		base = this;
		// Color
		{
			hwTextureCreateInfo!() info;
			info.size = uvec3(fboWidth,fboHeight,1);
			info.format = hwColorFormat.RGBA_n8;
			//if(!colorAsTexture) info.renderBuffer = true;
			color = hwCreate(info);
		}

		// Depth Stencil 
		{
			hwTextureCreateInfo!() info;
			info.size = uvec3(fboWidth,fboHeight,1);
			info.format = hwColorFormat.Depth_24_Stencil_8;
			info.renderBuffer = true;
			depth = hwCreate(info);
		}

		// Render Target
		{
			hwFboCreateInfo info;
			info.colors[0].enabled = true;
			info.colors[0].tex = color;
			info.depthstencil.enabled = true;
			info.depthstencil.tex = depth;
			renderTarget = hwCreate(info);
		}

		//graph = new simplegraphics(new Font("./assets/fonts/consola.ttf", 14.0f));
		graph = new simplegraphics(new Font(fontSize, "./assets/fonts/SourceCodePro-Regular.otf", "./assets/fonts/fontawesome-webfont.ttf"));
		bounds.size.x = fboWidth;
		bounds.size.y = fboHeight;
	}

	public Rectangle windowBounds() {
		auto state = hwState();
		return Rectangle(0,0, state.mainViewport.size.x, state.mainViewport.size.y);
	}

	public void setUp() {
		doInit();
	}

	~this() {
		hwDestroy(renderTarget);
		hwDestroy(color);
		hwDestroy(depth);
	}

	public hwFboRef getFBO() {
		return renderTarget;
	}

	public hwTextureRef!(hwTextureType.tex2D) getTexture() {
		return color;
	}

	override protected void thinkProc() {
		import graphics.color;
		import math.geo.rectangle;
		import std.stdio;

		if(invalid) {
			doStylize();

			hwRenderStateInfo state;
			state.fbo = renderTarget;
			state.viewport = iRectangle(0, 0, fboWidth, fboHeight);
			state.depthTest = true;
			state.depthFunction = hwCmpFunc.greaterEqual;
			hwCmd(state);
			
			hwClearCommand clear;
			if(back)
				clear.colorClear = style.background;
			else
				clear.colorClear = Color(0,0,0,0);
			clear.depthClear = -1;
			hwCmd(clear);

			graph.setTarget(renderTarget, iRectangle(0, 0, fboWidth, fboHeight));
			graph.resetDepth();
			doDraw(graph, Rectangle(0, 0, bounds.size.x, bounds.size.y));
			graph.flush();
			
			invalid = false;

		}
	}

	public override void doKey(hwKey k, hwKeyModifier mods, bool down) {
		if(focus !is null) {
			focus.doKey(k, mods, down);
		}
	}

	public override void doChar(dchar c) {
		if(focus !is null) {
			focus.doChar(c);
		}
	}
	
	public override div doClick(vec2 loc, hwMouseButton button, bool down) {
		div last = getChildAt(loc);
		if(waitWindow !is null && last !is waitWindow) last = null;
		if(down && currentMenu !is null) {
			if(cast(menuDiv)last) {} else {
				currentMenu.closeMenu(-1, "-Menu Cancled-");
			}
		}
		if(down && waitWindow is null) {
			if(auto win = cast(Window)last) makeActiveWindow(win);
			else clearActiveWindow();
		}

		if(last !is null) last = last.doClick(loc-last.bounds.loc, button, down);
		if(down) makeFocus(last);
		return last;
	}

	public void makeFocus(div d) {
		if(d is null || !d.canFocus) return; 
		if(focus !is null) focus.doFocus(false);
		focus = d;
		focus.doFocus(true);
	}

	public void clearFocus() {
		if(focus !is null) focus.doFocus(false);
		focus = null;
	}

	public Window makeActiveWindow(Window d) {
		if(d is activeWindow || d is null) return activeWindow;
		auto temp = activeWindow;
		clearActiveWindow();
		clearFocus();
		activeWindow = d;
		activeWindow.active = true;
		//childrenList.moveBack(activeWindow.myNode);
		activeWindow.moveFront();
		activeWindow.activateProc(true);
		invalidate();
		return activeWindow;
	}

	public void clearActiveWindow() {
		if(activeWindow is null) return;
		activeWindow.active = false;
		activeWindow.activateProc(false);
		activeWindow = null;
		invalidate();
	}

	//public override void addDiv(div d) {
	//    assert(d.parent is null, "Child of another div");
	//    
	//    if(auto win = cast(Window)d) {
	//        win.myNode = childrenList.insertBack(win);
	//    } else if(auto menu = cast(menuDiv)d) {
	//        menu.myNode = childrenList.insertBack(menu);
	//    } else {
	//        d.myNode = childrenList.insertFront(d);
	//    }
	//
	//    d.parent = this;
	//    d.setStyle(this.style);
	//    d.setBase(this);
	//    d.invalidate();
	//}

	override public void removeDiv(div d) {
		if(d is focus)			focus			= null;
		if(d is activeWindow)	activeWindow	= null;
		if(d is hover)			hover			= null;
		if(d is waitWindow)		waitWindow		= null;
		if(d is currentMenu)	currentMenu		= null;
		super.removeDiv(d);
	}
	
	public override div doHover(vec2 loc) {
		div last = getChildAt(loc);
		if(last is null) {
			if(hover !is null) hover.doEnter(false);
			else hwCmd(cursor);
			hover = null;
			return null;
		}

		auto temp = last.doHover(loc-last.bounds.loc);
		if(temp !is hover) {
			if(hover !is null) hover.doEnter(false);
			hover = temp;
			if(hover !is null) hover.doEnter(true);
		}
		return temp;
	}

	override public void invalidate() {
		invalid = true;
	}

	override public simplegraphics getGraphics() {
		return graph;
	}

	override protected void stylizeProc() {
		super.stylizeProc();
		bounds = windowBounds();
		if(fillFirst && childrenList.length > 0) {
			div d = childrenList.peekBack();
			d.bounds.loc = vec2(0,0);
			d.bounds.size = this.bounds.size;
		}
	}

	public void blitToMain() {
		//hwRenderStateInfo state;
		//state.fbo = Game.state.mainFbo;
		//state.viewport = Game.state.mainViewport;
		//hwCmd(state);
		//hwBlitCommand blit;
		//blit.blitColor = true;
		//blit.destination = iRectangle(0, Game.state.mainViewport.size.y - fboHeight, fboWidth, fboHeight);
		//blit.source = iRectangle(0,0, fboWidth, fboHeight);
		//blit.fbo = renderTarget;
		//hwCmd(blit);
		import graphics.render.textureQuadRenderer;
		auto state = hwState();
		drawTexture(color, state.mainViewport, state.mainFbo, vec2(0,0), vec2(fboWidth, fboHeight), 0, true, false);
	}

	public void doFrame() {
		// UI think, then blit the UI to the main FBO 
		doThink();
		blitToMain();
	}

	override public void doThink() {
		// Do children think first... 
		foreach(div d; childrenList[]) {
			d.doThink();
		}
		thinkProc();
		doEventThink();
	}

	void waitOnWindowClose(Window w, bool centerWindow = true) {
		import graphics.color;
		auto prevActive = makeActiveWindow(w);
		auto prevWait = waitWindow;
		waitWindow = w;
		if(centerWindow) { 
			w.bounds.loc = (cast(vec2)hwState().mainViewport.size)/2 - w.bounds.size/2;
			if(w.bounds.loc.x < 0) w.bounds.loc.x = 0;
			if(w.bounds.loc.y < 0) w.bounds.loc.y = 0;
		}

		while(waitWindow is w && !hwState().shouldClose) {
			hwRenderStateInfo state;
			state.fbo = hwState().mainFbo;
			state.viewport = hwState().mainViewport;
			hwCmd(state);

			// Clear screen to a nice beige :)
			hwClearCommand clear;
			clear.colorClear = Color(0,0,0,0);
			clear.depthClear = -1;
			hwCmd(clear);
			hwPollEvents();
			// UI think, then blit the UI to the main FBO 
			doFrame();

			// Swap buffers and close if we need to
			hwSwapBuffers();
			if(hwState().keyboard[hwKey.ESCAPE]) break;
		}
		waitWindow = prevWait;
		if(prevActive !is null && prevActive !is w) { 
			makeActiveWindow(prevActive);
		}
	}

	void openMenu(void delegate(int, dstring) callback, vec2 loc, dstring[] items) {
		assert(currentMenu is null, "Can not have more than one menu open at a time");
		currentMenu = new menuDiv(items, callback);
		currentMenu.bounds.loc = loc;
		currentMenu.openMenu(this);
	}
}

import graphics.gui.verticalArrangement; 
private class menuDiv : VerticalArrangement {
	void delegate(int, dstring) callback = null;
	menuDiv ownerMenu; 
	menuDiv currentSub;
	enum itemPad = 4;
	enum menuWidth = 100;
	int itemHeight;
	float arrow_width;

	this() {
		// do nothinh...
	}

	this(dstring[] items, void delegate(int, dstring) callback) {
		this.callback = callback;
		addItems(items, 0);
		this();
	}

	private int addItems(dstring[] items, int start) {
		auto f = tofu_UI.getGraphics().getFont();
		
		if(ownerMenu !is null) arrow_width = ownerMenu.arrow_width;
		else arrow_width = f.measureString("\uF054").size.x;

		float mesure = menuWidth;
		scope(exit) 
			this.bounds.size.x = mesure;

		for(int i = start; i < items.length; i++) {
			auto item = items[i];
			if(item.length == 0) {
				// We will interpret null strings as horizontal bars... 
				this.addDiv(new menuItem(i));
			} else if(item[0] == '>') {
				// Start of a sub menu
				auto mi = new menuItem(i);
				auto sub = new menuDiv();
				sub.ownerMenu = this;
				mi.subMenu = sub;
				mi.text = item[1 .. $];
				auto t_width = f.measureString(mi.text).size.x + itemPad*3 + arrow_width;
				if(t_width > mesure) mesure = t_width;
				i = sub.addItems(items, i+1);
				this.addDiv(mi);
			} else if(item == "<") {
				// End of sub menu
				return i;
			} else {
				// Basic menu Item
				auto mi = new menuItem(i);
				mi.text = item;
				auto t_width = f.measureString(item).size.x + itemPad*2;
				if(t_width > mesure) mesure = t_width;
				this.addDiv(mi);
			}
		}
		return cast(int)(items.length);
	}

	override protected void initProc() {
		super.initProc;
		auto font = getGraphics().getFont();
		itemHeight = font.lineHeight + itemPad*2;
	}

	void closeMenu(int index, dstring text) {
		if(ownerMenu !is null) {
			ownerMenu.closeMenu(index, text);
		} else {
			closeMenu();
			if(callback !is null) callback(index, text);
		}
	}

	void closeMenu() {
		if(ownerMenu !is null) {
			ownerMenu.currentSub = null;
		} 
		if(currentSub !is null) currentSub.closeMenu();
		base.removeDiv(this);
	}

	void openMenu(Base b) {
		if(ownerMenu !is null) {
			if(ownerMenu.currentSub is this) return;
			if(ownerMenu.currentSub !is null) ownerMenu.currentSub.closeMenu();
			ownerMenu.currentSub = this;
		}
		b.addDiv(this);
	}
	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		g.drawRectangle(renderBounds, style.contrast);
	}

	override protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {
		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		auto darker = style.border_shadow;
		g.drawLine(v1, v2, darker,1);
		g.drawLine(v1, v3, darker,1);
		g.drawLine(v3, v4, darker,1);
		g.drawLine(v2, v4 + vec2(0, 1), darker,1);
	}
	override protected void stylizeProc() {
		super.stylizeProc;
		// Sub-menues get their y from the menuItem stylize

		if(ownerMenu !is null) {
			this.bounds.loc.x = ownerMenu.bounds.loc.x + ownerMenu.bounds.size.x;

			if(this.bounds.loc.x + this.bounds.size.x > parent.bounds.size.x) 
				bounds.loc.x = ownerMenu.bounds.loc.x - this.bounds.size.x + itemPad - 1; 
			// I dont do exactly loc.x - menuWidth because if the menues overlap perfectly it is hard to tell where one starts and the other ends
			// the extra itemPad - 1 just makes sure things dont line up perfectly
		} else {
			if(this.bounds.loc.x + this.bounds.size.x > parent.bounds.size.x) 
				this.bounds.loc.x = parent.bounds.size.x - this.bounds.size.x;
		}

		if(bounds.loc.y + bounds.size.y > parent.bounds.size.y) bounds.loc.y = parent.bounds.size.y - bounds.size.y;
		if(bounds.loc.x < 0) bounds.loc.x = 0;
		if(bounds.loc.y < 0) bounds.loc.y = 0;
	}
	
}

private class menuItem : div {
	int index;
	menuDiv subMenu = null;
	bool hover = false;

	this(int index) {
		canClick = true;
		this.index = index; 
	}
	override protected void stylizeProc() {
		auto p = cast(menuDiv) parent;
		bounds.size = vec2(parent.bounds.size.x, (text == "")? 3 : p.itemHeight);
		if(subMenu !is null)
			subMenu.bounds.loc.y = this.bounds.loc.y + parent.bounds.loc.y;
	}
	
	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		if(subMenu is null && text != "" && btn == hwMouseButton.MOUSE_LEFT && down) {
			auto p = cast(menuDiv) parent;
			p.closeMenu(index, text);
		}
	}
	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		if(text == "") {
			g.drawLine(renderBounds.loc + vec2(menuDiv.itemPad,1), renderBounds.loc + vec2(renderBounds.size.x - menuDiv.itemPad*2,1), style.border_shadow,1);
		} else {
			if(hover) g.drawRectangle(renderBounds, style.highlight_contrast);
			renderBounds.loc += vec2(menuDiv.itemPad, menuDiv.itemPad);
			renderBounds.size -= vec2(menuDiv.itemPad*2, menuDiv.itemPad*2);
			
			{
				auto tb =  g.getFont.measureString(text);
				vec2 p = renderBounds.centerLeft(tb);
				g.drawString(text, p, style.text_contrast); 
			}

			if(subMenu !is null) {
				auto tb =  g.getFont().measureString("\uF054");
				vec2 p = renderBounds.centerRight(tb);
				g.drawString("\uF054", p, style.text_contrast); 
			}
		}
	}

	override protected void enterProc(bool enter) {
		hover = enter;
		invalidate();

		if(!enter) return;
		if(subMenu !is null) {
			subMenu.openMenu(base);
		} else if(auto p = cast(menuDiv)parent) {
			if(p.currentSub !is null) p.currentSub.closeMenu();
		}
	}
}


//auto startUI(alias baseDiv)(uint w = 1920, uint h = 1080)
//{

//	auto mainDiv = new baseDiv!(div, div);
//	mainDiv.setUp(w,h);

//	return mainDiv;
//}
