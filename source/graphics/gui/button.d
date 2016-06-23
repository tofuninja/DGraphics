module graphics.gui.button;

import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;


class Button : div {
	private enum lowerText = true;
	private bool btnDown = false;
	public bool border = true;
	public Alignment alignment = Alignment.center;
	protected void pressProc() {}

	this() {
		canClick = true;
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		auto rbm1 = renderBounds.size - vec2(1, 1);
		auto v1 = renderBounds.loc;
		auto v2 = renderBounds.loc + vec2(rbm1.x, 0);
		auto v3 = renderBounds.loc + vec2(0, rbm1.y);
		auto v4 = renderBounds.loc + rbm1;

		Color darker = style.border_shadow;
		Color lighter = style.border;

		g.drawRectangle(renderBounds, style.button);
		if(border) {
			if(btnDown) {
				g.drawLine(v1, v2, darker,1);
				g.drawLine(v1, v3, darker,1);
				g.drawLine(v3, v4, lighter,1);
				g.drawLine(v2, v4 + vec2(0, 1), lighter,1);
			} else {
				g.drawLine(v1, v2, lighter,1);
				g.drawLine(v1, v3, lighter,1);
				g.drawLine(v3, v4, darker,1);
				g.drawLine(v2, v4 + vec2(0, 1), darker,1);
			}
		}

		auto tb =  g.getFont.measureString(text);
		auto textRec = Rectangle(renderBounds.loc + vec2(2,3), renderBounds.size - vec2(4,4));
		vec2 p = textRec.alignIn(tb, alignment);
		static if(lowerText) if(btnDown) p = p - vec2(1,1);
		g.drawString(text, p, style.text); 
	}

	override protected void clickProc(vec2 loc, hwMouseButton btn, bool down) {
		bool left = btn == hwMouseButton.MOUSE_LEFT || btn == hwMouseButton.MOUSE_DOUBLE;
		if(down && left) {
			btnDown = true;
			invalidate();
		}
		
		if(!down && left) {
			pressProc();
			{
				EventArgs e = {type: EventType.Action};
				doEvent(e);
			}
			btnDown = false;
			invalidate();
		}
	}


	override protected void enterProc(bool enter) {
		if(!enter && btnDown) {
			btnDown = false;
			invalidate();
		}
	}
}

