module tofuEngine.entity;

import std.file;
import std.stdio;
import std.range;
import std.traits;
import std.meta;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import container.clist;
import container.rstring;
import util.serial2;
import math.matrix;
import tofuEngine.level;
import tofuEngine.engine;
import tofuEngine.component;

private alias alloc = Mallocator.instance;



//	 ______       _   _ _         
//	|  ____|     | | (_) |        
//	| |__   _ __ | |_ _| |_ _   _ 
//	|  __| | '_ \| __| | __| | | |
//	| |____| | | | |_| | |_| |_| |
//	|______|_| |_|\__|_|\__|\__, |
//	                         __/ |
//	                        |___/ 


/**
* Entity container, just a name, an id, and a list of components
* The id is assigned at runtime and can not be changed after the entity is created
* The name can be changed at any time, can be used to search for entities
* 
* Prefabs will be Entities that have not been actualized yet, they will be deserialized, but that is it
* When an actualized entity is created from a prefab, that is when the onLoad is called
* 
* --Entity Lifetime Flags--
* Dynamic: Entities that will be saved into save files 
* Persistent: Entities that will persist between level Switches
* 	They are the only entities that will have onLevelChange called on them
*/ 
final class Entity {
	package CList!(Entity).Node* myNode;
	package CList!(Entity).Node* nameLookUpNode;
	package typeof(Level.octree).ItemRef octreeItem; 
	package Component[] components; // opted for an array because at run time the number of components will always be determined
	package bool dead = true;
	package bool markForDeath = false;


	public rstring name;			// Just another way to search for the entity 
	private vec3 location;			// Location of the entity
	private Quaternion rotation;	// Rotation of the entity
	public bool dynamic = false;	// Determines if the entity will need to be saved during level saving 
	public bool persistent = false;	// stays active between levels
	private Entity parent = null;
	private bool shareTransform = false;
	private mat4 transform; 


	/// Create an empty entity with no components
	private this() {
		transform = modelMatrix(vec3(0,0,0), quatern(0,0,0), vec3(1,1,1));
	}

	@disable this(int i) {}

	void initEnt() {
		enum REGION = LEVEL_SIZE/2;
		updateTransform();
		octreeItem = tofu_Level.octree.insert(this, location/REGION, vec3(0,0,0));
		if(name != "" && name[0] != '_') nameLookUpNode = tofu_Level.nameLookup[name].insert(this);
		else nameLookUpNode = null;
		foreach(com; components) {
			com.m_owner = this;
			com.initCom();
		}
		dead = false;
	}

	void destEnt() {
		foreach(com; components) com.destCom();
		tofu_Level.octree.removeItem(octreeItem);
		if(nameLookUpNode != null) {
			tofu_Level.nameLookup[name].removeNode(nameLookUpNode);
			nameLookUpNode = null;
		}
		dead = true;
	}

	/*
	* Getters and setters
	*/ 

	/// Get the list of components
	final Component[] getComponents() {
		return components;
	}

	/// Move the entity to a new loc/rot
	final void move(vec3 loc, Quaternion rot) {
		if(location == loc && rotation == rot) return; 
		location = loc;
		rotation = rot;
		if(dead) return;

		updateTransform();
		tofu_Level.octree.moveItem(this.octreeItem, loc/(LEVEL_SIZE/2), vec3(0,0,0));

		//MessageContext args;
		//args.engine = engine;
		//args.owner  = this;

		OwnerMoveMsg msg;
		broadcast(msg);
	}

	/// Move the entity ti a new loc
	final void move(vec3 loc) {
		move(loc, this.rotation);
	}

	final void rotate(quatern rot) {
		move(this.location, rot);
	}

	final void moveWorld(vec3 worldLoc) {
		if(parent is null || shareTransform == false) move(worldLoc);
		else {
			{
				import std.stdio;
				writeln(worldLoc);
			}
			auto i = inverse(parent.transform);
			auto p = i*(worldLoc~1);
			move(p.xyz / p.w);
		}
	}

	final void updateTransform() {
		transform = modelMatrix(location, rotation, vec3(1,1,1));
		if(parent !is null && shareTransform) transform = parent.transform*transform;
	}

