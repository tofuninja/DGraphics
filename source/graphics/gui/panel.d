module graphics.gui.panel;
import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

class Panel : div
{
	public bool border = true;
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
}

