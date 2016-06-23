module graphics.render.lightBatch;

//	 _      _       _     _     ____        _       _     
//	| |    (_)     | |   | |   |  _ \      | |     | |    
//	| |     _  __ _| |__ | |_  | |_) | __ _| |_ ___| |__  
//	| |    | |/ _` | '_ \| __| |  _ < / _` | __/ __| '_ \ 
//	| |____| | (_| | | | | |_  | |_) | (_| | || (__| | | |
//	|______|_|\__, |_| |_|\__| |____/ \__,_|\__\___|_| |_|
//	           __/ |                                      
//	          |___/                                       



// closly based on the mesh batcher 

import container.clist;
import container.octree;
import math.matrix;
import math.geo.rectangle;
import math.geo.AABox;
import math.geo.frustum;
import graphics.hw;
import graphics.render.sceneuniforms;
import graphics.camera;
import graphics.color;
import tofuEngine;

private enum OctDepth = 10;

private enum batchSize = 1024;
private bool batcherInted = false;
private hwBufferRef instanceBuffer;
private hwBufferRef sphereBuffer;
private hwBufferRef nolightBuffer;
private hwVaoRef vao;
private hwVaoRef noLightvao;
private hwShaderRef shade;
private hwShaderRef noLightShade;
private uint sphereVertCount = 0;



struct LightInstanceRef{
	private LightBatch owner; 
	private Octree!(LightInstance, OctDepth).ItemRef node;

	void setDebugBox(bool b) {
		LightInstance* me = &(node.data.data);
		me.debug_box = b;
	}

	void change(vec3 loc, float r, Color color, float ambiant, float intensity, bool visable) {
		LightInstance* me = &(node.data.data);
		me.change(loc, r, color, ambiant, intensity, visable);
		auto bb = me.box;
		bb.center = bb.center/owner.region;
		bb.size = bb.size/owner.region;
		owner.octree.moveItem(node, bb.center, bb.size);
	}


	/// removes this instance and invalidates it
	void remove() {
		owner.octree.removeItem(node);
	}
}


private struct LightInstance{
	vec3 loc;
	float r;
	vec3 color = vec3(1,1,1);
	float ambiant;
	float intensity;
	bool visable = true;
	bool debug_box = false;
	AABox box;
	void change(vec3 loc, float r, Color color, float ambiant, float intensity, bool visable) {
		this.loc = loc;
		this.r = r;
		this.color = (color.to!vec4()).xyz;
		this.ambiant = ambiant;
		this.intensity = intensity;
		this.visable = visable;
		this.box = AABox(loc, vec3(r,r,r)*2);
	}
}



class LightBatch {
	private float region; // Bound for the octree 
	private Octree!(LightInstance, OctDepth) octree;
	batcher batch;

	Color globalColor = RGB(255,255,255);
	float globalIntensity = 0;

	this(float region_bound) {
		region = region_bound/2;
	}

	LightInstanceRef makeInstance(vec3 loc, float r, Color color, float ambiant, float intensity, bool visable) {
		LightInstance me;
		me.change(loc, r, color, ambiant, intensity, visable);
		auto bb = me.box;
		bb.center = bb.center/this.region;
		bb.size = bb.size/this.region;
		auto node = octree.insert(me, bb.center, bb.size);
		LightInstanceRef ret;
		ret.node = node;
		ret.owner = this;
		return ret;
	}

