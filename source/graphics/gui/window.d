module graphics.gui.window;

import graphics.gui.div;
import graphics.gui.button;
import graphics.hw;
import graphics.color;
import graphics.simplegraphics;
import math.matrix;
import math.geo.rectangle;
import container.clist;

private enum titleBarPadding = 2;
private enum gripSize = 4;
private enum cornerPad = 4;
private enum minWindowX = 100;

class Window : div { 
	bool showCloseButton	= true;
	bool sizeable			= true;
	bool moveable			= true;
	bool fillFirst			= false;

	package bool active		= false;
	private int currentGrip = -1;
	private vec2 clickLoc;
	private vec2 clickSize;
	private int defaultHeight;
	private titleBar tb_div;
	private mainArea ma_div;
	private closeButton closeBtn;
	private sizeGrip grip00;
	private sizeGrip grip10;
	private sizeGrip grip20;
	private sizeGrip grip21;
	private sizeGrip grip22;
	private sizeGrip grip12;
	private sizeGrip grip02;
	private sizeGrip grip01;

	this() {
		canClick = true;
		grip00 = new sizeGrip(1);
		super.addDiv(grip00);
		grip10 = new sizeGrip(2);
		super.addDiv(grip10);
		grip20 = new sizeGrip(3);
		super.addDiv(grip20);
		grip21 = new sizeGrip(4);
		super.addDiv(grip21);
		grip22 = new sizeGrip(5);
		super.addDiv(grip22);
		grip12 = new sizeGrip(6);
		super.addDiv(grip12);
		grip02 = new sizeGrip(7);
		super.addDiv(grip02);
		grip01 = new sizeGrip(8);
		super.addDiv(grip01);
		tb_div = new titleBar();
		super.addDiv(tb_div);
		ma_div = new mainArea();
		super.addDiv(ma_div);
		closeBtn = new closeButton();
		super.addDiv(closeBtn);
	}

	override protected void initProc() {
		super.initProc;
		import graphics.gui.base; 
		assert(cast(Base)parent, "Window divs can only be added to the base div"); 
		auto font = getGraphics().getFont();
		defaultHeight = (font.ascent - font.descent + 4);
	}

	//override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
	//    g.drawRectangle(renderBounds, RGB(255,0,0));
	//}

	override protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {
		renderBounds.loc += vec2(gripSize, gripSize);
		renderBounds.size -= vec2(gripSize*2, gripSize*2);

		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		Color darker = style.border_shadow;
		Color lighter = style.border;
		auto borderColor = active?darker:lighter;
		g.drawLine(v1, v2, borderColor,1);
		g.drawLine(v1, v3, borderColor,1);
		g.drawLine(v3, v4, borderColor,1);
		g.drawLine(v2, v4 + vec2(0, 1), borderColor,1);
		auto titleH = defaultHeight + titleBarPadding*2 + 1;
		g.drawLine(v1+vec2(0,titleH), v2 + vec2(1,titleH), borderColor,1);
	}

