module graphics.batchRender.textBatch;

import graphics.batchRender.batcher;
import math.geo.rectangle;
import math.matrix;
import graphics.hw.game;
import graphics.color;
import graphics.font;
import std.stdio;

private bool inited = false;
private enum batchSize = 1024;
private bufferRef tri;
private vaoRef vao;
private shaderRef shade;

private vector[batchSize] tempData;

private struct vector
{
	vec4 rectangle;
	vec4 uvrectangle;
	vec4 color;
	vec4 scissor;
	float depth;
}

private void init()
{
	assert(Game.state.initialized); 
	
	// Create vertex buffer
	{
		auto info 		= bufferCreateInfo();
		info.size 		= (vector.sizeof)*batchSize;
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
		info.attachments[2].elementCount = 4;
		info.attachments[2].offset = vector.color.offsetof;
		
		info.attachments[3].enabled = true;
		info.attachments[3].bindIndex = 0;
		info.attachments[3].elementType = vertexType.float32;
		info.attachments[3].elementCount = 4;
		info.attachments[3].offset = vector.scissor.offsetof;

		info.attachments[4].enabled = true;
		info.attachments[4].bindIndex = 0;
		info.attachments[4].elementType = vertexType.float32;
		info.attachments[4].elementCount = 1;
		info.attachments[4].offset = vector.depth.offsetof;
		
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
			layout(location = 2)in vec4 color;
			layout(location = 3)in vec4 scissor;
			layout(location = 4)in float depth;
			out vec4 vColor;
			out vec2 textUV;
			out float gl_ClipDistance[4];
			void main()
			{
				vColor = color;
				gl_Position = (vert[gl_VertexID]*vec4(rec.zw,1,1) + vec4(rec.xy, depth, 0));

				gl_ClipDistance[0] = gl_Position.x - scissor.x;
				gl_ClipDistance[1] = gl_Position.y - scissor.y;
				gl_ClipDistance[2] = scissor.x + scissor.z - gl_Position.x;
				gl_ClipDistance[3] = scissor.y + scissor.w - gl_Position.y;

				gl_Position.y = -gl_Position.y;
				textUV = vert[gl_VertexID].xy*uvrec.zw + uvrec.xy;
			}`;
		
		string frag = `
			#version 420	
			in vec4 vColor;
			in vec2 textUV;

			layout(binding = 0) uniform sampler2D text; 
			out vec4 fragColor;
			void main()
			{
				float c = texture(text, textUV).x;
				fragColor = vec4(vColor.xyz, c);
				//fragColor = vColor;
			}
			`;
		shaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = Game.createShader(info);
	}
	
	inited = true;
}

struct textBatch
{
	mixin Batcher!(batchSize, dstring, vec2, Color, float, Rectangle);
	iRectangle viewport;
	fboRef fbo;
	Font font;

	private void doBatch(T)(T range)
	{
		if(!inited) init();
		renderStateInfo state;
		state.mode = renderMode.triangleStrip;
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
		state.blend = true;
		state.blendState.srcColor = blendParameter.src_alpha;
		state.blendState.dstColor = blendParameter.one_minus_src_alpha;
		state.depthTest = true;
		state.depthFunction = cmpFunc.greaterEqual;
		state.enableClip[0] = true;
		state.enableClip[1] = true;
		state.enableClip[2] = true;
		state.enableClip[3] = true;
		Game.cmd(state);
		
		vboCommand bind;
		bind.vbo = tri;
		bind.stride = vector.sizeof;
		Game.cmd(bind);

		texCommand!(textureType.tex2D) tex;
		tex.location = 0;
		tex.texture = font.texture;
		Game.cmd(tex);
		
		void flushBatch(int count)
		{
			bufferSubDataInfo sub;
			sub.data = tempData[0..count];
			sub.offset = 0;
			tri.subData(sub);
			
			drawCommand draw;
			draw.vertexCount = 4;
			draw.instanceCount = count;
			Game.cmd(draw);
		}


		vec2 screen = cast(vec2)viewport.size;
		float tabWidth = font.glyphs[' '].advance.x * 5; // Width of 5 spaces

		int i = 0;
		foreach(b; range)
		{
			dstring s = b[0];
			vec2 textloc = b[1];

			// Align it to a pixel to improve text quality
			textloc.x = cast(int)textloc.x;
			textloc.y = cast(int)textloc.y;
			Color c = b[2];
			float depth = b[3];
			Rectangle scissor = b[4];
			scissor.loc = (scissor.loc*2)/screen - vec2(1,1);
			scissor.size = (scissor.size*2)/screen;
			vec2 lineStart = textloc;
			int lineCount = 0; 
			foreach(dc; s)
			{
				if(i == batchSize)
				{
					flushBatch(i);
					i = 0;
				}



				// Special chars
				if(dc == '\r') continue;
				if(dc == '\n') {
					lineCount++;
					textloc = lineStart + vec2(0, font.lineHeight*lineCount);
					continue;
				}
				if(dc == '\t')
				{
					import std.math;
					textloc.x = ceil((textloc.x + 1 - lineStart.x)/tabWidth)*tabWidth + lineStart.x;
					continue;
				}



				auto gp = dc in font.glyphs;
				Glyph g;
				if(gp) 	g = *gp;
				else 	g = font.glyphs['█'];

				vec2 texSize = cast(vec2)font.texture.size.xy;
				vec2 texLoc = (cast(vec2)g.extent.loc)/texSize;
				vec2 texExt = (cast(vec2)g.extent.size - vec2(2,2))/texSize;

				vec2 offset = (cast(vec2)g.offset); 
				vec2 pen = textloc + offset;
				vec2 loc = (pen*2)/screen - vec2(1,1);
				vec2 size = ((cast(vec2)g.extent.size - vec2(2,2))*2)/(viewport.size);

				textloc = textloc + cast(vec2)g.advance;

				tempData[i].rectangle.xy = loc;
				tempData[i].rectangle.zw = size;
				tempData[i].uvrectangle.xy = texLoc;
				tempData[i].uvrectangle.zw = texExt;
				tempData[i].color = c.to!vec4();
				tempData[i].depth = depth;
				tempData[i].scissor.xy = scissor.loc;
				tempData[i].scissor.zw = scissor.size;
				i++;
			}
		}
		flushBatch(i);
	}
}