	uint runBatch(Camera cam, iRectangle viewport, hwFboRef fbo, hwTextureRef!(hwTextureType.tex2D) color, hwTextureRef!(hwTextureType.tex2D) normal, hwTextureRef!(hwTextureType.tex2D) location, hwTextureRef!(hwTextureType.tex2D) id) {
		initBatcher();
		auto f = frustum(cam.camMatrix);

		import std.stdio;
		{
			hwRenderStateInfo state;
			state.mode = hwRenderMode.triangles;
			state.vao = vao;
			state.shader = shade;
			state.viewport = viewport;
			state.fbo = fbo;
			state.depthTest = false;
			state.backFaceCulling = true;
			state.frontOrientation = hwFrontFaceMode.clockwise;

			state.blend = true;
			state.blendState.srcColor = hwBlendParameter.one;
			state.blendState.dstColor = hwBlendParameter.one;
			state.blendState.srcAlpha = hwBlendParameter.zero;
			state.blendState.dstAlpha = hwBlendParameter.zero;

			hwCmd(state);
		}

		hwClearCommand clear;
		clear.colorClear = Color(0,0,0,0);
		hwCmd(clear);

		hwVboCommand bind0;
		bind0.location = 0;
		bind0.vbo = sphereBuffer;
		bind0.stride = sphereVector.sizeof;
		hwCmd(bind0);

		hwVboCommand bind1;
		bind1.location = 1;
		bind1.vbo = instanceBuffer;
		bind1.stride = instanceVector.sizeof;
		hwCmd(bind1);

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
	
		batch.startBatch(cam);

		// Add instances
		uint lights_rendered = searchOctree(octree.getHead(), f, region);

		// Flush the batchers
		batch.endBatch();

		// override no light pixels
		{
			hwRenderStateInfo state;
			state.mode = hwRenderMode.triangleStrip;
			state.vao = noLightvao;
			state.shader = noLightShade;
			state.viewport = viewport;
			state.fbo = fbo;
			state.depthTest = false;
			state.backFaceCulling = false;
			state.blend = true;
			state.blendState.srcColor = hwBlendParameter.one;
			state.blendState.dstColor = hwBlendParameter.one;
			state.blendState.srcAlpha = hwBlendParameter.zero;
			state.blendState.dstAlpha = hwBlendParameter.zero;

			hwCmd(state);
		}
		{
			nolightVector[1] vecs;
			vecs[0].color = (globalColor.to!vec4()).xyz;
			vecs[0].intensity = globalIntensity;
			hwBufferSubDataInfo sub;
			sub.data = vecs;
			sub.offset = 0;
			nolightBuffer.subData(sub);
		}

		{
			hwVboCommand bind3;
			bind3.location = 0;
			bind3.vbo = nolightBuffer;
			bind3.stride = nolightVector.sizeof;
			hwCmd(bind3);
		}

		hwDrawCommand draw;
		draw.vertexCount = 4;
		hwCmd(draw);

		
		return lights_rendered;
	}

	private static bool onFrustum(vec3 center, vec3 size, frustum f, float scale) {
		return f.intersect(AABox(center*scale, size*scale)) <= 0;
	}

	private uint searchOctree(N)(N* root, frustum f, float scale) {
		uint count = 0;
		if(root == null) return 0;
		if(onFrustum(root.center, vec3(root.size*2), f, scale)) {
			foreach(ref n; root.list[]) {
				if(n.data.visable) {
					if(n.data.debug_box) {
						tofu_Graphics.drawDebugCube(n.data.box, vec3(1,0,0));
					}
					// add to batcher
					batch.addInstance(n.data);

					count++;
				}
			}

			foreach(c; root.children) {
				count += searchOctree(c, f, scale);
			}
		}
		return count;
	}
}




private struct batcher{
	instanceVector[batchSize] instance_vectors;
	uint currentInstance;
	mat4 view;
	mat4 proj;
	void startBatch(Camera cam) {
		currentInstance = 0;
		view = cam.viewMatrix();
		proj = cam.projMatrix();
	}

	void addInstance(LightInstance instance) { 
		instanceVector current;
		current.color = instance.color;
		current.light = (instance.loc ~ instance.r);
		current.ambiant = instance.ambiant;
		current.intensity = instance.intensity;
		
		instance_vectors[currentInstance] = current;
		currentInstance++;
		if(currentInstance == batchSize) {
			flushBatch();
			currentInstance = 0;
		}
	}

	void endBatch() {
		if(currentInstance != 0) flushBatch();
	}

	void flushBatch() {
		hwBufferSubDataInfo sub;
		sub.data = instance_vectors[0..currentInstance];
		sub.offset = 0;
		instanceBuffer.subData(sub);

		hwDrawCommand draw;
		draw.vertexCount = sphereVertCount;
		draw.instanceCount = currentInstance;
		hwCmd(draw);
	}
}





private struct instanceVector
{
	@hwAttachmentLocation(0) vec3 color; 
	@hwAttachmentLocation(1) vec4 light; 
	@hwAttachmentLocation(2) float ambiant; 
	@hwAttachmentLocation(3) float intensity; 
}

private struct sphereVector
{
	@hwAttachmentLocation(0) vec3 loc; 
}

private struct nolightVector{
	@hwAttachmentLocation(0) vec3 color;
	@hwAttachmentLocation(1) float intensity;
}