	override protected void thinkProc() {
		if(currentGrip >= 0) {
			if(hwState().mouseButtons[hwMouseButton.MOUSE_LEFT] == false || moveable == false) {
				currentGrip = -1;
				return;
			}
			auto minx = minWindowX + gripSize*2 + 2;
			auto miny = defaultHeight + gripSize*2 + titleBarPadding*2 + 2;

			switch(currentGrip) {
				case 0: {
					// Title bar
					bounds.loc = hwState().mousePos - clickLoc;
				} break;
				case 1: {
					// Upper Left
					bounds.loc = hwState().mousePos - clickLoc;
					bounds.size = clickSize - bounds.loc;
					
					// maintain min size
					if(bounds.size.x < minx) {
						bounds.loc.x = clickSize.x - minx;
						bounds.size.x = minx;
					}
					if(bounds.size.y < miny) {
						bounds.loc.y = clickSize.y - miny;
						bounds.size.y = miny;
					}
				} break;
				case 2: {
					// Upper Middle 
					bounds.loc.y = hwState().mousePos.y - clickLoc.y;
					bounds.size.y = clickSize.y - bounds.loc.y;

					// maintain min size
					if(bounds.size.y < miny) {
						bounds.loc.y = clickSize.y - miny;
						bounds.size.y = miny;
					}
				} break;
				case 3: {
					// Upper Right
					bounds.size.x = hwState().mousePos.x + clickSize.x - clickLoc.x - 2*bounds.loc.x;
					bounds.loc.y = hwState().mousePos.y - clickLoc.y;
					bounds.size.y = clickSize.y - bounds.loc.y;

					// maintain min size
					if(bounds.size.x < minx) bounds.size.x = minx;
					if(bounds.size.y < miny) {
						bounds.loc.y = clickSize.y - miny;
						bounds.size.y = miny;
					}
				} break;
				case 4: {
					// Center Right
					bounds.size.x = hwState().mousePos.x + clickSize.x - clickLoc.x - 2*bounds.loc.x;
					// maintain min size
					if(bounds.size.x < minx) bounds.size.x = minx;
				} break;
				case 5: {
					// Lower Right
					bounds.size.x = hwState().mousePos.x + clickSize.x - clickLoc.x - 2*bounds.loc.x;
					bounds.size.y = hwState().mousePos.y + clickSize.y - clickLoc.y - 2*bounds.loc.y;
					// maintain min size
					if(bounds.size.x < minx) bounds.size.x = minx;
					if(bounds.size.y < miny) bounds.size.y = miny;
				} break;
				case 6: {
					// Lower Middle
					bounds.size.y = hwState().mousePos.y + clickSize.y - clickLoc.y - 2*bounds.loc.y;
					// maintain min size
					if(bounds.size.y < miny) bounds.size.y = miny;
				} break;
				case 7: {
					// Lower Left
					bounds.loc.x = hwState().mousePos.x - clickLoc.x;
					bounds.size.x = clickSize.x - bounds.loc.x;
					bounds.size.y = hwState().mousePos.y + clickSize.y - clickLoc.y - 2*bounds.loc.y;
					// maintain min size
					if(bounds.size.x < minx) {
						bounds.loc.x = clickSize.x - minx;
						bounds.size.x = minx;
					}
					if(bounds.size.y < miny) bounds.size.y = miny;
				} break;
				case 8: {
					// Center Left
					bounds.loc.x = hwState().mousePos.x - clickLoc.x;
					bounds.size.x = clickSize.x - bounds.loc.x;

					// maintain min size
					if(bounds.size.x < minx) {
						bounds.loc.x = clickSize.x - minx;
						bounds.size.x = minx;
					}
				} break;
				default: assert(0);
			}
			invalidate();
		}
	}

	override protected void stylizeProc() {
		tb_div.bounds = Rectangle(gripSize+1, gripSize+1, bounds.size.x-gripSize*2 - 2, defaultHeight + titleBarPadding*2);
		ma_div.bounds = bounds;
		ma_div.bounds.loc = vec2(gripSize+1, gripSize + defaultHeight + titleBarPadding*2 + 2);
		ma_div.bounds.size -= vec2(gripSize*2 + 2, gripSize*2 + defaultHeight + titleBarPadding*2 + 3);
		closeBtn.bounds = Rectangle(bounds.size.x - (gripSize + defaultHeight + titleBarPadding + 2), gripSize + 1, defaultHeight + titleBarPadding*2, defaultHeight + titleBarPadding*2);

		auto cornerSize = gripSize + cornerPad + 1;
		auto borderSize = gripSize + 1;
		grip00.bounds = Rectangle(0,0, cornerSize, cornerSize);
		grip10.bounds = Rectangle(cornerSize, 0, bounds.size.x - (cornerSize)*2, borderSize);
		grip20.bounds = Rectangle(bounds.size.x - cornerSize, 0, cornerSize, cornerSize);
		grip21.bounds = Rectangle(bounds.size.x - borderSize, cornerSize, borderSize, bounds.size.y - (cornerSize)*2);
		grip22.bounds = Rectangle(bounds.size.x - cornerSize, bounds.size.y - cornerSize, cornerSize, cornerSize);
		grip12.bounds = Rectangle(cornerSize, bounds.size.y - borderSize, bounds.size.x - (cornerSize)*2, borderSize);
		grip02.bounds = Rectangle(0, bounds.size.y - cornerSize, cornerSize, cornerSize);
		grip01.bounds = Rectangle(0, cornerSize, borderSize, bounds.size.y - (cornerSize)*2);

		{
			auto minx = minWindowX + gripSize*2 + 2;
			auto miny = defaultHeight + gripSize*2 + titleBarPadding*2 + 2;
			// maintain min size
			if(bounds.size.x < minx) bounds.size.x = minx;
			if(bounds.size.y < miny) bounds.size.y = miny;
		}

		super.stylizeProc();
	}
	
