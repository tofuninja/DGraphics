module graphics.gui.siderender;

import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
//import util.event;


/**
 * Renders of to an off screen buffer and displays that as the contents of the div with out the need to re-render the rest of the ui
 * The contents are re-rendered every think
 */
public class SideRender : div
{
	private float myZ;
	private hwFboRef baseRT;
	private iRectangle baseVP;
	private hwTextureRef!(hwTextureType.tex2D) color;
	private hwTextureRef!(hwTextureType.tex2D) depth;
	private hwFboRef renderTarget;
	protected uint width;
	protected uint height;
	private Rectangle viewBounds;
	private bool setup = false;

	public this(uint w, uint h, uint colorCount = 1) {
		width = w;
		height = h;
	}

	protected override void initProc() {
		setUpRenderTarget();
	}

	protected void render(hwFboRef fbo, iRectangle viewport) {
		// Defult render

		// Render Logic here
		hwRenderStateInfo state;
		state.fbo = fbo;
		state.viewport = viewport;
		hwCmd(state);
		
		// Clear side render to a nice beige as the default :)
		hwClearCommand clear;
		clear.colorClear = Color(255,255,200,255);
		clear.depthClear = -1;
		hwCmd(clear);
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		//g.drawRectangle(renderBounds, style.background);
		
		// Reserve a z-slice for the off screen buffer to take when we do actually render it
		myZ = g.getDepth();

		// Get the rendertarget and calculate the viewport
		g.getTarget(baseRT, baseVP);
		auto rbi = iRectangle(cast(ivec2)renderBounds.loc, cast(ivec2)renderBounds.size); 
		baseVP.loc.x = cast(int)renderBounds.loc.x;
		baseVP.loc.y = cast(int)(baseVP.size.y - (renderBounds.loc.y + renderBounds.size.y));
		baseVP.size = cast(ivec2)renderBounds.size;

		// set the view of the side render bounds to be centered within the viewport
		viewBounds = Rectangle(vec2(0,0), vec2(width, height));
		viewBounds.loc = center(Rectangle(0,0,bounds.size.x,bounds.size.y), viewBounds);
	}

	override protected void thinkProc() {
		if(!setup) return;
		auto pastState = hwRenderState();

		render(renderTarget, iRectangle(0, 0, width, height)); // Render the side render out to an off-screen buffer

		{
			import graphics.render.textureQuadRenderer;
			drawTexture(color, baseVP, baseRT, viewBounds.loc, viewBounds.size, myZ); // Draw the game out to the ui buffer with out needing to re-render the rest of the ui! 
		}
				
		hwCmd(pastState);
	}			
				
	public Rectangle screenSpaceViewport() {
		return viewBounds;
	}

	uvec2 getVPSize() {
		return uvec2(width, height);
	}

	private void setUpRenderTarget() {
		// Color
		{
			hwTextureCreateInfo!() info;
			info.size = uvec3(width,height,1);
			info.format = hwColorFormat.RGBA_n8;
			color = hwCreate(info);
		}

		// Depth Stencil 
		{
			hwTextureCreateInfo!() info;
			info.size = uvec3(width,height,1);
			info.format = hwColorFormat.Depth_24_Stencil_8;
			info.renderBuffer = true;
			depth = hwCreate(info);
		}

		// Render Target
		{
			hwFboCreateInfo info;
			info.colors[0].enabled = true;
			info.colors[0].tex = color;
			info.depthstencil.enabled = true;
			info.depthstencil.tex = depth;
			renderTarget = hwCreate(info);
		}

		setup = true;
	}
}
