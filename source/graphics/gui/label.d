module graphics.gui.label;
import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

class Label : div
{
	public bool autoSize = true;
	public bool border = false;
	public bool back = false;
	public float pad = 1.0f;
	public Alignment alignment = Alignment.center;

	override protected void stylizeProc() {
		if(autoSize) {
			auto font = getGraphics().getFont();
			auto tb = font.measureString(text);
			bounds.size = tb.size + vec2(pad,pad)*2;
		}
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {

		if(back) {
			g.drawRectangle(renderBounds, style.background);
		}

		if(border) {
			auto rbm1 = renderBounds.size - vec2(1, 1);
			auto v1 = renderBounds.loc;
			auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
			auto v3 = renderBounds.loc + vec2(0, rbm1.y);
			auto v4 = renderBounds.loc + rbm1;
			
			Color darker = style.border_shadow;
			Color lighter = style.border;
			g.drawLine(v1, v2, lighter,1);
			g.drawLine(v1, v3, lighter,1);
			g.drawLine(v3, v4, darker,1);
			g.drawLine(v2, v4 + vec2(0, 1), darker,1);
		}
		
		g.drawStringAlignIn(text, renderBounds, alignment, style.text);
	}
}

