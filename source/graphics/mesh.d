module graphics.mesh;

import editor.io;
import derelict.assimp3.assimp;
import math.matrix;
import math.geo.rectangle;
import container.clist;
import graphics.hw.game;


// To simplify things, we will only be focusing on the meshes inside of a scene
// We will not be supporting complex scenes defined in the asset files
// Basicly the assimp scene node heirarchy will be ignored
// If an asset file has more then one mesh, then they are considered to be seperate and unrelated
// That way what we get from loading an asset is just a list of meshes
// The assimp scene system is not helpful for our needs

struct meshID
{
	string name;
	uint index;
}

class Mesh
{
	public struct Vector
	{
		@attachmentLocation(0) vec3 location;
		@attachmentLocation(1) vec3 normal;
		@attachmentLocation(2) vec2 uv;
	}

	public meshID id;

	public uint vectorCount;
	public uint indexCount;
	private bufferRef vec;
	private bufferRef index;

	public this(meshID id, Vector[] vectors, uvec3[] indices)
	{
		this.id = id;
		vectorCount = vectors.length;
		indexCount = indices.length*3;

		// Create vec buffer
		{
			auto info 		= bufferCreateInfo();
			info.size 		= (Vector.sizeof)*vectors.length;
			info.dynamic 	= false;
			info.data 		= vectors;
			vec 			= Game.createBuffer(info);
		}

		// Create index buffer
		{
			auto info 		= bufferCreateInfo();
			info.size 		= (uvec3.sizeof)*indices.length;
			info.dynamic 	= false;
			info.data 		= indices;
			index 			= Game.createBuffer(info);
		}
	}

	public ~this()
	{
		Game.destroyBuffer(vec);
		Game.destroyBuffer(index);
	}
}

Mesh[] loadMeshAsset(string file, string root = "./assets/meshes/")
{
	import std.string;
	import std.path;
	import std.conv;

	// Load mesh from file with assimp
	const aiScene* scene = aiImportFile( (root ~ file).toStringz(), 
		aiProcess_GenNormals			|
		aiProcess_OptimizeMeshes		| 
		aiProcess_OptimizeGraph			|
		aiProcess_Triangulate			|
		aiProcess_JoinIdenticalVertices	|
		aiProcess_SortByPType);

	// If the import failed, throw
	if(!scene)
	{
		string error = fromStringz(aiGetErrorString()).idup;
		throw new Exception(error);
	}

	scope(exit) aiReleaseImport(scene);
	// Now we are free to access the scene
	Mesh[] ret = new Mesh[scene.mNumMeshes];

	for(int i = 0; i < scene.mNumMeshes; i++)
	{
		const aiMesh* m = scene.mMeshes[i];

		bool hasUV = (m.mNumUVComponents[0] == 2);

		// Get the faces, because of aiProcess_Triangulate, can assume the faces are triangles(i hope)
		auto index = new uvec3[m.mNumFaces];
		for(int j = 0; j < m.mNumFaces; j++) 
			index[j] = uvec3(m.mFaces[j].mIndices[0], m.mFaces[j].mIndices[1], m.mFaces[j].mIndices[2]);
		
		// Get the verticies 
		auto vec = new Mesh.Vector[m.mNumVertices];
		for(int j = 0; j < m.mNumVertices; j++)
		{
			Mesh.Vector v;
			v.location = vec3(m.mVertices[j].x, m.mVertices[j].y, m.mVertices[j].z);
			v.normal = vec3(m.mNormals[j].x, m.mNormals[j].y, m.mNormals[j].z);
			if(hasUV) v.uv = vec2(m.mTextureCoords[0][j].x, m.mTextureCoords[0][j].y);
			else v.uv = vec2(0,0);
			vec[j] = v;
		}

		ret[i] = new Mesh(meshID(file, i), vec, index);
	}
	
	return ret;
}

private const(char)[] ai2s(const ref aiString s)
{
	return s.data[0 .. s.length];
}


//	  _____                       _    _       _  __                         
//	 / ____|                     | |  | |     (_)/ _|                        
//	| (___   ___ ___ _ __   ___  | |  | |_ __  _| |_ ___  _ __ _ __ ___  ___ 
//	 \___ \ / __/ _ \ '_ \ / _ \ | |  | | '_ \| |  _/ _ \| '__| '_ ` _ \/ __|
//	 ____) | (_|  __/ | | |  __/ | |__| | | | | | || (_) | |  | | | | | \__ \
//	|_____/ \___\___|_| |_|\___|  \____/|_| |_|_|_| \___/|_|  |_| |_| |_|___/
//	                                                                         
//	                                                                         
class SceneUniforms
{
	public struct uniformData
	{
		mat4 projection;
	}
	public bufferRef buffer;
	public uniformData data;
	alias data this;

