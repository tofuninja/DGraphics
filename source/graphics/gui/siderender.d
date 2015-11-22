module graphics.gui.siderender;

import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

private bool textureQuadRendererInited = false;
private bufferRef tri;
private vaoRef vao;
private shaderRef shade;

// TODO rounding error in viewport calculation? 

/**
 * Renders of to an off screen buffer and displays that as the contents of the div with out the need to re-render the rest of the ui
 * The contents are re-rendered every think
 */
public class SideRender : div
{
	private float myZ;
	private fboRef baseRT;
	private iRectangle baseVP;
	private texture2DRef color;
	private texture2DRef depth;
	private fboRef renderTarget;
	private uint width;
	private uint height;
	private Rectangle viewBounds;

	public this(uint w, uint h)
	{
		setUpRenderTarget(w, h);
	}

	protected void render(fboRef fbo, iRectangle viewport)
	{
		// Render Logic here
		renderStateInfo state;
		state.fbo = fbo;
		state.viewport = viewport;
		Game.cmd(state);
		
		// Clear side render to a nice beige as the default :)
		clearCommand clear;
		clear.colorClear = Color(255,255,200,255);
		clear.depthClear = -1;
		Game.cmd(clear);
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		g.drawRectangle(renderBounds, background);
		
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

	override protected void thinkProc()
	{
		auto pastState = Game.renderState;

		render(renderTarget, iRectangle(0, 0, width, height)); // Render the side render out to an off-screen buffer
		drawTexture(); // Draw the game out to the ui buffer with out needing to re-render the rest of the ui! 

		Game.cmd(pastState);
	}

	private void setUpRenderTarget(uint w, uint h)
	{
		width = w;
		height = h;

		// Color
		{
			textureCreateInfo!() info;
			info.size = uvec3(w,h,1);
			info.format = colorFormat.RGBA_u8;
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

		if(!textureQuadRendererInited) 
			initTextureQuadRenderer();
	}

	private void drawTexture()
	{
		// Draws the game scene out to the screen

		renderStateInfo state;
		state.mode = renderMode.triangleStrip;
		state.vao = vao;
		state.shader = shade;
		state.viewport = baseVP;
		state.fbo = baseRT;
		state.depthTest = true;
		state.depthFunction = cmpFunc.greaterEqual;
		Game.cmd(state);
		
		vboCommand bind;
		bind.vbo = tri;
		bind.stride = vector.sizeof;
		Game.cmd(bind);

		texCommand!(textureType.tex2D) tex;
		tex.location = 0;
		tex.texture = color;
		Game.cmd(tex);
		
		bufferSubDataInfo sub;
		vector[1] tempData;
		{
			vec2 loc = ((viewBounds.loc*2)/(baseVP.size)) - vec2(1,1);
			vec2 size = ((viewBounds.size*2)/(baseVP.size));
			tempData[0].rectangle.xy = loc;
			tempData[0].rectangle.zw = size; 
			tempData[0].uvrectangle = vec4(0,0,1,1);
			tempData[0].depth = myZ;
		}

		sub.data = tempData;
		sub.offset = 0;
		tri.subData(sub);
		
		drawCommand draw;
		draw.vertexCount = 4;
		draw.instanceCount = 1;
		Game.cmd(draw);
		
	}
}

private struct vector
{
	vec4 rectangle;
	vec4 uvrectangle;
	float depth;
}

private void initTextureQuadRenderer()
{
	assert(Game.state.initialized); 
	
	// Create vertex buffer
	{
		auto info 		= bufferCreateInfo();
		info.size 		= (vector.sizeof) * 1; // Only doing one at a time
		info.dynamic 	= true;
		info.data 		= null;
		tri 			= Game.createBuffer(info);
	}
	
	// Create VAO
	{
		vaoCreateInfo info;
		info.attachments[0].enabled = true;
		info.attachments[0].bindIndex = 0;
		info.attachments[0].elementType = vertexType.float32;
		info.attachments[0].elementCount = 4;
		info.attachments[0].offset = vector.rectangle.offsetof;

		info.attachments[1].enabled = true;
		info.attachments[1].bindIndex = 0;
		info.attachments[1].elementType = vertexType.float32;
		info.attachments[1].elementCount = 4;
		info.attachments[1].offset = vector.uvrectangle.offsetof;

		info.attachments[2].enabled = true;
		info.attachments[2].bindIndex = 0;
		info.attachments[2].elementType = vertexType.float32;
		info.attachments[2].elementCount = 1;
		info.attachments[2].offset = vector.depth.offsetof;
		
		info.bindPointDivisors[0] = 1;
		
		vao = Game.createVao(info);
	}
	
	// Create Shader
	{
		string vert = ` 
			#version 330
			
			const vec4 vert[4] = vec4[](
				vec4(0,0,0,1),
				vec4(0,1,0,1),
				vec4(1,0,0,1),
				vec4(1,1,0,1)
			);

			layout(location = 0)in vec4 rec;
			layout(location = 1)in vec4 uvrec;
			layout(location = 2)in float depth;

			out vec2 textUV;

			void main()
			{
				gl_Position = (vert[gl_VertexID]*vec4(rec.zw,1,1) + vec4(rec.xy, depth, 0));
				textUV = vert[gl_VertexID].xy*uvrec.zw + uvrec.xy;
				gl_Position.y = -gl_Position.y;
			}`;
		
		string frag = `
			#version 420	
			in vec2 textUV;

			layout(binding = 0) uniform sampler2D text; 
			out vec4 fragColor;
			void main()
			{
				fragColor = texture(text, textUV);
			}
			`;
		shaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = Game.createShader(info);
	}
	
	textureQuadRendererInited = true;
}