private void initBatcher() {
	if(batcherInted) return;

	assert(hwState().initialized); 

	// Create instance buffer
	{
		auto info 		= hwBufferCreateInfo();
		info.size 		= (instanceVector.sizeof)*batchSize;
		info.dynamic 	= true;
		info.data 		= null;
		instanceBuffer 	= hwCreate(info);
	}

	// Create sphere buffer
	{
		import math.generation.sphere;
		auto sphere = sphereMesh(3);
		auto info 		= hwBufferCreateInfo();
		info.size 		= cast(uint)((sphereVector.sizeof)*sphere.length);
		info.dynamic 	= false;
		info.data 		= sphere;
		sphereBuffer 	= hwCreate(info);
		sphereVertCount = cast(uint)sphere.length;
	}
	
	// Create nolight buffer
	{
		auto info 		= hwBufferCreateInfo();
		info.size 		= (nolightVector.sizeof)*batchSize;
		info.dynamic 	= true;
		info.data 		= null;
		nolightBuffer 	= hwCreate(info);
	}

	// Create VAO
	{
		hwVaoCreateInfo info;
		// sphere data
		info.hwRegisterAttachments!(sphereVector)(0,0);

		// Instance data
		info.hwRegisterAttachments!(instanceVector)(1,1);
		info.bindPointDivisors[1] = 1;
		vao = hwCreate(info);
	}

	// Create No Light VAO
	{
		hwVaoCreateInfo info;
		info.hwRegisterAttachments!(nolightVector)(0,0);
		info.bindPointDivisors[0] = 1;
		noLightvao = hwCreate(info);
	}

	// Create Shader
	{
		string vert = `
			#version 440

			//const vec4 vert[4] = vec4[](
			//vec4(0,0,0,1),
			//vec4(0,1,0,1),
			//vec4(1,0,0,1),
			//vec4(1,1,0,1)
			//);

			layout(std140, binding = 0) uniform sceneUniforms
			{
				mat4 projection;
				vec4 size;
			};

			layout(location = 0)in vec3 loc;
			layout(location = 1)in vec3 color;
			layout(location = 2)in vec4 light;
			layout(location = 3)in float ambiant;
			layout(location = 4)in float intensity;
			out vec3 fragColor;
			out vec4 fragLight;
			out float fragambiant;
			out float fragintensity;
			void main() {
				vec3 light_loc = light.xyz;
				float r = light.w;

				vec4 pos = projection*vec4(loc*r*1.1f + light_loc,1);

				gl_Position = pos;
				//gl_Position.y = -gl_Position.y;
				fragColor = color;
				fragLight = light;
				fragambiant = ambiant;
				fragintensity = intensity;
			}`;

		string frag = `
			#version 420	

			layout(binding = 0) uniform sampler2D text; 
			layout(binding = 1) uniform sampler2D normal; 
			layout(binding = 2) uniform sampler2D location; 
			layout(binding = 3) uniform usampler2D id; 

			layout(std140, binding = 0) uniform sceneUniforms
			{
				mat4 projection;
				vec4 size;
			};

			in vec3 fragColor;
			in vec4 fragLight;
			in float fragambiant;
			in float fragintensity;
			out vec3 outColor;
			void main() {
				//vec2 dif = size.xy - size.zw;
				ivec2 textUV = ivec2(gl_FragCoord.xy);
				vec3 loc  = texelFetch(location, textUV,0).xyz;
				vec3 norm = texelFetch(normal, textUV,0).xyz;

				vec3 light_loc = fragLight.xyz;
				float light_r  = fragLight.w;
				
				float directional = clamp(dot(norm, normalize(light_loc-loc)), 0.0, 1.0);
				float intensity = (1 - min(length(loc-light_loc)/light_r, 1))*(directional + fragambiant);
				outColor = fragColor*intensity*fragintensity;
			}`;

		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = hwCreate(info);
	}

	// Create No Light Shader
	{
		string vert = `
			#version 440

			const vec4 vert[4] = vec4[](
				vec4(-1,-1,0,1),
				vec4(-1,1,0,1),
				vec4(1,-1,0,1),
				vec4(1,1,0,1)
			);

			layout(location = 0)in vec3 color;
			layout(location = 1)in float intensity;

			out vec3 fragColor;
			out float fragIntensity;
			void main() {
				gl_Position = vert[gl_VertexID];
				fragColor = color;
				fragIntensity = intensity;
			}`;

		string frag = `
			#version 420	

			layout(binding = 0) uniform sampler2D text; 
			layout(binding = 1) uniform sampler2D normal; 
			layout(binding = 2) uniform sampler2D location; 
			layout(binding = 3) uniform usampler2D id; 

			in vec3 fragColor;
			in float fragIntensity;

			out vec3 outColor;
			void main() {
				ivec2 textUV = ivec2(gl_FragCoord.xy);
				float override = float(texelFetch(id, textUV,0) == uvec4(0,0,0,1)); 
				outColor = fragColor*fragIntensity + vec3(1,1,1)*override;
			}`;

		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		noLightShade = hwCreate(info);
	}

	batcherInted = true;
}

