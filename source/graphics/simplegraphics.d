module graphics.simplegraphics;

class simplegraphics
{
	import graphics.batchRender.lineBatch;
	import graphics.batchRender.ovalBatch;
	import graphics.batchRender.rectangleBatch;
	import graphics.batchRender.textBatch;
	import graphics.hw.game;
	import graphics.font;

	import std.math;
	import math.geo.rectangle;
	import math.matrix;
	import graphics.color;

	private float currentDepth = -1;
	private lineBatch line;
	private ovalBatch oval;
	private rectangleBatch rect;
	private textBatch txt;
	private fboRef fbo;
	private iRectangle viewport;

	private Rectangle scissor;

	public this(Font f)
	{
		txt.font = f;
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
		currentDepth = nextUp(currentDepth);
		currentDepth = nextUp(currentDepth);
		return currentDepth;
	}

	public Font getFont()
	{
		return txt.font;
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
		float d = getDepth();
		txt.postBatch(text, loc, c, d, scissor);
	}

	public void setTarget(fboRef fbo, iRectangle viewport)
	{
		this.fbo = fbo;
		this.viewport = viewport;

		line.fbo = fbo;
		oval.fbo = fbo;
		rect.fbo = fbo;
		txt.fbo  = fbo;
		
		line.viewport = viewport;
		oval.viewport = viewport;
		rect.viewport = viewport;
		txt.viewport  = viewport;
	}

	public void getTarget(out fboRef fbo, out iRectangle viewport)
	{
		fbo = this.fbo;
		viewport = this.viewport;
	}

	public void flush()
	{
		line.runBatch();
		oval.runBatch();
		rect.runBatch();
		txt.runBatch();
	}
}

