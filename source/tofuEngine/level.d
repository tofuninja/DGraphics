module tofuEngine.level;

import container.octree;
import container.hashmap;
import container.clist;
import container.rstring;

import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import util.serial2;
import math.matrix;
import tofuEngine.entity;
import tofuEngine.engine;
private alias alloc = Mallocator.instance;

//	 _                    _ 
//	| |                  | |
//	| |     _____   _____| |
//	| |    / _ \ \ / / _ \ |
//	| |___|  __/\ V /  __/ |
//	|______\___| \_/ \___|_|
//


private enum octree_depth = 8; // The depth of the entity octree

/// Keeps track of a set of entities
final class Level {
	package uint currentEntityId = 1;
	package CList!Entity entityList;							// The current alive entities 
	package CList!Entity spawnList;								// The entities waiting to spawn
	package Octree!(Entity, octree_depth) octree;				// Used to do spatial lookup on the entites 
	package Hashmap!(rstring, CList!Entity, 1024) nameLookup;	// Used to to name lookups on the entites 
	package bool haveDead = false;
	rstring name;
	private uint currentEntityCount = 0;

	auto entityRange() {
		return entityList[];
	}

	uint entityCount() {
		return currentEntityCount;
	}

	/// Process new and dead entities 
	package void processSpawns() {
		// Spawn the waiting entities 
		foreach(e; spawnList) {
			e.initEnt();
			//message_editor!"addEntity"(e);
			static if(EDITOR_ENGINE) tofu_Editor.addItem(e);
		}
		transferAllBack(spawnList, entityList);

		// Remove the dead
		if(haveDead) {
			static if(EDITOR_ENGINE) {
				foreach(e; entityList) {
					if(e.markForDeath) //message_editor!"removeEntity"(e);
						tofu_Editor.removeItem(e);
				} 
			}

			entityList.removePred!(removeProc)(this);
			haveDead = false;
		}
	}

	static bool removeProc(Entity e, Level l) {
		if(!e.markForDeath) return false;
		deleteEntity(e);
		return true;
	}

	/// Gets called when the level first starts getting used 
	package void openLevel() {
		foreach(ent; tofu_Engine.componentTypes.registered_components) {
			if(ent.isGlobal()) {
				auto c = ent.global;
				c.initCom(); 
			}
		}
	}

	/// Gets called when the level is closed
	package void closeLevel() {
		foreach(ent; tofu_Engine.componentTypes.registered_components) {
			if(ent.isGlobal()) {
				auto c = ent.global;
				c.destCom(); 
			}
		}
		removeAllEntities();
	}





	/*
	* Entity management
	*/

	/**
	* Creates a blank entity
	* Used primarily by the editor
	*/
	Entity spawn() {
		// Make an entity and put in spawn list, the entity will be inited at the start of the next frame
		auto e = newEntity();
		auto n = spawnList.insertBack(e);
		e.myNode = n;
		currentEntityId++;
		currentEntityCount++;
		return e;
	}

	/**
	* Creates an an entity from a prefab
	* This is how most entities will be made
	*/
	Entity spawn(Entity prefab) {
		// Make an entity and put in spawn list, the entity will be inited at the start of the next frame
		auto e = prefab.duplicate();
		//e.id = currentEntityId;
		auto n = spawnList.insertBack(e);
		e.myNode = n;
		currentEntityId++;
		currentEntityCount++;
		return e;
	}

	/**
	* Creates an an entity from a prefab, directly from a file
	*/
	Entity spawn(string file_name) {
		// Make an entity and put in spawn list, the entity will be inited at the start of the next frame
		auto e = spawn();
		e.loadPrefab(file_name);
		return e;
	}

	/**
	* Removes an entity
	*/
	void removeEntity(Entity e) {
		// Simply mark as dead, will be removed from the list at the start of the next frame
		e.markForDeath = true;
		this.haveDead = true;
		currentEntityCount--;
	}

