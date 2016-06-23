module graphics.gui.valueSlider;


import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;


class ValueSlider : div
{
	protected bool clicked = false;
	private int defaultHeight = 0;
	private float past = 0;
	private dstring valueText = "0";
	
	bool border = true;
	bool back = true;
	float value = 0.0f;
	float min   = 0.0f;
	float max   = 100.0f;

	this() {
		canClick = true;
		cursor = hwGetSimpleCursor(hwSimpleCursor.hand);
	}

	protected void onChange() {}

	override protected void stylizeProc() {
		bounds.size.y = defaultHeight;
	}

	override protected void initProc() {
		super.initProc;
		auto font = getGraphics().getFont();
		defaultHeight = (font.ascent - font.descent + 4);
		bounds.size.y = defaultHeight;
		{
			import std.algorithm : minV = min, maxV = max;
			value = maxV(min, minV(max, value));
		}
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto font = g.getFont();

		if(back) {
			g.drawRectangle(renderBounds, style.lower);
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

		vec2 p = renderBounds.loc + vec2(2, font.ascent + 2);
		g.drawString(getVstring(), p, style.text_hint);

		{
			auto lp = renderBounds.loc + vec2(((value-min)/(max-min))*renderBounds.size.x, 0);
			auto start = lp;
			auto end = lp + vec2(0,  renderBounds.size.y);
			g.drawLine(start, end, style.border_shadow);
		}
		
	}

	override protected void thinkProc() {
		if(clicked) {
			if(!hwState().mouseButtons[hwMouseButton.MOUSE_LEFT]) { 
				clicked = false;
				invalidate;
			} else {
				import std.algorithm : minV = min, maxV = max;
				import std.math : round;

				float m = round(screenToLocal(hwState().mousePos).x);
				float s = round(bounds.size.x);
				float x = maxV(0.0f, minV(1.0f, m/s));
				value = min + (max-min)*x;
				changeEvent();
				invalidate;
			}
		}
	}

	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		if((btn == hwMouseButton.MOUSE_LEFT || btn == hwMouseButton.MOUSE_DOUBLE) && down)
			clicked = true;
	}

	private void changeEvent() {
		EventArgs e = { type:EventType.ValueChange };
		e.fvalue = value;
		doEvent(e);
		onChange();
	}

	private dstring getVstring() {
		import std.conv : to;
		if(past != value) {
			past = value;
			valueText = value.to!dstring;
		}
		return valueText;
	}
}
