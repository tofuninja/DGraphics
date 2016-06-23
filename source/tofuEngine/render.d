module tofuEngine.render;


import graphics.color;
import graphics.hw;
import util.integerSeq;
import util.serial2;
import math.matrix;
import math.geo.rectangle;
import math.geo.AABox;
import math.conversion;
import graphics.camera;
import graphics.render.line3Batch;
import graphics.render.sceneuniforms;
import graphics.render.meshBatcher;
import graphics.render.lightBatch;
import tofuEngine.engine;


//	 _____                _           _             
//	|  __ \              | |         (_)            
//	| |__) |___ _ __   __| | ___ _ __ _ _ __   __ _ 
//	|  _  // _ \ '_ \ / _` |/ _ \ '__| | '_ \ / _` |
//	| | \ \  __/ | | | (_| |  __/ |  | | | | | (_| |
//	|_|  \_\___|_| |_|\__,_|\___|_|  |_|_| |_|\__, |
//	                                           __/ |
//	                                          |___/ 


class Renderer {
	uint width = 1920;
	uint height = 1080; 


	SceneUniforms uniforms;
	MeshBatch meshBatch;
	LightBatch lightBatch;
	Camera cam;
	uint meshes_rendered = 0;

	// buffers
	private hwTextureRef!(hwTextureType.tex2D) color;
	private hwTextureRef!(hwTextureType.tex2D) normal;
	private hwTextureRef!(hwTextureType.tex2D) location;
	private hwTextureRef!(hwTextureType.tex2D) id;
	private hwTextureRef!(hwTextureType.tex2D) depth;
	private hwFboRef renderTarget;

	// lighting render target
	private hwTextureRef!(hwTextureType.tex2D) lightAcumulate;
	private hwFboRef lightTarget;


	static if(EDITOR_ENGINE) {
		private Line3Batcher debugLines;
	}

	this() {
		uniforms 	= new SceneUniforms();
		cam 		= Camera(toRad(45.0f), 1, vec3(0,1,0), 0.1f, 400.0f);
		cam.eye 	= vec3(2,2,-5);
		meshBatch	= new MeshBatch(LEVEL_SIZE);
		lightBatch	= new LightBatch(LEVEL_SIZE);
		// set up defered render taget 
		{
			// Color
			{
				hwTextureCreateInfo!() info;
				info.size = uvec3(width,height,1);
				info.format = hwColorFormat.RGB_n8;
				color = hwCreate(info);
			}

			// Normal
			{
				hwTextureCreateInfo!() info;
				info.size = uvec3(width,height,1);
				info.format = hwColorFormat.RGB_f32;
				normal = hwCreate(info);
			}

			// Location
			{
				hwTextureCreateInfo!() info;
				info.size = uvec3(width,height,1);
				info.format = hwColorFormat.RGB_f32;
				location = hwCreate(info);
			}

			// ID (used for other material specific info); 
			{
				hwTextureCreateInfo!() info;
				info.size = uvec3(width,height,1);
				info.format = hwColorFormat.RGBA_u8;
				id = hwCreate(info);
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
				info.colors[1].enabled = true;
				info.colors[1].tex = normal;
				info.colors[2].enabled = true;
				info.colors[2].tex = location;
				info.colors[3].enabled = true;
				info.colors[3].tex = id;
				info.depthstencil.enabled = true;
				info.depthstencil.tex = depth;
				renderTarget = hwCreate(info);
			}
		}
		// set up light render target
		{
			// Color
			{
				hwTextureCreateInfo!() info;
				info.size = uvec3(width,height,1);
				info.format = hwColorFormat.RGB_n8;
				lightAcumulate = hwCreate(info);
			}

			// Render Target
			{
				hwFboCreateInfo info;
				info.colors[0].enabled = true;
				info.colors[0].tex = lightAcumulate;
				lightTarget = hwCreate(info);
			}
		}
	}

	ref Camera getCurrentCamera(){
		//import tofuEngine.components.camera_component;
		//if(currentCam !is null) {
		//    c = currentCam.getCam();
		//}

		cam.aspect = getAspect();
		return cam;
	}

	void render(hwFboRef fbo, iRectangle viewport) {
		// Render Logic here
		auto time = tofu_Clock.getTimeStamp;
		auto v = getViewport;
		auto offset_v = viewport;
		offset_v.loc.y -= height-viewport.size.y;
		offset_v.size = ivec2(width,height);

		Camera c = cam;
		{
			
		}

		c.aspect = getAspect();

		uniforms.projection = c.camMatrix();
		uniforms.size = vec4(float(width), float(height), float(viewport.size.x), float(viewport.size.y));
		uniforms.update();

		hwRenderStateInfo state;
		state.fbo = renderTarget;
		state.viewport = v;
		hwCmd(state);

		hwClearCommand clear;
		clear.colorClear = Color(0,0,0,0);
		clear.depthClear = 1;
		hwCmd(clear);

		uniforms.bind(0);

		meshes_rendered = meshBatch.runBatch(c, v, renderTarget);
		static if(EDITOR_ENGINE) debugLines.run(v, renderTarget); 

		auto lights_renderd = lightBatch.runBatch(c, v, lightTarget, color, normal, location, id);

		{
			vec2 s = cast(vec2) v.size;
			deferedRenderer_draw(color, normal, location, id, lightAcumulate, viewport, fbo, vec2(0,0), s);
		}



		// Print some runtime info
		if(time.totalFrames%60 == 0) {
			import util.dump;
			import std.stdio;
			mixin dump!("time.fps", "meshes_rendered", "lights_renderd");
			stdout.flush();
		}
	}


