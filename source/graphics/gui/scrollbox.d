module graphics.gui.scrollbox;
import graphics.hw.game;
import graphics.gui.div;
import graphics.gui.panel;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

import std.stdio;

class Scrollbox : div
{
	public bool border = true;
	public vec2 area;
	public vec2 scroll;

	protected scrollbar!(false) horz;
	protected scrollbar!(true) vert;
	package enum barWidth = 6;
	package enum barBoarder = 1;
	package enum scrollAmount = 8;

	mixin(customStyleMixin(`
			foreground = defaultForeColor(background);
		`));

	public this()
	{
		canScroll = true;
	}

	public Color defaultForeColor(Color f)
	{
		auto v = f.to!vec4;
		v = v + vec4(0.1f,0.1f,0.1f,1);
		return v.to!Color;
	}

	override protected void initProc()
	{
		horz = new scrollbar!(false)(this);
		vert = new scrollbar!(true)(this);
		this.addDiv(horz);
		this.addDiv(vert);
	}

	override protected void scrollProc(vec2 loc, int s){
		scroll.y -= s*scrollAmount / area.y;
		invalidate();
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		g.drawRectangle(renderBounds, background);
	}

	override protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {

		if(!border) return;

		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		
		Color darker;
		{
			auto v = background.to!vec4;
			v = v*0.8f;
			darker = v.to!Color;
		}
		
		Color lighter;
		{
			auto v = background.to!vec4;
			v = v*1.1f;
			lighter = v.to!Color;
		}

		g.drawLine(v1, v2, darker,1);
		g.drawLine(v1, v3, darker,1);
		g.drawLine(v3, v4, lighter,1);
		g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
	}

	override public void doStylize()
	{
		stylizeProc();
		onStylize(this);

		float x = 0;
		float y = 0;

		foreach(div d; children())
		{
			if(typeid(d) == typeid(scrollbar!true) || typeid(d) == typeid(scrollbar!false))
				continue;

			d.doStylize();
			if(d.bounds.loc.x + d.bounds.size.x > x) x = d.bounds.loc.x + d.bounds.size.x;
			if(d.bounds.loc.y + d.bounds.size.y > y) y = d.bounds.loc.y + d.bounds.size.y;
		}

		if(y > bounds.size.y)
		{
			vert.isShown = true;
			x += barWidth + barBoarder;
		}
		else vert.isShown = false;

		if(x > bounds.size.x)
		{
			horz.isShown = true;
			y += barWidth + barBoarder;
		}
		else horz.isShown = false;

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
	}

	override public void doDraw(simplegraphics g, Rectangle renderBounds)
	{
		auto t = g.addScissor(renderBounds);
		drawProc(g, renderBounds);
		g.setScissor(t);
		
		t = g.addScissor(renderBounds);
		onDraw(this, g, renderBounds);
		g.setScissor(t);
		
		
		foreach(div d; children())
		{
			t = g.addScissor(renderBounds);
			if(typeid(d) == typeid(scrollbar!true) || typeid(d) == typeid(scrollbar!false))
				d.doDraw(g, Rectangle(renderBounds.loc + d.bounds.loc, d.bounds.size));
			else
				d.doDraw(g, Rectangle(renderBounds.loc + d.bounds.loc - area*scroll, d.bounds.size));
			g.setScissor(t);
		}
		
		t = g.addScissor(renderBounds);
		afterDrawProc(g, renderBounds);
		g.setScissor(t);
	}

	override public div doClick(vec2 loc, mouseButton button, bool down)
	{
		div last = null;
		auto newp1 = loc-bounds.loc;
		auto newp2 = newp1 + area*scroll;
		foreach(c; children)
		{
			if(typeid(c) == typeid(scrollbar!true) || typeid(c) == typeid(scrollbar!false))
			{
				if(c.bounds.contains(newp1)) last = c;
			}
			else 
			{
				if(c.bounds.contains(newp2)) last = c;
			}
		}
		
		if(last !is null){
			if(typeid(last) == typeid(scrollbar!true) || typeid(last) == typeid(scrollbar!false))
				last = last.doClick(newp1, button, down);
			else
				last = last.doClick(newp2, button, down);
		}
		
		if(last is null)
		{
			if(canClick)
			{
				clickProc(newp1, button, down);
				onClick(this, newp1, button, down);
				return this;
			}
			else return null;
		}
		
		return last;
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

	public this(Scrollbox p)
	{
		parent = p;
		canClick = true;
		canScroll = true;
	}

	override protected void scrollProc(vec2 loc, int s){
		static if(vertical)
		{
			parent.scroll.y -= s*Scrollbox.scrollAmount / parent.area.y;
		}
		else
		{
			parent.scroll.x -= s*Scrollbox.scrollAmount / parent.area.x;
		}

		invalidate();
	}
	
	override protected void thinkProc()
	{
		import std.algorithm;
		if(hasClicked)
		{
			if(Game.state.mouseButtons[mouseButton.MOUSE_LEFT] == false)
			{
				hasClicked = false;
				return;
			}

			static if(vertical)
			{
				float ssize = parent.bounds.size.y / parent.area.y;
				parent.scroll.y = clickValue + (Game.state.mousePos.y - gameY)/parent.bounds.size.y;
				//gameY = Game.state.mousePos.y;
				parent.scroll.y = min(parent.scroll.y, 1 - ssize);
				parent.scroll.y = max(parent.scroll.y,0);
			}
			else
			{
				float ssize = parent.bounds.size.x / parent.area.x;
				parent.scroll.x = clickValue + (Game.state.mousePos.x - gameY)/parent.bounds.size.x;
				//gameY = Game.state.mousePos.x;
				parent.scroll.x = min(parent.scroll.x, 1 - ssize);
				parent.scroll.x = max(parent.scroll.x,0);
			}
			invalidate();
		}
	}
	
	override protected void clickProc(vec2 loc, mouseButton button, bool down)
	{
		hasClicked = true;
		
		static if(vertical)
		{
			gameY = Game.state.mousePos.y;
			clickValue = parent.scroll.y;
		}
		else
		{
			gameY = Game.state.mousePos.x;
			clickValue = parent.scroll.x;
		}
		thinkProc();
	}
	
	override protected void stylizeProc()
	{
		if(isShown == false)
		{
			bounds = Rectangle(0,0,0,0);
			return;
		}

		auto pbs = parent.bounds.size;
		static if(vertical)
		{
			bounds = Rectangle(
				pbs.x - Scrollbox.barWidth - Scrollbox.barBoarder,
				Scrollbox.barBoarder,
				Scrollbox.barWidth, 
				pbs.y - Scrollbox.barWidth - 2*Scrollbox.barBoarder
				);
		}
		else
		{
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
		static if(vertical)
		{
			float ssize = parent.bounds.size.y / parent.area.y;
			renderBounds.loc.y += renderBounds.size.y*parent.scroll.y;
			renderBounds.size.y = renderBounds.size.y*ssize;
		}
		else
		{
			float ssize = parent.bounds.size.x / parent.area.x;
			renderBounds.loc.x += renderBounds.size.x*parent.scroll.x;
			renderBounds.size.x = renderBounds.size.x*ssize;
		}

		g.drawRectangle(renderBounds, parent.foreground);
	}
	
}