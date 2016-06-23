module graphics.render.glyphBatch;

import graphics.render.batcher;
import math.geo.rectangle;
import math.matrix;
import graphics.hw;
import graphics.color;
import graphics.font;

private bool 				inited 		= false;
private enum 				batchSize 	= 1024*10;
private hwBufferRef 			gpu_buffer;
private hwVaoRef 				vao;
private hwShaderRef 			shade;
private vector[batchSize] 	tempData;

private struct vector
{
	vec4 rectangle;
	vec4 uvrectangle;
	vec4 color;
	vec4 scissor;
	float depth;
}


// Init the needed render objects, vbo, shader, vao... 
private void init() {
	assert(hwState().initialized); 
	
	// Create vertex buffer
	{
		auto info 		= hwBufferCreateInfo();
		info.size 		= (vector.sizeof)*batchSize;
		info.dynamic 	= true;
		info.data 		= null;
		gpu_buffer 		= hwCreate(info);
	}
	
	// Create VAO
	{
		hwVaoCreateInfo info;
		info.attachments[0].enabled = true;
		info.attachments[0].bindIndex = 0;
		info.attachments[0].elementType = hwVertexType.float32;
		info.attachments[0].elementCount = 4;
		info.attachments[0].offset = vector.rectangle.offsetof;

		info.attachments[1].enabled = true;
		info.attachments[1].bindIndex = 0;
		info.attachments[1].elementType = hwVertexType.float32;
		info.attachments[1].elementCount = 4;
		info.attachments[1].offset = vector.uvrectangle.offsetof;
		
		info.attachments[2].enabled = true;
		info.attachments[2].bindIndex = 0;
		info.attachments[2].elementType = hwVertexType.float32;
		info.attachments[2].elementCount = 4;
		info.attachments[2].offset = vector.color.offsetof;
		
		info.attachments[3].enabled = true;
		info.attachments[3].bindIndex = 0;
		info.attachments[3].elementType = hwVertexType.float32;
		info.attachments[3].elementCount = 4;
		info.attachments[3].offset = vector.scissor.offsetof;

		info.attachments[4].enabled = true;
		info.attachments[4].bindIndex = 0;
		info.attachments[4].elementType = hwVertexType.float32;
		info.attachments[4].elementCount = 1;
		info.attachments[4].offset = vector.depth.offsetof;
		
		info.bindPointDivisors[0] = 1;
		
		vao = hwCreate(info);
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
			void main() {
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
			void main() {
				float c = texture(text, textUV).x;
				fragColor = vec4(vColor.xyz, c);
				//fragColor = vColor;
			}
			`;
		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = hwCreate(info);
	}
	
	inited = true;
}

struct GlyphBatch
{
	mixin Batcher!(batchSize, Glyph*, vec2, Color, float, Rectangle);
	iRectangle viewport;
	hwFboRef fbo;
	Font font;

	private void doBatch(T)(T range) {
		if(!inited) init();
		//if(glyphBatchCount >= 3) return;
		// Render state for drawing chars 
		hwRenderStateInfo state;
		state.mode = hwRenderMode.triangleStrip;
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
		state.blend = true;
		state.blendState.srcColor = hwBlendParameter.src_alpha;
		state.blendState.dstColor = hwBlendParameter.one_minus_src_alpha;
		state.blendState.srcAlpha = hwBlendParameter.zero;
		state.blendState.dstAlpha = hwBlendParameter.one;
		state.depthTest = true;
		state.depthFunction = hwCmpFunc.greaterEqual;
		state.enableClip[0] = true;
		state.enableClip[1] = true;
		state.enableClip[2] = true;
		state.enableClip[3] = true;
		hwCmd(state);
		
		hwVboCommand bind;
		bind.vbo = gpu_buffer;
		bind.stride = vector.sizeof;
		hwCmd(bind);

		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 0;
		tex.texture = font.texture;
		hwCmd(tex);

		void flushBatch(int count) {
			hwBufferSubDataInfo sub;
			sub.data = tempData[0..count];
			sub.offset = 0;
			gpu_buffer.subData(sub);
			
			hwDrawCommand draw;
			draw.vertexCount = 4;
			draw.instanceCount = count;
			hwCmd(draw);
		}


		vec2 screen_size = cast(vec2)viewport.size;

		int i = 0;
		foreach(b; range) {
			// Flush if we need too
			if(i == batchSize) {
				flushBatch(i);
				i = 0;
			}

			// Give the args names
			Glyph* g 			= b[0];
			vec2 loc			= b[1];
			Color char_color 	= b[2];
			float depth 		= b[3];
			Rectangle scissor 	= b[4];

			// Align loc to a pixel to improve text quality, looks bad if dont
			loc.x = cast(int)loc.x;
			loc.y = cast(int)loc.y;
			scissor.loc = (scissor.loc*2)/screen_size - vec2(1,1);
			scissor.size = (scissor.size*2)/screen_size;
			
			// Check if we have a glyph for the char we are trying to draw
			if(g == null) 	continue; // Cant draw it so move on

			vec2 fontmap_size 		= cast(vec2)font.texture.size.xy; 						// size of the font texture
			vec2 fontmap_char_loc 	= (cast(vec2)g.extent.loc)/fontmap_size;				// location of the char in the font map texture
			vec2 fontmap_char_size 	= (cast(vec2)g.extent.size - vec2(2,2))/fontmap_size;	// size of the char in the font map texture 

			// Calculate the screen loc and size for the char
			vec2 char_offset 	= (cast(vec2)g.offset); 
			vec2 char_pen 		= loc + char_offset;
			vec2 onscreen_loc 	= (char_pen*2)/screen_size - vec2(1,1);
			vec2 onscreen_size 	= ((cast(vec2)g.extent.size - vec2(2,2))*2)/(cast(vec2)viewport.size);

			// Put the render args into the vector array to be flushed later on 
			tempData[i].rectangle.xy = onscreen_loc;
			tempData[i].rectangle.zw = onscreen_size;
			tempData[i].uvrectangle.xy = fontmap_char_loc;
			tempData[i].uvrectangle.zw = fontmap_char_size;
			tempData[i].color = char_color.to!vec4();
			tempData[i].depth = depth;
			tempData[i].scissor.xy = scissor.loc;
			tempData[i].scissor.zw = scissor.size;
			i++;
		}
		flushBatch(i);
	}
}

