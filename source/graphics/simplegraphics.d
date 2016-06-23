module graphics.simplegraphics;

class simplegraphics
{
	import graphics.render.lineBatch;
	import graphics.render.ovalBatch;
	import graphics.render.rectangleBatch;
	import graphics.render.glyphBatch;
	import graphics.hw;
	import graphics.font;

	import std.math;
	import math.geo.rectangle;
	import math.matrix;
	import graphics.color;

	private uint currentDepth = 0;
	private lineBatch line;
	private ovalBatch oval;
	private rectangleBatch rect;
	private GlyphBatch text_batch;
	private hwFboRef fbo;
	private iRectangle viewport;

	private Rectangle scissor;

	public this(Font text_font) {
		text_batch.font = text_font;
		scissor = Rectangle(-10000, -10000, 20000, 20000);
	}

	/**
	 * Returns a unique depth value on the range -1 to 1
	 * Each call is garanteed to be larger than the previous
	 * 
	 * Used to correctly combine outside rendering with things rendered with 
	 * simplegraphics
	 */
	public float getDepth() {
		currentDepth++;
		return currentDepth/(838607.5f) - 1.0f;
	}

	public Font getFont() {
		return text_batch.font;
	}

	public void setScissor(Rectangle s) {
		scissor = s;
	}

	Rectangle addScissor(Rectangle s) {
		auto tmp = scissor;
		scissor = clip(scissor, s);
		return tmp;
	}

	public void drawLine(vec2 start, vec2 end, Color c) {
		drawLine(start, end, c, 1);
	}

	public void drawLine(vec2 start, vec2 end, Color c, float w) {
		float d = getDepth();
		line.postBatch(start, end, c, w, d, scissor);
	}

	public void drawRectangle(fRectangle rectangle, Color c) {
		float d = getDepth();
		rect.postBatch(rectangle, c, d, scissor);
	}

	public void drawOval(fRectangle ovalBounds, Color c) {
		float d = getDepth();
		oval.postBatch(ovalBounds, c, d, scissor);
	}

	private int char_count = 0;

	/// Draws a string, interprets loc as the start of the base line
	public void drawString(dstring text, vec2 loc, Color c) {
		float d = getDepth();
		foreach(LayoutPos g; text_batch.font.textLayout(text, loc)) {
			if(g.glyph == null) continue;

			// Check if char in scissor
			auto r = Rectangle(g.loc + cast(vec2)g.glyph.offset, cast(vec2)g.glyph.extent.size);
			if(!scissor.intersects(r)) continue;

			text_batch.postBatch(g.glyph, g.loc, c, d, scissor);
		}
	}

	/// Excatly the same as drawString, drawString already interprests the loc as the start of the baseline
	public alias drawStringBaseLine = drawString;

	/// The same as drawString but instead of interpreting loc as the start of the base line, it is interpreted as the start of the ascent line
	public void drawStringAscentLine(dstring text, vec2 loc, Color c) { 
		auto f = text_batch.font;
		drawString(text, loc + vec2(0, f.ascent + 1), c);
	}

	/// The same as drawString but instead of interpreting loc as the start of the base line, it is interpreted as the start of the desent line
	public void drawStringDescentLine(dstring text, vec2 loc, Color c) { 
		auto f = text_batch.font;
		drawString(text, loc + vec2(0, f.descent + 1), c);
	}

	/// Draws a string aligned inside a rectangle
	public void drawStringAlignIn(dstring text, Rectangle box, Alignment alignment, Color c) {
		auto f = text_batch.font;
		auto tb = f.measureString(text);
		vec2 p = box.alignIn(tb, alignment);
		drawString(text, p, c); 
	}

	public void setTarget(hwFboRef fbo, iRectangle viewport) {
		this.fbo = fbo;
		this.viewport = viewport;

		line.fbo = fbo;
		oval.fbo = fbo;
		rect.fbo = fbo;
		text_batch.fbo  = fbo;
		
		
		line.viewport = viewport;
		oval.viewport = viewport;
		rect.viewport = viewport;
		text_batch.viewport  = viewport;
		
	}

	public void getTarget(out hwFboRef fbo, out iRectangle viewport) {
		fbo = this.fbo;
		viewport = this.viewport;
	}

	public void flush() {
		import std.stdio;
		line.runBatch();
		oval.runBatch();
		rect.runBatch();
		text_batch.runBatch();
	}

	public void resetDepth() {
		currentDepth = 0;//-1;
	}
}

