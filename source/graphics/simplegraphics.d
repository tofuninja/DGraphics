module graphics.simplegraphics;

class simplegraphics
{
	import graphics.batchRender.lineBatch;
	import graphics.batchRender.ovalBatch;
	import graphics.batchRender.rectangleBatch;
	import graphics.batchRender.glyphBatch;
	import graphics.hw.game;
	import graphics.font;

	import std.math;
	import math.geo.rectangle;
	import math.matrix;
	import graphics.color;

	private uint currentDepth = 0;
	private lineBatch line;
	private ovalBatch oval;
	private rectangleBatch rect;
	//private textBatch text_batch_1;
	private GlyphBatch text_batch_1;
	private GlyphBatch text_batch_2;
	private fboRef fbo;
	private iRectangle viewport;

	private Rectangle scissor;

	public this(Font text_font, Font icon_font)
	{
		text_batch_1.font = text_font;
		text_batch_2.font = icon_font;
		scissor = Rectangle(-10000, -10000, 20000, 20000);
	}

	/**
	 * Returns a unique depth value on the range -1 to 1
	 * Each call is garanteed to be larger than the previous
	 * 
	 * Used to correctly combine outside rendering with things rendered with 
	 * simplegraphics
	 */
	public float getDepth()
	{
		currentDepth++;
		return currentDepth/(838607.5f) - 1.0f;
	}

	public Font getFont()
	{
		return getFont_1();
	}

	public Font getIconFont()
	{
		return getFont_2();
	}

	public Font getFont_1()
	{
		return text_batch_1.font;
	}

	public Font getFont_2()
	{
		return text_batch_2.font;
	}

	public void setScissor(Rectangle s)
	{
		scissor = s;
	}

	Rectangle addScissor(Rectangle s)
	{
		auto tmp = scissor;
		scissor = clip(scissor, s);
		return tmp;
	}

	public void drawLine(vec2 start, vec2 end, Color c)
	{
		drawLine(start, end, c, 1);
	}

	public void drawLine(vec2 start, vec2 end, Color c, float w)
	{
		float d = getDepth();
		line.postBatch(start, end, c, w, d, scissor);
	}

	public void drawRectangle(fRectangle rectangle, Color c)
	{
		float d = getDepth();
		rect.postBatch(rectangle, c, d, scissor);
	}

	public void drawOval(fRectangle ovalBounds, Color c)
	{
		float d = getDepth();
		oval.postBatch(ovalBounds, c, d, scissor);
	}

	public void drawString(dstring text, vec2 loc, Color c)
	{
		drawString_1(text, loc, c);
	}

	public void drawIconString(dstring text, vec2 loc, Color c)
	{
		drawString_2(text, loc, c);
	}
	private int char_count = 0;
	public void drawString_1(dstring text, vec2 loc, Color c)
	{
		float d = getDepth();
		foreach(LayoutPos g; text_batch_1.font.textLayout(text, loc))
		{
			if(g.glyph == null) continue;

			// Check if char in scissor
			auto r = Rectangle(g.loc + g.glyph.offset, cast(vec2)g.glyph.extent.size);
			if(!scissor.intersects(r)) continue;

			text_batch_1.postBatch(g.glyph, g.loc, c, d, scissor);
		}
	}

	public void drawString_2(dstring text, vec2 loc, Color c)
	{
		float d = getDepth();
		foreach(LayoutPos g; text_batch_2.font.textLayout(text, loc))
		{
			if(g.glyph == null) continue;

			// Check if char in scissor
			auto r = Rectangle(g.loc + g.glyph.offset, cast(vec2)g.glyph.extent.size);
			if(!scissor.intersects(r)) continue;
			
			text_batch_2.postBatch(g.glyph, g.loc, c, d, scissor);
		}
	}

	public void setTarget(fboRef fbo, iRectangle viewport)
	{
		this.fbo = fbo;
		this.viewport = viewport;

		line.fbo = fbo;
		oval.fbo = fbo;
		rect.fbo = fbo;
		text_batch_1.fbo  = fbo;
		text_batch_2.fbo  = fbo;
		
		line.viewport = viewport;
		oval.viewport = viewport;
		rect.viewport = viewport;
		text_batch_1.viewport  = viewport;
		text_batch_2.viewport  = viewport;
	}

	public void getTarget(out fboRef fbo, out iRectangle viewport)
	{
		fbo = this.fbo;
		viewport = this.viewport;
	}

	public void flush()
	{
		import std.stdio;
		line.runBatch();
		oval.runBatch();
		rect.runBatch();
		text_batch_1.runBatch();
		text_batch_2.runBatch();
	}

	public void resetDepth()
	{
		currentDepth = 0;//-1;
	}
}

