module graphics.gui.label;
import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

class Label : div
{
	public bool border = false;
	public bool back = false;
	public string alignment = "top-left";

	//enum styleMember[] style = super.style ~ [styleMember("bounds", "t.bounds.size = defaultSize(text)")];
	mixin(customStyleMixin(`
			bounds.size = defaultSize(text);
		`));
	
	public vec2 defaultSize(dstring f)
	{
		auto font = getGraphics().getFont();
		auto tb = font.measureString(f);
		return tb.size + vec2(2,2);
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		if(back)
		{
			g.drawRectangle(renderBounds, background);
		}

		if(border)
		{
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

			g.drawLine(v1, v2, lighter,1);
			g.drawLine(v1, v3, lighter,1);
			g.drawLine(v3, v4, darker,1);
			g.drawLine(v2, v4 + vec2(0, 1), darker,1);
		}
		
		auto tb =  g.getFont.measureString(text);
		vec2 p = renderBounds.alignIn(tb, alignment);
		g.drawString(text, p, textcolor); 
	}
}

