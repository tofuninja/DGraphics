module graphics.gui.button;

import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

class Button : div
{
	private bool btnDown = false;

	public bool border = true;
	public string alignment = "center";
	public Event!(div) onPress;
	protected void pressProc(){}

	this()
	{
		canClick = true;
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
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

		g.drawRectangle(renderBounds, background);
		if(border)
		{
			if(btnDown)
			{
				g.drawLine(v1, v2, darker,1);
				g.drawLine(v1, v3, darker,1);
				g.drawLine(v3, v4, lighter,1);
				g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
			}
			else
			{
				g.drawLine(v1, v2, lighter,1);
				g.drawLine(v1, v3, lighter,1);
				g.drawLine(v3, v4, darker,1);
				g.drawLine(v2, v4 + vec2(0, 1), darker,1);
			}
		}

		auto tb =  g.getFont.measureString(text);
		vec2 p = renderBounds.alignIn(tb, alignment);
		if(btnDown) p = p + vec2(1,1);
		g.drawString(text, p, textcolor); 
	}

	override protected void clickProc(vec2 loc, mouseButton btn, bool down)
	{
		if(down && btn == mouseButton.MOUSE_LEFT)
		{
			btnDown = true;
			invalidate();
		}

		if(!down && btn == mouseButton.MOUSE_LEFT && btnDown)
		{
			pressProc();
			onPress(this);
			btnDown = false;
			invalidate();
		}
	}


	override protected void enterProc(bool enter)
	{
		if(!enter && btnDown)
		{
			btnDown = false;
			invalidate();
		}
	}
}

