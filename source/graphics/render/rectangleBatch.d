module graphics.render.rectangleBatch;
import graphics.render.batcher;
import math.geo.rectangle;
import math.matrix;
import graphics.hw;
import graphics.color;

private bool inited = false;
private enum batchSize = 1024;
private hwBufferRef tri;
private hwVaoRef vao;
private hwShaderRef shade;

private vector[batchSize] tempData;

private struct vector
{
	vec4 rectangle;
	vec4 color;
	vec4 scissor;
	float depth;
}

private void init() {
	assert(hwState().initialized); 

	// Create vertex buffer
	{
		auto info 		= hwBufferCreateInfo();
		info.size 		= (vector.sizeof)*batchSize;
		info.dynamic 	= true;
		info.data 		= null;
		tri 			= hwCreate(info);
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
		info.attachments[1].offset = vector.color.offsetof;

		info.attachments[2].enabled = true;
		info.attachments[2].bindIndex = 0;
		info.attachments[2].elementType = hwVertexType.float32;
		info.attachments[2].elementCount = 4;
		info.attachments[2].offset = vector.scissor.offsetof;

		info.attachments[3].enabled = true;
		info.attachments[3].bindIndex = 0;
		info.attachments[3].elementType = hwVertexType.float32;
		info.attachments[3].elementCount = 1;
		info.attachments[3].offset = vector.depth.offsetof;

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
			layout(location = 1)in vec4 color;
			layout(location = 2)in vec4 scissor;
			layout(location = 3)in float depth;
			out vec4 vColor;
			out float gl_ClipDistance[4];
			void main() {
				vColor = color;
				gl_Position = (vert[gl_VertexID]*vec4(rec.zw,1,1) + vec4(rec.xy, depth, 0));
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
			void main() {
				fragColor = vColor;
			}
			`;
		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = hwCreate(info);
	}

	inited = true;
}

struct rectangleBatch
{
	mixin Batcher!(batchSize, fRectangle, Color, float, Rectangle);
	iRectangle viewport;
	hwFboRef fbo;
	private void doBatch(T)(T range) {
		if(!inited) init();

		hwRenderStateInfo state;
		state.mode = hwRenderMode.triangleStrip;
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
		state.depthTest = true;
		state.depthFunction = hwCmpFunc.greaterEqual;
		state.enableClip[0] = true;
		state.enableClip[1] = true;
		state.enableClip[2] = true;
		state.enableClip[3] = true;
		hwCmd(state);
		
		hwVboCommand bind;
		bind.vbo = tri;
		bind.stride = vector.sizeof;
		hwCmd(bind);

		void flushBatch(int count) {
			hwBufferSubDataInfo sub;
			sub.data = tempData[0..count];
			sub.offset = 0;
			tri.subData(sub);

			hwDrawCommand draw;
			draw.vertexCount = 4;
			draw.instanceCount = count;
			hwCmd(draw);
		}

		int i = 0;
		vec2 screen = cast(vec2)viewport.size;
		foreach(b; range) {
			if(i == batchSize) {
				flushBatch(i);
				i = 0;
			}
			Rectangle scissor = b[3];
			scissor.loc = (scissor.loc*2)/screen - vec2(1,1);
			scissor.size = (scissor.size*2)/screen;

			vec2 loc = ((b[0].loc*2)/(cast(vec2)viewport.size)) - vec2(1,1);
			vec2 size = ((b[0].size*2)/(cast(vec2)viewport.size));
			tempData[i].rectangle.xy = loc;
			tempData[i].rectangle.zw = size;
			tempData[i].color = b[1].to!vec4();
			tempData[i].depth = b[2];
			tempData[i].scissor.xy = scissor.loc;
			tempData[i].scissor.zw = scissor.size;
			i++;
		}
		flushBatch(i);
	}
}