	public this()
	{
		auto info 		= bufferCreateInfo();
		info.size 		= (uniformData.sizeof);
		info.dynamic 	= true;
		info.data 		= null;
		buffer 			= Game.createBuffer(info);
	}

	public ~this()
	{
		Game.destroyBuffer(buffer);
	}

	public void update()
	{
		bufferSubDataInfo info;
		uniformData[1] d = data;
		info.data = d;
		buffer.subData(info);
	}
}




//	 __  __           _       ____        _       _     _             
//	|  \/  |         | |     |  _ \      | |     | |   (_)            
//	| \  / | ___  ___| |__   | |_) | __ _| |_ ___| |__  _ _ __   __ _ 
//	| |\/| |/ _ \/ __| '_ \  |  _ < / _` | __/ __| '_ \| | '_ \ / _` |
//	| |  | |  __/\__ \ | | | | |_) | (_| | || (__| | | | | | | | (_| |
//	|_|  |_|\___||___/_| |_| |____/ \__,_|\__\___|_| |_|_|_| |_|\__, |
//	                                                             __/ |
//	                                                            |___/ 

private enum batchSize = 1024;
private bool batcherInted = false;
private bufferRef instanceBuffer;
private vaoRef vao;
private shaderRef shade;

public struct MeshBatch
{
	public CList!(MeshInstance*) instances;
	public Mesh mesh;
	public this(Mesh m)
	{
		mesh = m;
	}

	public void runBatch(SceneUniforms uniforms, iRectangle viewport, fboRef fbo) 
	{
		initBatcher();
		if(mesh is null) return;
		// Iterate the instances and draw each one
		instanceVector[batchSize] tempData;

		renderStateInfo state;
		state.mode = renderMode.triangles; 
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
		state.depthTest = true;
		state.depthFunction = cmpFunc.less;
		state.backFaceCulling = true;
		state.frontOrientation = frontFaceMode.clockwise;
		Game.cmd(state);
		
		vboCommand bind0;
		bind0.location = 0;
		bind0.vbo = mesh.vec;
		bind0.stride = Mesh.Vector.sizeof;
		Game.cmd(bind0);

		vboCommand bind1;
		bind1.location = 1;
		bind1.vbo = instanceBuffer;
		bind1.stride = instanceVector.sizeof;
		Game.cmd(bind1);

		iboCommand bind2;
		bind2.ibo = mesh.index;
		Game.cmd(bind2);

		uboCommand bind3;
		bind3.location = 0;
		bind3.size = SceneUniforms.uniformData.sizeof;
		bind3.ubo = uniforms.buffer;
		Game.cmd(bind3);

		void flushBatch(int count)
		{
			bufferSubDataInfo sub;
			sub.data = tempData[0..count];
			sub.offset = 0;
			instanceBuffer.subData(sub);

			drawIndexedCommand draw;
			draw.vertexCount = mesh.indexCount;
			draw.instanceCount = count;
			Game.cmd(draw);
		}

		int currentInstance = 0;
		foreach(MeshInstance* instance; instances[])
		{
			if(instance.visible)
			{
				tempData[currentInstance].transform = instance.transform;

				currentInstance++;
				if(currentInstance == batchSize)
				{
					flushBatch(batchSize);
					currentInstance = 0;
				}
			}
		}
		if(currentInstance > 0) flushBatch(currentInstance);
	}
}


public struct MeshInstance
{
	// Information needed for rendering the instance
	public bool visible = true;
	public mat4 transform; // Location, rotation, scale
	// Maybe add color
	// Going to need to add bone transform information as well
}

private struct instanceVector
{
	@attachmentLocation(0) mat4 transform; 
}

private void initBatcher()
{
	if(batcherInted) return;

	assert(Game.state.initialized); 

	// Create instance buffer
	{
		auto info 		= bufferCreateInfo();
		info.size 		= (instanceVector.sizeof)*batchSize;
		info.dynamic 	= true;
		info.data 		= null;
		instanceBuffer 	= Game.createBuffer(info);
	}

	// Create VAO
	{
		vaoCreateInfo info;
		// Mesh data
		info.registerAttachments!(Mesh.Vector)(0,0);
		
		// Instance data
		info.registerAttachments!(instanceVector)(3,1);
		info.bindPointDivisors[1] = 1;

		vao = Game.createVao(info);
	}
	
	// Create Shader
	{
		string vert = import("mesh.vert.glsl");
		string frag = import("mesh.frag.glsl");
		
		shaderCreateInfo info;
		info.vertShader = vert;
		info.fragShader = frag;
		shade = Game.createShader(info);
	}

	batcherInted = true;
}