module graphics.render.meshBatcher;

import container.clist;
import container.octree;
import math.matrix;
import math.geo.rectangle;
import math.geo.AABox;
import math.geo.frustum;
import graphics.hw;
import graphics.render.sceneuniforms;
import graphics.mesh;
import graphics.camera;
import graphics.color;
import tofuEngine;

//	 __  __           _       ____        _       _     _             
//	|  \/  |         | |     |  _ \      | |     | |   (_)            
//	| \  / | ___  ___| |__   | |_) | __ _| |_ ___| |__  _ _ __   __ _ 
//	| |\/| |/ _ \/ __| '_ \  |  _ < / _` | __/ __| '_ \| | '_ \ / _` |
//	| |  | |  __/\__ \ | | | | |_) | (_| | || (__| | | | | | | | (_| |
//	|_|  |_|\___||___/_| |_| |____/ \__,_|\__\___|_| |_|_|_| |_|\__, |
//	                                                             __/ |
//	                                                            |___/ 


// TODO support textures, will have to furthure sort on texture 
// Seeing as an octree is going to be used to do culling
// changin really of anything about a mesh instance needs to be known

// TODO eventualy support transparent meshes/colors 

private enum OctDepth = 10;

private enum batchSize = 1024;
private bool batcherInted = false;
private hwBufferRef instanceBuffer;
private hwVaoRef vao;
private hwShaderRef shade;



struct MeshInstanceRef
{
	private MeshBatch owner; 
	private CList!(MeshInstance).Node* node;

	void setDebugBox(bool b) {
		MeshInstance* me = &(node.data);
		me.debug_box = b;
	}

	void change(GUID mesh_id, GUID texture_id, mat4 transform, Color color, bool visable) {
		MeshInstance* me = &(node.data);
		bool meshChange = false;

		if(me.mesh_id != mesh_id) {
			if(me.mesh != null) me.mesh.count--;
			me.mesh_id = mesh_id;
			me.mesh = null;

			if(me.texture_id != GUID(null)) {
				if(me.texture != null) me.texture.count--;
				me.texture_id = GUID(null);
				me.texture = null;
			}

			if(mesh_id != GUID(null)) {
				me.mesh = owner.getMeshEntry(mesh_id);
				me.mesh.count++;
			}

			meshChange = true;
		}

		if(me.texture_id != texture_id || meshChange == true) {
			if(me.texture != null) me.texture.count--;
			me.texture_id = texture_id;
			me.texture = null;
			if(me.mesh != null) {
				me.texture = me.mesh.getTextureEntry(texture_id);
				me.texture.count++;
			}
		}


		me.transform = transform;
		me.color = color.to!vec4;

		if(color.A == 0 || me.mesh == null || !visable) {
			me.visible = false;
			if(me.inOctree) {
				owner.octree.removeItem(me.octree_entry);
				me.inOctree = false;
			}
		} else {
			auto bb = me.mesh.mesh.box.transform(me.transform);
			me.box = bb;
			bb.center = bb.center/owner.region;
			bb.size = bb.size/owner.region;
			if(!me.inOctree) {
				me.octree_entry = owner.octree.insert(node, bb.center, bb.size);
				me.inOctree = true;
			} else {
				owner.octree.moveItem(me.octree_entry, bb.center, bb.size);
			}
			me.visible = true;
		}
	}


	/// removes this instance and invalidates it
	void remove() {
		if(node.data.inOctree) owner.octree.removeItem(node.data.octree_entry);
		if(node.data.texture != null) node.data.texture.count--;
		if(node.data.mesh != null)    node.data.mesh.count--;

		owner.instances.removeNode(node);
	}
}










private struct MeshInstance
{
	GUID mesh_id;
	GUID texture_id;
	mat4 transform;
	vec4 color = vec4(1,1,1,1); 
	bool visible = true;

	bool debug_box = false;

	mesh_entry* mesh = null; 
	texture_entry* texture = null;
	bool inOctree = false;
	Octree!(CList!(MeshInstance).Node*, OctDepth).ItemRef octree_entry;

	AABox box;
}



class MeshBatch {
	private float region; // Bound for the octree 
	private CList!MeshInstance instances;
	private CList!mesh_entry meshes;
	private Octree!(CList!(MeshInstance).Node*, OctDepth) octree;

	this(float region_bound) {
		region = region_bound/2;
	}

	MeshInstanceRef makeInstance() {
		auto node = instances.insert(MeshInstance());
		MeshInstanceRef ret;
		ret.node = node;
		ret.owner = this;
		return ret;
	}