	final void drawDebugLine(vec3 start, vec3 end, vec3 color) {
		//pragma(inline, true);
		// Only draw debug lines in the editor
		static if(EDITOR_ENGINE) {
			debugLines.drawLine(start,end,color);
		}
	}

	final void drawDebugCube(vec3 center, vec3 size, vec3 c) {
		//pragma(inline, true);
		drawDebugCube(AABox(center, size), c);
	}

	final void drawDebugCube(AABox box, vec3 c) {
		//pragma(inline, true);
		// Only draw debug cubes in the editor
		static if(EDITOR_ENGINE) {
			auto corners = box.getCorners;
			drawDebugLine(corners[0], corners[1],c);
			drawDebugLine(corners[0], corners[2],c);
			drawDebugLine(corners[0], corners[4],c);
			drawDebugLine(corners[1], corners[3],c);
			drawDebugLine(corners[1], corners[5],c);
			drawDebugLine(corners[2], corners[3],c);
			drawDebugLine(corners[2], corners[6],c);
			drawDebugLine(corners[3], corners[7],c);
			drawDebugLine(corners[4], corners[5],c);
			drawDebugLine(corners[4], corners[6],c);
			drawDebugLine(corners[5], corners[7],c);
			drawDebugLine(corners[6], corners[7],c);
		}
	}

	final void drawDebugCube(mat4 transform, vec3 c) {
		//pragma(inline, true);
		// Only draw debug cubes in the editor
		static if(EDITOR_ENGINE) {
			vec3[8] corners;
			corners[0] = (transform*vec4(-1,-1,-1,1)).xyz;
			corners[1] = (transform*vec4( 1,-1,-1,1)).xyz;
			corners[2] = (transform*vec4( 1,-1, 1,1)).xyz;
			corners[3] = (transform*vec4(-1,-1, 1,1)).xyz;
			corners[4] = (transform*vec4(-1, 1,-1,1)).xyz;
			corners[5] = (transform*vec4( 1, 1,-1,1)).xyz;
			corners[6] = (transform*vec4( 1, 1, 1,1)).xyz;
			corners[7] = (transform*vec4(-1, 1, 1,1)).xyz;
			
			drawDebugLine(corners[0], corners[1], c);
			drawDebugLine(corners[1], corners[2], c);
			drawDebugLine(corners[2], corners[3], c);
			drawDebugLine(corners[3], corners[0], c);
			drawDebugLine(corners[4], corners[5], c);
			drawDebugLine(corners[5], corners[6], c);
			drawDebugLine(corners[6], corners[7], c);
			drawDebugLine(corners[7], corners[4], c);
			drawDebugLine(corners[0], corners[4], c);
			drawDebugLine(corners[1], corners[5], c);
			drawDebugLine(corners[2], corners[6], c);
			drawDebugLine(corners[3], corners[7], c);
		}
	}

	final void drawDebugGrid(mat4 m, int size, float gapSize, vec3 c){
		static if(EDITOR_ENGINE) {
			if(size == 0) size = 1;
			for(int i = -size; i <= size; i++){
				auto xstart = (m*vec4(-size*gapSize, 0,    i*gapSize, 1)).xyz;
				auto xend   = (m*vec4( size*gapSize, 0,    i*gapSize, 1)).xyz;
				auto zstart = (m*vec4(    i*gapSize, 0,-size*gapSize, 1)).xyz;
				auto zend   = (m*vec4(    i*gapSize, 0, size*gapSize, 1)).xyz;
				drawDebugLine(xstart, xend, c);
				drawDebugLine(zstart, zend, c);
			}
		}
	}

	final void drawDebugIndicator(mat4 m, float intensity){
		static if(EDITOR_ENGINE) {
			auto o = (m*vec4(0,0,0,1)).xyz;
			auto x = (m*vec4(1,0,0,1)).xyz;
			auto y = (m*vec4(0,1,0,1)).xyz;
			auto z = (m*vec4(0,0,1,1)).xyz;
			drawDebugLine(o,x, vec3(intensity,0,0));
			drawDebugLine(o,y, vec3(0,intensity,0));
			drawDebugLine(o,z, vec3(0,0,intensity));
		}
	}

	float getAspect() {
		auto size = getSize;
		return size.x/size.y;
	}

	vec2 getSize() {
		//return cast(vec2) Game.state.mainViewport.size;
		return vec2(width, height);
	}

	iRectangle getViewport() {
		return iRectangle(0,0, width, height);
	}
}







