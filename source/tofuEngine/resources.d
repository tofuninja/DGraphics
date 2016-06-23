module tofuEngine.resources;

import std.path;
import std.file;
import std.stdio;
import std.range;
import std.traits;
import std.meta;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import graphics.mesh;
import graphics.image;
import graphics.hw;
import util.integerSeq;
import tofuEngine.level;
import tofuEngine.engine;

private alias alloc = Mallocator.instance;


//	 _____                                      __  __                                              _    
//	|  __ \                                    |  \/  |                                            | |   
//	| |__) |___  ___  ___  _   _ _ __ ___ ___  | \  / | __ _ _ __   __ _  __ _  ___ _ __ ___  _ __ | |_  
//	|  _  // _ \/ __|/ _ \| | | | '__/ __/ _ \ | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '_ ` _ \| '_ \| __| 
//	| | \ \  __/\__ \ (_) | |_| | | | (_|  __/ | |  | | (_| | | | | (_| | (_| |  __/ | | | | | | | | |_  
//	|_|  \_\___||___/\___/ \__,_|_|  \___\___| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_| |_| |_|_| |_|\__| 
//	                                                                      __/ |                          
//	                                                                     |___/                           
// TODO would be awesome to be able to have dll's be a resource type that could be loaded to add component types
// TODO do level loading (".lev") for the level data

/// Keeps track of all the resources, one instance per engine 
class ResourceManager {
	public string rootFolder;
	public Resource[GUID] resources;
	private ResourceValueTypes default_resources;

	this(string root) {
		rootFolder = root;

		// init defaults 
		foreach(i; IntegerSeq!(0, ResourceValueTypes.length)) {
			default_resources[i] = ResourceTypes[i].getDef();
		}
		setFolder();
	}

	/**
	* Will begin tracking the resources in the path
	* 
	* If there is a conflict, aka a resorce in the path with a GUID already being tracked
	* then the new one replaces the old one
	*/ 
	package void setFolder() {
		// iterate all the resources, there should only ever be one resource in each file 
		// each resource should have a specific extension to identify the resource type
		// only known resource types will be tracked
		import std.array;
		import std.conv;
		resources = null;

		// Holy crap, using a fileDiologBox changes the cwd 
		// So if a fileDiologBox gets opened before the engine is started, it mucks every thing up...
		// Set the cwd to the exe dir 
		chdir(thisExePath().dirName);


		string path = rootFolder.asAbsolutePath.asNormalizedPath.array;
		rootFolder = "";
		if(extension(path).length != 0) return;
		if(!exists(path)) return;
		if(!isDir(path)) return;
		rootFolder = path;

		refresh();
	}

	package auto load_res(T)(GUID id) {
		auto p = id in resources;
		if(p != null) {
			if(auto c = cast(T)(*p)) {
				if(c.ref_count == 0) {
					c.load();
				}
				c.ref_count++;
				return c;
			}
		}
		return null;
	}

	package void unload_res(GUID id) {
		auto p = id in resources;
		if(p == null) return;
		p.ref_count--;
		if(p.ref_count == 0) {
			p.unload();
			if(p.deleted) resources.remove(id);
		}
	}

	/// Get a resource, if the resource is not loaded, this will load it
	/// All resources are ref counted to know when to unload it, 
	/// so when you are done with a resource, you must free it with resources.free(guid); 
	public auto get(T)(GUID guid) {
		template check(C) {
			enum check = is(C == T);
		}

		static if(Filter!(check, ResourceValueTypes).length == 1) {
			foreach(i; IntegerSeq!(0, ResourceValueTypes.length)) {
				static if(is(ResourceValueTypes[i] == T)) {
					auto r = load_res!(ResourceTypes[i])(guid);
					if(r is null) {
						return default_resources[i];
					}
					return r.get();
				}
			}
		} else {
			static assert(0);
		}
	}

	public void free(GUID guid) {
		unload_res(guid);
	}

	public void refresh() {
		// remove all the resources that no longer exist
		foreach(r;resources) {
			if(!exists(r.fullPath)) {
				if(r.ref_count != 0) r.deleted = true;
				else resources.remove(r.id);
			}
		}

		// add all the new ones
		foreach (DirEntry e; dirEntries(rootFolder, SpanMode.breadth)) {
			checkFile(e);
		}
	}

