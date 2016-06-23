module graphics.gui.scrollbox;
import graphics.hw;
import graphics.gui.div;
import graphics.gui.panel;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import container.clist;


class Scrollbox : div
{
	public bool border = true;
	public bool back = true;
	public bool fillFirst = false;
	public vec2 area;
	public vec2 scroll;

	private scrollbar!(false) horz;
	private scrollbar!(true) vert;
	private Panel basePane;

	package enum barWidth = 6;
	package enum barBoarder = 1;
	package enum scrollAmount = 20;

	public this() {
		canScroll = true;
		horz = new scrollbar!(false)(this);
		vert = new scrollbar!(true)(this);

		basePane = new scrollPan();
		basePane.border = false;
		basePane.back = false;
		super.addDiv(basePane);
		super.addDiv(horz);
		super.addDiv(vert);
	}

	override protected void scrollProc(vec2 loc, int s) {
		scroll.y -= s*scrollAmount / area.y;
		invalidate();
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		if(back) g.drawRectangle(renderBounds, style.lower);
	}

	override protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {

		if(!border) return;

		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		
		Color darker = style.border_shadow;
		Color lighter = style.border;

		g.drawLine(v1, v2, darker,1);
		g.drawLine(v1, v3, darker,1);
		g.drawLine(v3, v4, lighter,1);
		g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
	}

	override public void doStylize() {
		stylizeProc();
		doEventStylize();

		if(fillFirst && basePane.children.length > 0) {
			div d = basePane.children.peekBack();
			d.bounds.loc = vec2(0,0);
			d.bounds.size = this.bounds.size;
		}

		basePane.doStylize();

		float x = 0;
		float y = 0;

		foreach(div d; basePane.children[]) {
			if(d.bounds.loc.x + d.bounds.size.x > x) x = d.bounds.loc.x + d.bounds.size.x;
			if(d.bounds.loc.y + d.bounds.size.y > y) y = d.bounds.loc.y + d.bounds.size.y;
		}

		if(y > bounds.size.y) {
			vert.isShown = true;
			x += barWidth + barBoarder;
		} else vert.isShown = false;

		if(x > bounds.size.x) {
			horz.isShown = true;
			y += barWidth + barBoarder;
		} else horz.isShown = false;

		vert.doStylize();
		horz.doStylize();

		area = vec2(x, y);

		import std.algorithm;
		float ssizey = bounds.size.y / area.y;
		float ssizex = bounds.size.x / area.x;
		scroll.y = min(scroll.y, 1 - ssizey);
		scroll.y = max(scroll.y,0);
		scroll.x = min(scroll.x, 1 - ssizex);
		scroll.x = max(scroll.x,0);

		basePane.bounds.size = area;
		basePane.bounds.loc = - area*scroll;
	}

	override public void addDiv(div d) {
		basePane.addDiv(d);
	}

	override public void removeDiv(div d) {
		basePane.removeDiv(d);
	}
	

	override public CList!div children() {
		return basePane.children;
	}
}

private class scrollbar(bool vertical) : div  
{
	bool hasClicked = false;
	//public float value = 0;

	private Scrollbox parent;
	private float gameY;
	private float clickValue;
	private bool isShown;

	public this(Scrollbox p) {
		parent = p;
		canClick = true;
		canScroll = true;
	}

	override protected void scrollProc(vec2 loc, int s) {
		static if(vertical) parent.scroll.y -= s*Scrollbox.scrollAmount / parent.area.y;
		else parent.scroll.x -= s*Scrollbox.scrollAmount / parent.area.x;
		invalidate();
	}
	
	override protected void thinkProc() {
		import std.algorithm;
		if(hasClicked) {
			if(hwState().mouseButtons[hwMouseButton.MOUSE_LEFT] == false) {
				hasClicked = false;
				return;
			}

			static if(vertical) {
				float ssize = parent.bounds.size.y / parent.area.y;
				parent.scroll.y = clickValue + (hwState().mousePos.y - gameY)/parent.bounds.size.y;
				//gameY = Game.state.mousePos.y;
				parent.scroll.y = min(parent.scroll.y, 1 - ssize);
				parent.scroll.y = max(parent.scroll.y,0);
			} else {
				float ssize = parent.bounds.size.x / parent.area.x;
				parent.scroll.x = clickValue + (hwState().mousePos.x - gameY)/parent.bounds.size.x;
				//gameY = Game.state.mousePos.x;
				parent.scroll.x = min(parent.scroll.x, 1 - ssize);
				parent.scroll.x = max(parent.scroll.x,0);
			}
			invalidate();
		}
	}
	
	override protected void clickProc(vec2 loc, hwMouseButton button, bool down) {
		hasClicked = true;
		
		static if(vertical) {
			gameY = hwState().mousePos.y;
			clickValue = parent.scroll.y;
		} else {
			gameY = hwState().mousePos.x;
			clickValue = parent.scroll.x;
		}
		thinkProc();
	}
	
	override protected void stylizeProc() {
		if(isShown == false) {
			bounds = Rectangle(0,0,0,0);
			return;
		}

		auto pbs = parent.bounds.size;
		static if(vertical) {
			bounds = Rectangle(
				pbs.x - Scrollbox.barWidth - Scrollbox.barBoarder,
				Scrollbox.barBoarder,
				Scrollbox.barWidth, 
				pbs.y - Scrollbox.barWidth - 2*Scrollbox.barBoarder
				);
		} else {
			bounds = Rectangle(
				Scrollbox.barBoarder,
				pbs.y - Scrollbox.barWidth - Scrollbox.barBoarder,
				pbs.x - Scrollbox.barWidth - 2*Scrollbox.barBoarder, 
				Scrollbox.barWidth
				);
		}
	}
		
	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		if(isShown == false) return;
		static if(vertical) {
			float ssize = parent.bounds.size.y / parent.area.y;
			renderBounds.loc.y += renderBounds.size.y*parent.scroll.y;
			renderBounds.size.y = renderBounds.size.y*ssize;
		} else {
			float ssize = parent.bounds.size.x / parent.area.x;
			renderBounds.loc.x += renderBounds.size.x*parent.scroll.x;
			renderBounds.size.x = renderBounds.size.x*ssize;
		}

		g.drawRectangle(renderBounds, style.scroll);
	}
	
}

class scrollPan:Panel{
	this(){
		canScroll = true;
	}
	override protected void scrollProc(vec2 loc,int s) {
		auto p = cast(Scrollbox)parent;
		p.scroll.y -= s*Scrollbox.scrollAmount / p.area.y;
		invalidate();
	}
}