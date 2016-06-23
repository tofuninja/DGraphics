module graphics.gui.checkbox;
import graphics.hw;
import graphics.gui;
import graphics.simplegraphics;
import math.matrix;
import math.geo.rectangle;

class Checkbox : div {
	public bool value;
	private int side;
	private enum dstring no = "\uf204";
	private enum dstring yes = "\uf205";
	private bool hover = false;

	this() {
		canClick = true;
	}

	override protected void initProc() {
		//super.initProc;
		import std.algorithm : max;
		auto f = getGraphics.getFont;
		side = cast(int) max(f.measureString(no).size.x, f.measureString(yes).size.x);
	}
	

	protected void onChange() {}

	override protected void stylizeProc() {
		//super.stylizeProc();
		bounds.size = vec2(side,side);
		//style.lower = style.contrast;
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		//super.drawProc(g,renderBounds);

		//renderBounds.loc = renderBounds.loc + vec2(2,2);
		//renderBounds.size = renderBounds.size - vec2(4,4);
		//if(value) g.drawRectangle(renderBounds, style.text_contrast);
		
		auto color = hover?style.text_hover:style.text_contrast;
		auto text = value?yes:no;
		g.drawStringAlignIn(text, renderBounds, Alignment.center, color);
	}

	override protected void clickProc(vec2 loc, hwMouseButton button, bool down) {
		if(down) {
			value = !value;
			EventArgs e = { type:EventType.ValueChange, down:value };
			doEvent(e);
			onChange();
			invalidate();
		}
	}

	override protected void enterProc(bool enter) {
		hover = enter;
		invalidate();
	}
	
}