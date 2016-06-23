module tofuEngine.components.child_entity;
import math.matrix;
import tofuEngine;
import util.serial2;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import graphics.gui.propertyPane : PropertyPaneButton;
import graphics.gui.engineProperties;
alias alloc = Mallocator.instance;

mixin registerComponent!ChildEntity;
class ChildEntity : Component{
	private Entity ent;
	private bool shareT = false;
	override void initCom() {
		makeEntity();
		ent.initEnt();
	}

	override void destCom() {
		if(ent !is null) alloc.dispose(ent);
	}

	void message(DuplicateMsg msg) {
		if(ent !is null) {
			ent = ent.duplicate();
			ent.setParent(owner, shareT);
		}
	}
	
	void message(EditorEntryMsg msg) {
		if(ent !is null) {
			//msg.entry.addChild(new entityEntry(ent));
		}
	}

	void message(OwnerMoveMsg msg) {
		if(ent !is null && shareT) {
			ent.updateTransform();
			ent.broadcast(msg);
		}
	}

	void message(EditorSelectMsg msg) {
		if(ent !is null) ent.broadcast(msg);
	}

	void default_message(TypeInfo id, void* content) {
		if(ent !is null) ent.broadcastDefault(id, content);
	}

	private void makeEntity() {
		if(ent is null) {
			ent = newEntity();
			ent.setParent(owner, shareT);
		}
	}

	
	static if(EDITOR_ENGINE) {
		@PropertyPaneButton 
		void Load_Prefab() {
			import editor.io;
			import util.fileDialogue;
			import std.path;
			import std.range;

			string fileName;
			if(fileLoadDialogue(fileName, ExtensionFilter("Prefab", "*.pfb"))) {
				if(extension(fileName) != ".pfb") {
					writeln("Invalid file extension, must be .pfb");
					return;
				}
				ent.loadPrefab(fileName);
			}
		}
	}

	// Custom serialize 
	void customSerialize(Serializer s) {
		if(ent !is null) s.serialize(ent);
	}

	void customDeserialize(Deserializer d) {
		makeEntity();
		d.deserialize(ent);
	}
}

mixin registerComponent!ChildEntityShareTransform;
class ChildEntityShareTransform : ChildEntity {
	this() {
		shareT = true;
	}
}