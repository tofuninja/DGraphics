module graphics.render.textureQuadRenderer;

import graphics.hw;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

private bool textureQuadRendererInited = false;
private hwBufferRef tri;
private hwVaoRef vao;
private hwShaderRef shade;

private struct vector
{
	vec4 rectangle;
	vec4 uvrectangle;
	float depth;
}

private void initTextureQuadRenderer() {
	assert(hwState().initialized); 

	// Create vertex buffer
	{
		auto info 		= hwBufferCreateInfo();
		info.size 		= (vector.sizeof) * 1; // Only doing one at a time
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
		info.attachments[1].offset = vector.uvrectangle.offsetof;

		info.attachments[2].enabled = true;
		info.attachments[2].bindIndex = 0;
		info.attachments[2].elementType = hwVertexType.float32;
		info.attachments[2].elementCount = 1;
		info.attachments[2].offset = vector.depth.offsetof;

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
			layout(location = 2)in float depth;

			out vec2 textUV;

			void main() {
			gl_Position = (vert[gl_VertexID]*vec4(rec.zw,1,1) + vec4(rec.xy, depth, 0));
			textUV = vert[gl_VertexID].xy*uvrec.zw + uvrec.xy;
			textUV.y = 1 - textUV.y;
			gl_Position.y = -gl_Position.y;
			}`;

		string frag = `
			#version 420	
			in vec2 textUV;

			layout(binding = 0) uniform sampler2D text; 
			out vec4 fragColor;
			void main() {
			fragColor = texture(text, textUV);
			}
			`;
		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = hwCreate(info);
	}

	textureQuadRendererInited = true;
}


void drawTexture(hwTextureRef!(hwTextureType.tex2D) texture, iRectangle viewport, hwFboRef fbo, vec2 loc, vec2 size, float depth, bool blend = false, bool depth_test = true) {
	if(!textureQuadRendererInited) 
		initTextureQuadRenderer();

	// Render a texture out as a quad, this is un-batched

	hwRenderStateInfo state;
	state.mode = hwRenderMode.triangleStrip;
	state.vao = vao;
	state.shader = shade;
	state.viewport = viewport;
	state.fbo = fbo;
	if(depth_test) {
		state.depthTest = true;
		state.depthFunction = hwCmpFunc.greaterEqual;
	}
	if(blend) {
		state.blend = true;
		state.blendState.srcColor = hwBlendParameter.src_alpha;
		state.blendState.dstColor = hwBlendParameter.one_minus_src_alpha;
		state.blendState.srcAlpha = hwBlendParameter.zero;
		state.blendState.dstAlpha = hwBlendParameter.one;
	}
	hwCmd(state);

	hwVboCommand bind;
	bind.vbo = tri;
	bind.stride = vector.sizeof;
	hwCmd(bind);

	hwTexCommand!(hwTextureType.tex2D) tex;
	tex.location = 0;
	tex.texture = texture;
	hwCmd(tex);

	hwBufferSubDataInfo sub;
	vector[1] tempData;
	{
		loc  = ( (loc*2)/(cast(vec2)viewport.size)) - vec2(1,1);
		size = ((size*2)/(cast(vec2)viewport.size));
		tempData[0].rectangle.xy = loc;
		tempData[0].rectangle.zw = size; 
		tempData[0].uvrectangle = vec4(0,0,1,1);
		tempData[0].depth = depth;
	}

	sub.data = tempData;
	sub.offset = 0;
	tri.subData(sub);

	hwDrawCommand draw;
	draw.vertexCount = 4;
	draw.instanceCount = 1;
	hwCmd(draw);

}