	override public void addDiv(div d) {
		ma_div.addDiv(d);
	}

	override public void removeDiv(div d) {
		ma_div.removeDiv(d);
	}

	override public CList!div children() {
		return ma_div.children;
	}

	void activateProc(bool active) {} 

	void closeProc() {}

	void close() {
		closeProc();
		{
			EventArgs e = {type: EventType.Action};
			doEvent(e);
		}
		parent.removeDiv(this);
	}

	void waitOnClose(bool centerWindow = true) {
		if(base is null) {
			import tofuEngine : tofu_UI;
			tofu_UI.addDiv(this);
		}
		base.waitOnWindowClose(this, centerWindow);
	}
}

private class titleBar : div {
	this() {
		canClick = true;
	}
	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		auto w = cast(Window)parent;
		if(!down || btn != hwMouseButton.MOUSE_LEFT || w.moveable == false) return;
		w.currentGrip = 0;
		w.clickLoc = loc + bounds.loc;
	}
	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		auto w = cast(Window)parent;
		g.drawRectangle(renderBounds, w.active?style.contrast:style.lower);
	}
	override protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {
		auto w = cast(Window)parent;
		auto p = renderBounds.loc + vec2(titleBarPadding, titleBarPadding);
		g.drawStringAscentLine(w.text, p, w.active?style.text_contrast:style.border); 
	}
}

private class mainArea : div {
	this() {
		canClick = true;
	}
	override protected void stylizeProc() {
		auto w = cast(Window)parent;
		if(w.fillFirst && childrenList.length > 0) {
			div d = childrenList.peekBack();
			d.bounds.loc = vec2(0,0);
			d.bounds.size = this.bounds.size;
		}
		super.stylizeProc();
	}
	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		g.drawRectangle(renderBounds, style.contrast);
	}
}

private class sizeGrip : div {
	int gripID = 0;
	this(int grip) {
		gripID = grip;
		canClick = true;

		switch(gripID) {
			case 1: case 5:{
				cursor = hwGetSimpleCursor(hwSimpleCursor.size_back_arrow);
			} break;
			case 2: case 6:{
				cursor = hwGetSimpleCursor(hwSimpleCursor.size_v);
			} break;
			case 3: case 7:{
				cursor = hwGetSimpleCursor(hwSimpleCursor.size_forward_arrow);
			} break;
			case 4: case 8: {
				cursor = hwGetSimpleCursor(hwSimpleCursor.size_h);
			} break;
			default: assert(0);
		}
	}
	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		auto w = cast(Window)parent;
		if(!down || btn != hwMouseButton.MOUSE_LEFT || w.sizeable == false) return;
		w.currentGrip = gripID;
		w.clickLoc = loc + bounds.loc;
		w.clickSize = w.bounds.loc + w.bounds.size;
	}
}

private class closeButton : div {
	bool hover = false;
	this() {
		canClick = true;
	}
	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		auto w = cast(Window)parent;
		if(!down || btn != hwMouseButton.MOUSE_LEFT || w.showCloseButton == false) return;
		w.close();
	}
	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		auto w = cast(Window)parent;
		if(w.showCloseButton == false) return;
		g.drawRectangle(renderBounds, hover?RGB(255,0,0):(w.active?style.contrast:style.lower));
		Color darker = style.border_shadow;
		Color lighter = style.border;
		auto borderColor = w.active?darker:lighter;
		auto tb =  g.getFont().measureString("\uF00D");
		vec2 p = renderBounds.center(tb);
		g.drawString("\uF00D", p, hover?(w.active?style.contrast:style.lower):borderColor); 
	}

	override protected void enterProc(bool enter) {
		hover = enter;
		invalidate();
	}
	
}