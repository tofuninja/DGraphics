module graphics.gui.horizontalSplit;
import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
//import util.event;

class HorizontalSplit : div
{
	public bool border			= true;
	public bool back			= true;
	public bool percentageSplit = false;
	public bool flipSplit 		= false;
	public float split 			= 0;
	public bool allowSlide		= true;

	private float value 		= 0; 
	private enum barSize 		= 4;
	private bool hasClicked 	= false;
	private float gameY;
	private float clickValue;

	public this() {
		canClick = true;
	}

	override protected void initProc() {
		value = split;
		if(allowSlide) cursor = hwGetSimpleCursor(hwSimpleCursor.size_h);
	} 

	public Rectangle leftView() {
		auto s = barStart();
		return Rectangle(0, 0, s, this.bounds.size.y);
	}

	public Rectangle rightView() {
		auto s = barStart();
		s += barSize;
		return Rectangle(s, 0, this.bounds.size.x - s, this.bounds.size.y);
	}

	public override void doStylize() {
		stylizeProc();
		doEventStylize();
		
		// set the first div to the left and the second to the right
		import std.range;
		uint i = 0;
		foreach(c; childrenList[].retro) {
			if(i == 0) c.bounds = leftView();
			else if(i == 1) {
				c.bounds = rightView();
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

			value = clickValue + (hwState().mousePos.x - gameY)/bounds.size.x;
			value = min(value, 1 - barSize/bounds.size.x);
			value = max(value, 0);
			if(flipSplit) value = 1 - value;
			if(!percentageSplit) value *= bounds.size.x;
			invalidate();
		}
	}
	
	override protected void clickProc(vec2 loc, hwMouseButton button, bool down) {
		import std.algorithm;
		if(!allowSlide) return;
		auto s = barStart();
		if(loc.x < s || loc.x > s + barSize) return;
		hasClicked = true;
		gameY = hwState().mousePos.x;
		clickValue = value;
		if(!percentageSplit) clickValue /= bounds.size.x;
		if(flipSplit) clickValue = 1 - clickValue;

		thinkProc();
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		if(back) g.drawRectangle(renderBounds, style.lower);
		auto s = barStart();
		renderBounds.loc.x = renderBounds.loc.x + s;
		renderBounds.size.x = barSize;
		auto rbm1 = renderBounds.size - vec2(1, 0);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;
		g.drawRectangle(renderBounds, style.split);
		Color darker = style.border_split_shadow;
		Color lighter = style.border_split;
		g.drawLine(v1, v3, lighter,1);
		g.drawLine(v2, v4 , darker,1);
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

	private float barStart(){
		import std.algorithm:min,max;
		auto x = bounds.size.x;
		auto s = value;
		if(percentageSplit) s *= x;
		if(flipSplit) s = x - s;
		return  min(max(0,s), x-barSize);
	}
}