	package void removeAllEntities() {
		foreach(e; entityList[]) {
			deleteEntity(e);
		}
		entityList.clear();
		currentEntityCount = 0;
	}



	/*
	* Messaging
	*/
	// Messaging is pretty simple, every message is just a single value, the typeid is used to pass it onto the components 

	/// Broadcasts the message to all entites with the name
	void boadcastName(T)(rstring name, ref T msg) {
		auto p = name in nameLookup;
		if(p != null) 
			foreach(e; (p[0])[]) 
				broadcastEntity(e, msg);
	}

	/// Broadcast the message to the specific entity
	void broadcastEntity(T)(Entity e, ref T msg) {
		e.broadcast(msg);
	}

	void broadcastAll(T)(ref T msg) {
		foreach(e; entityList[]) {
			e.broadcast(msg);
		}
	}



	/*
	* Serialization (save/load)
	*/

	// TODO save level 
	// TODO save save 

	/// Saves the entire level out as a .lev, includes the dynamic and static entities, mostly used by the editor
	void saveLevel(string file_name) {
		import std.stdio;
		uint d_count = 0;
		uint s_count = 0;

		foreach(Entity e; entityList[]) {
			if(e.dynamic) d_count ++; 
			else s_count++;
		}

		levelHeader header;
		header.name = name;
		header.d_count = d_count;
		header.s_count = s_count;
		header.g_count = tofu_Engine.componentTypes.globalCount;

		auto s = alloc.make!Serializer();
		scope(exit) alloc.dispose(s);
		s.start();

		s.serialize(header);
		
		// put in the global components
		{
			auto comS = alloc.make!Serializer(false);
			foreach(ent; tofu_Engine.componentTypes.registered_components) {
				if(ent.isGlobal()) {
					auto c = ent.global;
					s.serialize(c.entry.hash);
					comS.start();
					c.serialize(comS);
					ubyte[] buf = comS.stop();
					s.serialize(buf);
					alloc.dispose(buf);
				}
			}
			alloc.dispose(comS);
		}

		// Put the static part in first because during save loading, that is the only part that will need to be read
		foreach(Entity e; entityList[])
			if(!e.dynamic) s.serialize(e);

		foreach(Entity e; entityList[])
			if(e.dynamic) s.serialize(e);

		ubyte[] result = s.stop();
		scope(exit) alloc.dispose(result);
		auto f = File(file_name, "w");
		f.rawWrite(result);

	}

	void loadLevel(string file_name) {
		import std.stdio;
		// Read the contents of the file
		auto f = File(file_name, "r");
		size_t s = cast(size_t)f.size;
		ubyte[] data = alloc.makeArray!ubyte(s);
		scope(exit) alloc.dispose(data);
		f.rawRead(data);
		auto d = alloc.make!Deserializer();
		scope(exit) alloc.dispose(d);
		d.start(data);

		// Grab the header
		levelHeader header;
		d.deserialize(header);
		name = header.name;

		// get out the global components
		{
			auto comD = alloc.make!Deserializer(false);
			for(int i = 0; i < header.g_count; i++) {
				GUID name;
				d.deserialize(name);
				auto entry = tofu_Engine.componentTypes.getComEntry(name);

				ubyte[] buf; 
				d.deserialize(buf);
				if(entry !is null) {
					comD.start(buf);
					try{
						entry.global.deserialize(comD);
					} catch(Exception e) {}
					comD.stop();
				}
				alloc.dispose(buf);
			}
			alloc.dispose(comD);
		}

		for(int i = 0; i < header.s_count; i++) {
			auto e = spawn();
			d.deserialize(e);
		}

		for(int i = 0; i < header.d_count; i++) {
			auto e = spawn();
			d.deserialize(e);
		}

		d.stop();
	}
}

/// Used in level saving and loading 
private struct levelHeader {
	rstring name;
	uint d_count;
	uint s_count;
	uint g_count;
}