	final void setName(rstring newName) {
		if(name == newName) return;

		if(!dead) {
			if(nameLookUpNode != null) {
				tofu_Level.nameLookup[name].removeNode(nameLookUpNode);
				nameLookUpNode = null;
			}

			if(name != "" && name[0] != '_') {
				nameLookUpNode = tofu_Level.nameLookup[newName].insert(this);
			}
		}
		name = newName;
	}

	/// Gets the current location of the entity
	final vec3 getLocation() {
		pragma(inline, true);
		return location;
	}

	final vec3 getWorldLocation() {
		pragma(inline, true);
		if(parent is null || shareTransform == false) return location;
		else return (parent.transform*(location ~ 1)).xyz;
	}

	/// Gets the current rotation of the entity
	final quatern getRotation() {
		pragma(inline, true);
		return rotation;
	}

	/// Gets the current name of the entity
	final rstring getName() {
		pragma(inline, true);
		return name;
	}

	void setParent(Entity e, bool shareTrans) {
		shareTransform = shareTrans;
		parent = e;
		updateTransform();
	}

	final Entity getParent() {
		pragma(inline, true);
		return parent;
	}

	final Entity getTransformParent() {
		pragma(inline, true);
		if(shareTransform == false) return null;
		return parent;
	}

	mat4 getTransform() {
		pragma(inline, true);
		return transform;
	}

	/*
	* Serlialization 
	*/

	void customSerialize(Serializer s) {
		//Setup the entity header
		EntityHeader header;
		header.name       = this.name;
		header.dynamic    = this.dynamic;
		header.persistent = this.persistent;
		header.loc        = this.location;
		header.rot        = this.rotation;
		header.comCount   = cast(uint)components.length;

		s.serialize(header);

		//MessageContext args;
		//args.engine = engine;
		//args.owner  = this;

		auto comS = alloc.make!Serializer(false);

		for(int i = 0; i < components.length; i++) {
			auto c = components[i];
			s.serialize(c.entry.hash);
			//args.meObj = c;
			//c.serialize(s, args);
			comS.start();
			c.serialize(comS);
			ubyte[] buf = comS.stop();
			s.serialize(buf);
			alloc.dispose(buf);
		}

		alloc.dispose(comS);
	}

	void customDeserialize(Deserializer d) {
		bool wasDead = dead;
		deconstruct();

		EntityHeader header;
		d.deserialize(header);

		this.name       = header.name;
		this.dynamic    = header.dynamic;
		this.persistent = header.persistent;
		this.location   = header.loc;
		this.rotation   = header.rot;

		//MessageContext args;
		//args.engine = engine;
		//args.owner  = this;

		// get all the componets back out
		if(header.comCount != 0) components = alloc.makeArray!Component(header.comCount);
		else components = null;
		
		// Using an intermidiate serializer simply causes the ubyte count of the com to be serialized as well
		// This is protection, if there is a problem deserializing the component, it wont break the rest of the serialization... 
		auto comD = alloc.make!Deserializer(false);

		for(int i = 0; i < header.comCount; i++) {
			GUID name;
			d.deserialize(name);
			auto entry = tofu_Engine.componentTypes.getComEntry(name);
			
			ubyte[] buf; 
			d.deserialize(buf);
			if(entry is null) components[i] = null;
			else {
				components[i] = entry.makeComponentFunc();
				components[i].m_owner = this;
				//args.meObj = components[i];
				//components[i].deserialize(d, args);
				comD.start(buf);
				try{
					components[i].deserialize(comD);
				} catch(Exception e) {}
				comD.stop();
			}
			alloc.dispose(buf);
		}
		alloc.dispose(comD);

		if(!wasDead) initEnt();
	}

	/**
	* Save the entity out as a prefab
	*/
	void savePrefab(string file_name) {
		auto l = location;
		location = vec3(0,0,0);
		auto s = alloc.make!Serializer();
		scope(exit) alloc.dispose(s);
		s.start();
		s.serialize(this);
		ubyte[] result = s.stop();
		scope(exit) alloc.dispose(result);
		auto f = File(file_name, "w");
		f.rawWrite(result);
		location = l;
	}

	void loadPrefab(string file_name) {
		auto f = File(file_name, "r");
		size_t s = cast(size_t)f.size;
		ubyte[] data = alloc.makeArray!ubyte(s);
		scope(exit) alloc.dispose(data);
		f.rawRead(data);
		auto d = alloc.make!Deserializer();
		scope(exit) alloc.dispose(d);
		d.start(data);
		Entity e = this;
		d.deserialize(e);
		d.stop();
		//if(!dead) message_editor!"loadPrefab"(this);
	}