private bool deferedRenderer_inited = false;
private hwBufferRef deferedRenderer_tri;
private hwVaoRef deferedRenderer_vao;
private hwShaderRef deferedRenderer_shade;

private struct deferedRenderer_vector
{
	vec4 rectangle;
	vec4 uvrectangle;
	float depth;
}

private void initDeferedRenderer() {
	assert(hwState().initialized); 

	// Create vertex buffer
	{
		auto info 			= hwBufferCreateInfo();
		info.size 			= (deferedRenderer_vector.sizeof) * 1; // Only doing one at a time
		info.dynamic 		= true;
		info.data 			= null;
		deferedRenderer_tri	= hwCreate(info);
	}

	// Create VAO
	{
		hwVaoCreateInfo info;
		info.attachments[0].enabled = true;
		info.attachments[0].bindIndex = 0;
		info.attachments[0].elementType = hwVertexType.float32;
		info.attachments[0].elementCount = 4;
		info.attachments[0].offset = deferedRenderer_vector.rectangle.offsetof;

		info.attachments[1].enabled = true;
		info.attachments[1].bindIndex = 0;
		info.attachments[1].elementType = hwVertexType.float32;
		info.attachments[1].elementCount = 4;
		info.attachments[1].offset = deferedRenderer_vector.uvrectangle.offsetof;

		info.attachments[2].enabled = true;
		info.attachments[2].bindIndex = 0;
		info.attachments[2].elementType = hwVertexType.float32;
		info.attachments[2].elementCount = 1;
		info.attachments[2].offset = deferedRenderer_vector.depth.offsetof;

		info.bindPointDivisors[0] = 1;

		deferedRenderer_vao = hwCreate(info);
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

			void main() {
			gl_Position = (vert[gl_VertexID]*vec4(rec.zw,1,1) + vec4(rec.xy, depth, 0));
			gl_Position.y = -gl_Position.y;
			}`;

		string frag = `
			#version 420	
			layout(std140, binding = 0) uniform sceneUniforms
			{
			mat4 projection;
			vec4 size;
			};
			layout(binding = 0) uniform sampler2D color; 
			layout(binding = 1) uniform sampler2D normal; 
			layout(binding = 2) uniform sampler2D location; 
			layout(binding = 3) uniform usampler2D id; 
			layout(binding = 4) uniform sampler2D light; 
			out vec4 fragColor;
			void main() {
			vec2 dif = size.xy - size.zw;
			ivec2 textUV = ivec2(gl_FragCoord.xy + vec2(0, dif.y));
			fragColor = texelFetch(color, textUV, 0)*texelFetch(light, textUV, 0);
			}
			`;
		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		deferedRenderer_shade = hwCreate(info);
	}

	deferedRenderer_inited = true;
}


private void deferedRenderer_draw(hwTextureRef!(hwTextureType.tex2D) color, hwTextureRef!(hwTextureType.tex2D) normal, hwTextureRef!(hwTextureType.tex2D) location, hwTextureRef!(hwTextureType.tex2D) id, hwTextureRef!(hwTextureType.tex2D) lightAcumulate, iRectangle viewport, hwFboRef fbo, vec2 loc, vec2 size) {
	if(!deferedRenderer_inited) 
		initDeferedRenderer();

	// Render a texture out as a quad, this is un-batched

	hwRenderStateInfo state;
	state.mode = hwRenderMode.triangleStrip;
	state.vao = deferedRenderer_vao;
	state.shader = deferedRenderer_shade;
	state.viewport = viewport;
	state.fbo = fbo;
	state.depthTest = false;
	state.depthFunction = hwCmpFunc.greaterEqual;
	state.blend = false;
	hwCmd(state);

	hwVboCommand bind;
	bind.vbo = deferedRenderer_tri;
	bind.stride = deferedRenderer_vector.sizeof;
	hwCmd(bind);
	{
		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 0;
		tex.texture = color;
		hwCmd(tex);
	}
	{
		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 1;
		tex.texture = normal;
		hwCmd(tex);
	}
	{
		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 2;
		tex.texture = location;
		hwCmd(tex);
	}
	{
		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 3;
		tex.texture = id;
		hwCmd(tex);
	}
	{
		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 4;
		tex.texture = lightAcumulate;
		hwCmd(tex);
	}

	hwBufferSubDataInfo sub;
	deferedRenderer_vector[1] tempData;
	{
		loc  = ( (loc*2)/(cast(vec2)viewport.size)) - vec2(1,1);
		size = ((size*2)/(cast(vec2)viewport.size));
		tempData[0].rectangle.xy = loc;
		tempData[0].rectangle.zw = size; 
		tempData[0].uvrectangle = vec4(0,0,1,1);
		tempData[0].depth = 1;
	}

	sub.data = tempData;
	sub.offset = 0;
	deferedRenderer_tri.subData(sub);

	hwDrawCommand draw;
	draw.vertexCount = 4;
	draw.instanceCount = 1;
	hwCmd(draw);

}

