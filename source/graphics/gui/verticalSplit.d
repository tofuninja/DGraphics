module graphics.gui.verticalSplit;
import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

// TODO horizontal split
class VerticalSplit : div
{
	public bool percentageSplit = false;
	public bool flipSplit = false;
	public float split = 0;
	private float value = 0; 
	private bool useInit = true;
	private enum barSize = 4;
	private bool hasClicked = false;
	private float gameY;
	private float clickValue;

	public this()
	{
		canClick = true;
	}

	public Rectangle topView(this T)()
	{
		import std.algorithm;
		auto t = stylized(cast(T)this);
		auto y = t.bounds.size.y;
		auto s = useInit? t.split : value;
		if(t.percentageSplit) s *= y;
		if(t.flipSplit) s = y - s;
		s = min(max(0,s), y);

		return Rectangle(0, 0, t.bounds.size.x, s);
	}

	public Rectangle botView(this T)()
	{
		import std.algorithm;
		auto t = stylized(cast(T)this);
		auto y = t.bounds.size.y;
		auto s = useInit? t.split : value;
		if(t.percentageSplit) s *= y;
		if(t.flipSplit) s = y - s;
		s += barSize;
		s = min(max(0,s), y);

		return Rectangle(0, s, t.bounds.size.x, y-s);
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

			value = clickValue + (Game.state.mousePos.y - gameY)/bounds.size.y;
			value = min(value, 1 - barSize/bounds.size.y);
			value = max(value, 0);
			if(flipSplit) value = 1 - value;
			if(!percentageSplit) value *= bounds.size.y;
			invalidate();
		}
	}
	
	override protected void clickProc(vec2 loc, mouseButton button, bool down)
	{
		import std.algorithm;
		auto y = bounds.size.y;
		auto s = value;
		if(percentageSplit) s *= y;
		if(flipSplit) s = y - s;
		s = min(max(0,s), y);
		if(loc.y < s || loc.y > s + barSize) return;

		hasClicked = true;
		gameY = Game.state.mousePos.y;
		clickValue = value;
		if(!percentageSplit) clickValue /= bounds.size.y;
		if(flipSplit) clickValue = 1 - clickValue;

		thinkProc();
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {

		if(useInit)
		{
			value = split;
			useInit = false;
		}

		g.drawRectangle(renderBounds, background);
		import std.algorithm;
		auto y = bounds.size.y;
		auto s = value;
		if(percentageSplit) s *= y;
		if(flipSplit) s = y - s;
		s = min(max(0,s), y);

		renderBounds.loc.y += s;
		renderBounds.size.y = barSize;
		g.drawRectangle(renderBounds, foreground);
		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		
		Color darker;
		{
			auto v = foreground.to!vec4;
			v = v*0.8f;
			darker = v.to!Color;
		}
		
		Color lighter;
		{
			auto v = foreground.to!vec4;
			v = v*1.1f;
			lighter = v.to!Color;
		}
		
		g.drawLine(v1, v2, darker,1);
		g.drawLine(v1, v3, darker,1);
		g.drawLine(v3, v4, lighter,1);
		g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
	}
}

