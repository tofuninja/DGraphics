module graphics.batchRender.lineBatch;

import graphics.batchRender.batcher;
import math.geo.rectangle;
import math.matrix;
import graphics.hw.game;
import graphics.color;

private bool inited = false;
private enum batchSize = 1024;
private bufferRef tri;
private vaoRef vao;
private shaderRef shade;

private vector[batchSize] tempData;

private struct vector
{
	vec4 line;
	vec4 color;
	vec4 scissor;
	float width;
	float depth;
}

private void init() @nogc
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
		info.attachments[0].offset = vector.line.offsetof;
		
		info.attachments[1].enabled = true;
		info.attachments[1].bindIndex = 0;
		info.attachments[1].elementType = vertexType.float32;
		info.attachments[1].elementCount = 4;
		info.attachments[1].offset = vector.color.offsetof;

		info.attachments[2].enabled = true;
		info.attachments[2].bindIndex = 0;
		info.attachments[2].elementType = vertexType.float32;
		info.attachments[2].elementCount = 4;
		info.attachments[2].offset = vector.scissor.offsetof;
		
		info.attachments[3].enabled = true;
		info.attachments[3].bindIndex = 0;
		info.attachments[3].elementType = vertexType.float32;
		info.attachments[3].elementCount = 1;
		info.attachments[3].offset = vector.width.offsetof;

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
			
			const vec2 vert[4] = vec2[](
				vec2(0,-0.5f),
				vec2(0, 0.5f),
				vec2(1,-0.5f),
				vec2(1, 0.5f)
			);

			layout(location = 0)in vec4 line;
			layout(location = 1)in vec4 color;
			layout(location = 2)in vec4 scissor;
			layout(location = 3)in float width;
			layout(location = 4)in float depth;
			out vec4 vColor;
			out float gl_ClipDistance[4];
			void main()
			{
				vec2 dif = line.zw-line.xy;
				float l = length(dif);
				float r = atan(dif.y, dif.x);
				mat2 rot = mat2(cos(r), sin(r), -sin(r), cos(r));
				vec2 scale = vec2(l, width);
				
				vColor = color;
				gl_Position = vec4(line.xy + rot*(vert[gl_VertexID]*scale),depth,1);
				gl_ClipDistance[0] = gl_Position.x - scissor.x;
				gl_ClipDistance[1] = gl_Position.y - scissor.y;
				gl_ClipDistance[2] = scissor.x + scissor.z - gl_Position.x;
				gl_ClipDistance[3] = scissor.y + scissor.w - gl_Position.y;
				gl_Position.y = -gl_Position.y;
			}`;
		
		string frag = `
			#version 420	
			in vec4 vColor;
			out vec4 fragColor;
			void main()
			{
				fragColor = vColor;
			}
			`;
		shaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = Game.createShader(info);
	}
	
	inited = true;
}

struct lineBatch
{
	mixin Batcher!(batchSize, vec2,vec2, Color, float, float, Rectangle);
	iRectangle viewport;
	fboRef fbo;
	private void doBatch(T)(T range)
	{
		if(!inited) init();
		
		renderStateInfo state;
		state.mode = renderMode.triangleStrip;
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
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
		
		int i = 0;
		vec2 screen = cast(vec2)viewport.size;
		foreach(b; range)
		{
			if(i == batchSize)
			{
				flushBatch(i);
				i = 0;
			}
			vec2 start 			= b[0];
			vec2 end 			= b[1];
			Color color 		= b[2];
			float width 		= b[3];
			float depth 		= b[4];
			Rectangle scissor 	= b[5];
			scissor.loc = (scissor.loc*2)/screen - vec2(1,1);
			scissor.size = (scissor.size*2)/screen;

			vec2 v1 = ((start*2 + vec2(1,0))/(viewport.size)) - vec2(1,1);
			vec2 v2 = ((end  *2 + vec2(1,0))/(viewport.size)) - vec2(1,1);
			tempData[i].line.xy = v1;
			tempData[i].line.zw = v2;
			tempData[i].color = color.to!vec4();
			tempData[i].width = width*2/viewport.size.y;
			tempData[i].depth = depth;
			tempData[i].scissor.xy = scissor.loc;
			tempData[i].scissor.zw = scissor.size;

			i++;
		}
		flushBatch(i);
	}
}