	package void checkFile(DirEntry e) {
		import std.array;
		import std.conv;

		if(e.isDir) return;
		dstring guidstring = e.name.relativePath(rootFolder).to!dstring;
		auto guid = GUID(guidstring);
		auto fullPath = e.name;
		auto ext = extension(fullPath);

		if(guid in resources) {
			resources[guid].deleted = false;
			return;
		}

		// Loop through all the resource handlers, 
		// check if it has  an extension that matches, 
		// and if so make a Resource entry for it
		foreach(T; ResourceTypes) {
			foreach(res_ext; T.ext) {
				if(res_ext == ext) {
					auto r = new T(); 
					r.id = guid;
					r.guid_string = guidstring;
					r.fullPath = fullPath;
					resources[guid] = r;
					return;
				}
			}
		}
	}

	GUID getGUID(string file) {
		foreach(r;resources) {
			if(file == r.fullPath) {
				return r.id;
			}
		}
		return GUID(null);
	}
}

/// Resource handler
private abstract class Resource {
	GUID     id;
	dstring  guid_string;
	string   fullPath;
	uint     ref_count = 0;
	bool     deleted = false;

	void load();
	void unload();
}


// ------------
// Resource types
// ------------


// Meshes
@ResourceType
private class MeshResource : Resource
{
	enum ext = [".obj", ".b3d"];
	Mesh data;
	override void load() {
		data = alloc.make!Mesh(fullPath);
	}

	override void unload() {
		alloc.dispose(data);
	}

	Mesh get() {
		return data;
	}

	static Mesh getDef() {
		return new Mesh([],[]);
	}
}

// Strings
@ResourceType
private class TextResource : Resource
{
	enum ext = [".txt", ".glsl"];
	dchar[] data;
	override void load() {
		auto f = File(fullPath);
		auto s = cast(size_t)f.size;
		data = alloc.makeArray!dchar(s);
		char[1] c;
		for(int i = 0; i < s; i++) {
			f.rawRead(c);
			data[i] = c[0];
			if(data[i] == '\r') data[i] = ' ';
		}
	}

	override void unload() {
		alloc.dispose(data);
	}

	dstring get() {
		return cast(dstring)data;
	}

	static dstring getDef() {
		return "";
	}
}

// Images 
@ResourceType
private class ImageResource : Resource
{
	enum ext = [".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff"];
	hwTextureRef!(hwTextureType.tex2D) data;
	override void load() {
		Image img = loadImage(fullPath, alloc);
		data = generateTexture(img);
		alloc.dispose(img);
	}

	override void unload() {
		hwDestroy(data);
	}

	hwTextureRef!(hwTextureType.tex2D) get() {
		return data;
	}

	static hwTextureRef!(hwTextureType.tex2D) getDef() {
		import graphics.color;
		Image img = alloc.make!Image(32,32);
		for(int i = 0; i< 32; i++) {
			for(int j = 0; j< 32; j++) {
				img[i,j] = ((i+j)%2 == 0)?RGB(0,0,0):RGB(255, 102, 153);
			}
		}
		hwTextureRef!(hwTextureType.tex2D) t = generateTexture(img);
		alloc.dispose(img);
		return t;
	}
}

// Level 
@ResourceType
private class LevelResource : Resource
{
	// For levels we will just return the 
	enum ext = [".lev"];
	override void load() {
	}

	override void unload() {
	}

	LevelInfo get() {
		return LevelInfo(fullPath);
	}

	static LevelInfo getDef() {
		return LevelInfo();
	}
}

struct LevelInfo{
	string path;
}





enum ResourceType; 

// Used to get all the resource handlers in this module 
private template rec(A ...) {
	import std.traits: hasUDA;

	static if(A.length == 0) alias rec = AliasSeq!();
	else static if(A[0] != "ResourceValueTypes" && __traits(compiles, () {mixin("alias a = " ~ A[0] ~";");})) {
		mixin("alias a = " ~ A[0] ~";");
		static if(hasUDA!(a, ResourceType)) {
			alias rec = AliasSeq!(a, rec!(A[1 .. $]));
		} else alias rec = rec!(A[1 .. $]);
	} else alias rec = rec!(A[1 .. $]);
}

private template resType(T) {
	alias resType = typeof(T.getDef());
}

/// The types of all the resource handlers in this module 
private alias ResourceTypes = rec!(__traits(allMembers, mixin(__MODULE__)));
/// Resource type of the resource handles, so like TextResource's resource type is dstring... 
private alias ResourceValueTypes = staticMap!(resType, ResourceTypes);

