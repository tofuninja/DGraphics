module graphics.gui.base;
import graphics.gui.div;
import graphics.hw.game;
import graphics.simplegraphics;
import graphics.font;
import math.matrix;
import math.geo.rectangle;

/**
 * Base div, contains its own render buffer where all divs are rendered to
 * 
 */
class Base : div
{
	private texture2DRef color;
	private texture2DRef depth;
	private simplegraphics graph;
	private fboRef renderTarget;
	private bool invalid = true;
	private div focus = null;
	private div hover = null;
	private uint width;
	private uint height;
	public float fontSize = 12.0f;

	//enum styleMember[] style = super.style ~ [styleMember("bounds", "t.bounds = windowBounds")];
	mixin(customStyleMixin(`
			bounds = windowBounds;
		`));

	public Rectangle windowBounds()
	{
		return Rectangle(0,0,Game.state.mainViewport.size.x, Game.state.mainViewport.size.y);
	}

	public void setUp(this T)(uint w, uint h, bool colorAsTexture = false)
	{
		float f_size;
		{
			auto t = stylized(cast(T)this);
			import std.stdio;
			f_size = t.fontSize;
		}

		width = w;
		height = h;

		// Color
		{
			textureCreateInfo!() info;
			info.size = uvec3(w,h,1);
			info.format = colorFormat.RGBA_u8;
			if(!colorAsTexture) info.renderBuffer = true;
			color = Game.createTexture(info);
		}

		// Depth Stencil 
		{
			textureCreateInfo!() info;
			info.size = uvec3(w,h,1);
			info.format = colorFormat.Depth_24_Stencil_8;
			info.renderBuffer = true;
			depth = Game.createTexture(info);
		}

		// Render Target
		{
			fboCreateInfo info;
			info.colors[0].enabled = true;
			info.colors[0].tex = color;
			info.depthstencil.enabled = true;
			info.depthstencil.tex = depth;
			renderTarget = Game.createFbo(info);
		}

		//graph = new simplegraphics(new Font("./assets/fonts/consola.ttf", 14.0f));
		graph = new simplegraphics(
			new Font("./assets/fonts/SourceCodePro-Regular.otf", f_size),
			new Font("./assets/fonts/fontawesome-webfont.ttf", f_size)
			);

		bounds.size.x = w;
		bounds.size.y = h;

		// Automaticly register input handelers to Game
		bool mouseProc(vec2 loc, mouseButton btn, bool down)
		{
			doClick(loc, btn, down);
			return false;
		}
		
		bool keyProc(key k, keyModifier mods, bool down)
		{
			doKey(k, mods, down);
			return false;
		}
		
		bool mouseMoveProc(vec2 loc)
		{
			doHover(loc);
			return false;
		}
		
		bool charProc(dchar c)
		{
			doChar(c);
			return false;
		}

		bool scrollProc(int scroll)
		{
			doScroll(Game.state.mousePos, scroll);
			return false;
		}

		bool windowSizeProc(vec2 size)
		{
			invalidate();
			import graphics.color;
			renderStateInfo state;
			state.fbo = Game.state.mainFbo;
			Game.cmd(state);
			
			// Clear screen to a nice beige :)
			clearCommand clear;
			clear.colorClear = Color(255,255,200,255);
			clear.depthClear = -1;
			Game.cmd(clear);
			
			// UI think, then blit the UI to the main FBO 
			doThink();
			blitToMain();
			
			// Swap buffers and close if we need to
			Game.swapBuffers();
			return false;
		}
		
		Game.onMouseClick += &mouseProc;
		Game.onKey += &keyProc;
		Game.onMouseMove += &mouseMoveProc; 
		Game.onChar += &charProc;
		Game.onWindowSize += &windowSizeProc;
		Game.onScroll += &scrollProc;

		initProc();
	}

	~this()
	{
		Game.destroyFbo(renderTarget);
		Game.destroyTexture(color);
		Game.destroyTexture(depth);
	}

	public fboRef getFBO()
	{
		return renderTarget;
	}

	public texture2DRef getTexture()
	{
		return color;
	}

	override protected void thinkProc() {
		import graphics.color;
		import math.geo.rectangle;
		import std.stdio;

		if(invalid){
			doStylize();
			doAfterStylize();

			renderStateInfo state;
			state.fbo = renderTarget;
			state.viewport = iRectangle(0, 0, width, height);
			state.depthTest = true;
			state.depthFunction = cmpFunc.greaterEqual;
			Game.cmd(state);
			
			clearCommand clear;
			clear.colorClear = background;
			clear.depthClear = -1;
			Game.cmd(clear);

			graph.setTarget(renderTarget, iRectangle(0, 0, width, height));
			graph.resetDepth();
			doDraw(graph, Rectangle(0, 0, bounds.size.x, bounds.size.y));
			graph.flush();
			
			invalid = false;

		}
	}

	public override void doKey(key k, keyModifier mods, bool down)
	{
		if(focus !is null)
		{
			focus.doKey(k, mods, down);
		}
	}

	public override void doChar(dchar c)
	{
		if(focus !is null)
		{
			focus.doChar(c);
		}
	}
	
	public override div doClick(vec2 loc, mouseButton button, bool down)
	{
		div last = null;

		foreach(c; children())
		{
			if(c.bounds.contains(loc)) last = c;
		}

		if(last !is null) last = last.doClick(loc, button, down);

		if(last is null) {
			if(focus !is null) focus.doFocus(false);
			focus = null;
			return null;
		}

		if(last.canFocus) {
			if(focus !is null) focus.doFocus(false);
			focus = last;
			focus.doFocus(true);
		}
		return last;
	}

	public override div doHover(vec2 loc)
	{
		div last = null;
		foreach(c; children)
		{
			if(c.bounds.contains(loc)) last = c;
		}

		if(last is null)
		{
			if(hover !is null) hover.doEnter(false);
			hover = null;
			return null;
		}

		auto temp = last.doHover(loc);

		if(temp !is hover)
		{
			if(hover !is null) hover.doEnter(false);
			hover = temp;
			if(hover !is null) hover.doEnter(true);
		}
		
		return temp;
	}

	override public void invalidate() 
	{
		invalid = true;
	}

	override public simplegraphics getGraphics()
	{
		return graph;
	}

	public void blitToMain()
	{
		renderStateInfo state;
		state.fbo = Game.state.mainFbo;
		state.viewport = Game.state.mainViewport;
		Game.cmd(state);
		blitCommand blit;
		blit.blitColor = true;
		blit.destination = iRectangle(0, Game.state.mainViewport.size.y - height, width, height);
		blit.source = iRectangle(0,0, width, height);
		blit.fbo = renderTarget;
		Game.cmd(blit);
	}

	public void run()
	{
		import graphics.color;
		while(!Game.state.shouldClose)
		{
			renderStateInfo state;
			state.fbo = Game.state.mainFbo;
			state.viewport = Game.state.mainViewport;
			Game.cmd(state);
			
			// Clear screen to a nice beige :)
			clearCommand clear;
			clear.colorClear = Color(255,255,200,255);
			clear.depthClear = -1;
			Game.cmd(clear);
			
			// UI think, then blit the UI to the main FBO 
			doThink();
			blitToMain();
			
			// Swap buffers and close if we need to
			Game.swapBuffers();
			if(Game.state.keyboard[key.ESCAPE]) break;
		}
	}
}

auto startUI(alias baseDiv)(uint w = 1920, uint h = 1080)
{

	auto mainDiv = new baseDiv!(div, div);
	mainDiv.setUp(w,h);

	return mainDiv;
}