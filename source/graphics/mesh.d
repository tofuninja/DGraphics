module graphics.mesh;

import std.traits;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;

import derelict.assimp3.assimp;
import math.matrix;
import math.geo.AABox;
import graphics.hw;
import graphics.render.meshBatcher;

version(Windows) {
	private enum assimp_dll	= "assimp.dll";
} else version(linux) {
	static assert(false); // TODO Not testsed
	private enum assimp_dll	= "libassimp.so";
} else {
	static assert(false);
}

version(X86_64) {
	private enum lib_folder = "./libs/libs64/";
} else {
	private enum lib_folder = "./libs/";
}

private bool lib_inited = false;
private void initAssimp() {
	DerelictASSIMP3.load([lib_folder ~ assimp_dll]);
}

string getMeshLoaderVersionString() {
	import std.conv:to;
	if(lib_inited == false) initAssimp();
	uint maj, min, pat;
	maj = aiGetVersionMajor();
	min = aiGetVersionMinor();
	pat = aiGetVersionRevision();
	return "Assimp Version: " ~ maj.to!string ~ "." ~ min.to!string ~ "." ~ pat.to!string;
}


// To simplify things, we will only be focusing on the meshes inside of a scene
// We will not be supporting complex scenes defined in the asset files
// Basicly the assimp scene node heirarchy will be ignored
// If an asset file has more then one mesh, then they are considered to be seperate and unrelated
// That way what we get from loading an asset is just a list of meshes
// The assimp scene system is not helpful for our needs

class Mesh
{
	public struct Vector
	{
		@hwAttachmentLocation(0) vec3 location;
		@hwAttachmentLocation(1) vec3 normal;
		@hwAttachmentLocation(2) vec2 uv;
	}



	public uint vectorCount;
	public uint indexCount;
	public AABox box;


	package hwBufferRef vec;
	package hwBufferRef index;

	/// Load a mesh from file
	public this(S)(S path) if(isSomeString!S) {
		import std.string;
		import std.path;
		import std.conv;
		if(lib_inited == false) initAssimp();
		
		// Convert path to useable form
		auto malloc = Mallocator.instance;
		char[] p = malloc.makeArray!char(path.length + 1);
		scope(exit) malloc.dispose(p);
		foreach(i,v; path) p[i] = v;
		p[$-1] = 0;

		// Load mesh from file with assimp
		const aiScene* scene = aiImportFile(p.ptr, 
			aiProcess_GenNormals			|
			aiProcess_OptimizeMeshes		| 
			aiProcess_OptimizeGraph			|
			aiProcess_Triangulate			|
			aiProcess_JoinIdenticalVertices	|
			aiProcess_SortByPType);

		// If the import failed, throw
		if(!scene) {
			string error = fromStringz(aiGetErrorString()).idup;
			throw new Exception(error);
		}
		scope(exit) aiReleaseImport(scene);
		if(scene.mNumMeshes < 1) throw new Exception("no mesh in file");

		// Now we are free to access the scene
		const aiMesh* m = scene.mMeshes[0];
		bool hasUV = (m.mNumUVComponents[0] == 2);
		// Get the faces, because of aiProcess_Triangulate, can assume the faces are triangles(i hope)
		auto index = malloc.makeArray!uvec3(m.mNumFaces);//new uvec3[m.mNumFaces];
		scope(exit) malloc.dispose(index);
		for(int j = 0; j < m.mNumFaces; j++) 
			index[j] = uvec3(m.mFaces[j].mIndices[0], m.mFaces[j].mIndices[1], m.mFaces[j].mIndices[2]);
		
		// Get the verticies 
		auto vec = malloc.makeArray!Vector(m.mNumVertices);//new Mesh.Vector[m.mNumVertices];
		scope(exit) malloc.dispose(vec);
		for(int j = 0; j < m.mNumVertices; j++) {
			Vector v;
			v.location = vec3(m.mVertices[j].x, m.mVertices[j].y, m.mVertices[j].z);
			v.normal = vec3(m.mNormals[j].x, m.mNormals[j].y, m.mNormals[j].z);
			if(hasUV) v.uv = vec2(m.mTextureCoords[0][j].x, m.mTextureCoords[0][j].y);
			else v.uv = vec2(0,0);
			vec[j] = v;
		}

		this(vec, index);
	}

	/// Create a mesh from a vector and index array
	public this(Vector[] vectors, uvec3[] indices) {
		vectorCount = cast(uint)vectors.length;
		indexCount = cast(uint)indices.length*3;

		// calc aabb
		vec3 min_v;
		vec3 max_v;
		if(vectors.length == 0) {
			min_v = vec3(0);
			max_v = vec3(0);
		} else {
			min_v = vectors[0].location;
			max_v = vectors[0].location;
			foreach(v; vectors) {
				if(v.location.x < min_v.x) min_v.x = v.location.x;
				if(v.location.y < min_v.y) min_v.y = v.location.y;
				if(v.location.z < min_v.z) min_v.z = v.location.z;
				if(v.location.x > max_v.x) max_v.x = v.location.x;
				if(v.location.y > max_v.y) max_v.y = v.location.y;
				if(v.location.z > max_v.z) max_v.z = v.location.z;
			}
		}

		box = AABox(min_v + (max_v - min_v)/2.0f, max_v - min_v);

		// Create vec buffer
		if(vectors.length != 0) {
			auto info 		= hwBufferCreateInfo();
			info.size 		= cast(uint)((Vector.sizeof)*vectors.length);
			info.dynamic 	= false;
			info.data 		= vectors;
			vec 			= hwCreate(info);
		}

		// Create index buffer
		if(indices.length != 0) {
			auto info 		= hwBufferCreateInfo();
			info.size 		= cast(uint)((uvec3.sizeof)*indices.length);
			info.dynamic 	= false;
			info.data 		= indices;
			index 			= hwCreate(info);
		}
	}

	public ~this() {
		hwDestroy(vec);
		hwDestroy(index);
	}
}


private const(char)[] ai2s(const ref aiString s) {
	return s.data[0 .. s.length];
}