	uint runBatch(Camera cam, iRectangle viewport, hwFboRef fbo) {
		auto f = frustum(cam.camMatrix);

		import std.stdio;


		hwRenderStateInfo state;
		state.mode = hwRenderMode.triangles; 
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
		state.depthTest = true;
		state.depthFunction = hwCmpFunc.less;
		state.backFaceCulling = true;
		state.frontOrientation = hwFrontFaceMode.clockwise;
		hwCmd(state);

		// prep the batchers
		foreach(ref m; meshes) {
			foreach(ref t; m.textures) {
				t.batch.startBatch(m.mesh, t.text);
			}
		}

		// Add instances
		uint meshes_rendered = searchOctree(octree.getHead(), f, region);

		// Flush the batchers
		foreach(ref m; meshes) {
			foreach(ref t; m.textures) {
				t.batch.endBatch();
			}
		}
		return meshes_rendered;
	}

	private static bool onFrustum(vec3 center, vec3 size, frustum f, float scale) {
		return f.intersect(AABox(center*scale, size*scale)) <= 0;
	}

	private uint searchOctree(N)(N* root, frustum f, float scale) {
		uint count = 0;
		if(root == null) return 0;
		if(onFrustum(root.center, vec3(root.size*2), f, scale)) {
			foreach(ref n; root.list[]) {
				n.data.data.texture.batch.addInstance(n.data.data);
				if(n.data.data.debug_box) {
					tofu_Graphics.drawDebugCube(n.data.data.box, vec3(1,0,0));
				}
				count++;
			}

			foreach(c; root.children) {
				count += searchOctree(c, f, scale);
			}
		}
		return count;
	}

	mesh_entry* getMeshEntry(GUID id) {
		foreach(ref me; meshes) {
			if(me.id == id) {
				return &me;
			}
		}
		auto n = meshes.insert(mesh_entry(id));
		return &(n.data);
	}
	
}

private struct mesh_entry{
	uint count = 0;

	GUID id;
	CList!texture_entry textures;
	Mesh mesh;

	this(GUID mesh_id) {
		id = mesh_id;
		mesh = tofu_Resources.get!Mesh(id);
	}

	void free() {
		tofu_Resources.free(id);
	}

	texture_entry* getTextureEntry(GUID id) {
		foreach(ref te; textures) {
			if(te.id == id) {
				return &te;
			}
		}
		auto n = textures.insert(texture_entry(id));
		return &(n.data);
	}


}

private struct texture_entry{
	uint count = 0;
	GUID id;
	batcher batch;
	hwTextureRef!(hwTextureType.tex2D) text;
	this(GUID texture_id) {
		id = texture_id;
		text = tofu_Resources.get!(hwTextureRef!(hwTextureType.tex2D))(id);
	}

	void free() {
		tofu_Resources.free(id);
	}
}


private struct batcher{
	instanceVector[batchSize] instance_vectors;
	Mesh mesh;
	hwTextureRef!(hwTextureType.tex2D) text;
	uint currentInstance;

	void startBatch(Mesh mesh, hwTextureRef!(hwTextureType.tex2D) text) {
		this.mesh = mesh;
		this.text = text;
		currentInstance = 0;
	}

	void addInstance(MeshInstance instance) {
		if(!instance.visible) return; 
		instanceVector current;
		current.transform = instance.transform;

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
		initBatcher();
		if(mesh is null) return;

		hwVboCommand bind0;
		bind0.location = 0;
		bind0.vbo = mesh.vec;
		bind0.stride = Mesh.Vector.sizeof;
		hwCmd(bind0);

		hwVboCommand bind1;
		bind1.location = 1;
		bind1.vbo = instanceBuffer;
		bind1.stride = instanceVector.sizeof;
		hwCmd(bind1);

		hwIboCommand bind2;
		bind2.ibo = mesh.index;
		hwCmd(bind2);

		hwTexCommand!(hwTextureType.tex2D) tex;
		tex.location = 0;
		tex.texture = text;
		hwCmd(tex);

		hwBufferSubDataInfo sub;
		sub.data = instance_vectors[0..currentInstance];
		sub.offset = 0;
		instanceBuffer.subData(sub);

		hwDrawIndexedCommand draw;
		draw.vertexCount = mesh.indexCount;
		draw.instanceCount = currentInstance;
		hwCmd(draw);
	}
}





private struct instanceVector
{
	@hwAttachmentLocation(0) mat4 transform; 
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

	// Create VAO
	{
		hwVaoCreateInfo info;
		// Mesh data
		info.hwRegisterAttachments!(Mesh.Vector)(0,0);
		
		// Instance data
		info.hwRegisterAttachments!(instanceVector)(3,1);
		info.bindPointDivisors[1] = 1;

		vao = hwCreate(info);
	}
	
	// Create Shader
	{
		string vert = import("mesh.vert.glsl");
		string frag = import("mesh.frag.glsl");
		
		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = hwCreate(info);
	}

	batcherInted = true;
}