	/**
	* Used to make a copy of the entity 
	*/
	Entity duplicate() {
		auto e = newEntity();
		e.components = alloc.makeArray!Component(this.components.length);
		for(int i = 0; i < this.components.length; i++) {
			e.components[i] = this.components[i].dup();
			e.components[i].m_owner = e;
			auto msg = DuplicateMsg(this.components[i], this);
			e.broadcastIndex(i, msg);
		}

		e.name			= this.name;
		e.location		= this.location;
		e.rotation		= this.rotation;
		e.dynamic		= this.dynamic;
		e.persistent	= this.persistent;
		return e;
	}


	/*
	* Messaging
	*/
	void broadcast(T)(ref T msg) {
		foreach(c;components) {
			c.broadcast(msg);
		}
	}
	
	// Broadcast the message starting at the top entity
	void broadcastTop(T)(ref T msg) {
		if(parent !is null) parent.broadcastTop(msg);
		else broadcast(msg);
	}

	void broadcastTransformTop(T)(ref T msg) {
		if(parent !is null && shareTransform) parent.broadcastTransformTop(msg);
		else broadcast(msg);
	}

	void broadcastIndex(T)(size_t index, ref T msg) {
		if(index >= components.length) return;
		components[index].broadcast(msg);
	}

	//void broadcastComponentType(ComType, T)(T msg)
	//{
	//    static if(__traits(compiles, function(ComType c, T m) {
	//        c.message(m); // Check that the type can actually recive the message 
	//    })) {
	//        MessageContext args;
	//        args.engine = engine;
	//        args.owner  = this;
	//        foreach(c; components)
	//        {
	//            if(auto com = cast(com_imp!ComType)c)
	//            {
	//                args.meObj = c;
	//                // can bypass the message handeler because we know the type of the component we are sending to
	//                com.com.message(msg, args);
	//            }
	//        }
	//    }
	//}

	//void broadcastComponent(T)(T msg, Component com)
	//{
	//    // Assume that com is a child component of this entity 
	//    com.broadcast(msg);
	//}

	void broadcastDefault(TypeInfo id, void* content) {
		foreach(c; components) {
			c.messageHandeler(id, content);
		}
	}


	/**
	* Make a new instance of a component and add it to the list of components
	* Mostly used by the editor 
	* Will cause a reallocation of the array, thats why it should not actually be used except from the editor
	*/ 
	void addComponent(ComEntry entry) {
		static if(!EDITOR_ENGINE) throw new Exception("Dont use this nigga");
		else {
			auto c = entry.makeComponentFunc();
			c.m_owner = this;
			alloc.expandArray(components, 1); 
			components[$-1] = c;
			auto msg = EditorAddMsg();
			c.broadcast(msg);
			c.initCom();
			//message_editor!"addComponent"(this, c);
			tofu_Editor.addItem(c);
		}
	}

	/**
	* Removes a component and destroys it
	* Mostly used by the editor
	* Will cause a reallocation of the array, thats why it should not actually be used except from the editor
	*/
	void removeComponent(Component com) {
		int index = -1;
		foreach(i, c; components) {
			if(c is com) {
				index = cast(int)i;
				break;
			}
		}

		if(index == -1) throw new Exception("Component not owned by this entity");
		//message_editor!"removeComponent"(com);
		static if(EDITOR_ENGINE) tofu_Editor.removeItem(com);
		com.destCom();
		alloc.dispose(com);
		for(int i = index+1; i < components.length; i++) {
			components[i-1] = components[i];
		}
		components[$-1] = null;
		shrinkArray(alloc, components, 1);
	}

	private void deconstruct() {
		if(!dead) destEnt();
		if(components.length == 0) return;
		foreach(com; components) alloc.dispose(com);
		alloc.dispose(components);
		components = [];
	}

	~this() {
		deconstruct();
	}
}

void kill(Entity e) {
	if(tofu_Level is null) return;
	tofu_Level.removeEntity(e);
}

/// Used to serialize the entity
private struct EntityHeader {
	rstring name;
	bool dynamic;
	bool persistent;
	vec3 loc;
	Quaternion rot;
	uint comCount;
}

Entity newEntity() {
	return alloc.make!Entity();
}

void deleteEntity(Entity e) {
	alloc.dispose(e);
}
