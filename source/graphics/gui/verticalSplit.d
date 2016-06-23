module graphics.gui.verticalSplit;
import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
//import util.event;

class VerticalSplit : div
{
	public bool border				= true;
	public bool back				= true;
	public bool percentageSplit 	= false;
	public bool flipSplit 			= false;
	public float split 				= 0;
	public bool allowSlide		= true;
	
	private float value = 0; 
	private enum barSize = 4;
	private bool hasClicked = false;
	private float gameY;
	private float clickValue;

	public this() {
		canClick = true;
		
	}

	override protected void initProc() {
		value = split;
		if(allowSlide) cursor = hwGetSimpleCursor(hwSimpleCursor.size_v);
	} 

	public Rectangle topView() {
		import std.algorithm;
		auto s = barStart();
		return Rectangle(0, 0, bounds.size.x, s);
	}

	public Rectangle botView() {
		auto s = barStart();
		s += barSize;
		return Rectangle(0, s, bounds.size.x, bounds.size.y-s);
	}

	public override void doStylize() {
		stylizeProc();
		doEventStylize();

		// set the first div to the top and the second to the bot
		import std.range;
		uint i = 0;
		foreach(c; childrenList[].retro) {
			if(i == 0) c.bounds = topView();
			else if(i == 1) {
				c.bounds = botView();
				break;
			}
			i++;
		}

		foreach(div d; childrenList[]) {
			d.doStylize();
		}
	}


	override protected void thinkProc() {
		import std.algorithm;
		if(hasClicked) {
			if(hwState().mouseButtons[hwMouseButton.MOUSE_LEFT] == false) {
				hasClicked = false;
				return;
			}

			value = clickValue + (hwState().mousePos.y - gameY)/bounds.size.y;
			value = min(value, 1 - barSize/bounds.size.y);
			value = max(value, 0);
			if(flipSplit) value = 1 - value;
			if(!percentageSplit) value *= bounds.size.y;
			invalidate();
		}
	}
	
	override protected void clickProc(vec2 loc, hwMouseButton button, bool down) {
		import std.algorithm;
		if(!allowSlide) return;
		auto s = barStart();
		if(loc.y < s || loc.y > s + barSize) return;
		hasClicked = true;
		gameY = hwState().mousePos.y;
		clickValue = value;
		if(!percentageSplit) clickValue /= bounds.size.y;
		if(flipSplit) clickValue = 1 - clickValue;

		thinkProc();
	}

	private float barStart(){
		import std.algorithm:min,max;
		auto y = bounds.size.y;
		auto s = value;
		if(percentageSplit) s *= y;
		if(flipSplit) s = y - s;
		return  min(max(0,s), y-barSize);
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		if(back) g.drawRectangle(renderBounds, style.lower);
		auto s = barStart();
		renderBounds.loc.y += s;
		renderBounds.size.y = barSize;
		auto rbm1 = renderBounds.size - vec2(0, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		g.drawRectangle(renderBounds, style.split);
		Color darker = style.border_split_shadow;
		Color lighter = style.border_split;
		g.drawLine(v1, v2, lighter,1);
		g.drawLine(v3, v4, darker,1);
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
}

