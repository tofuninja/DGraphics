module editor.concmds;
import graphics.gui.console;
import editor.io;
import editor.ui;
import graphics.mesh;
import graphics.gui;
import math.matrix;

import tofuEngine;

@command("Exit the editor")
void exit() {
	import graphics.hw;
	hwState().keyboard[hwKey.ESCAPE] = true;
}

@command("Add a new blank level to the game and switches to it")
void newLevel() {
	editor_engine.switchLevel();
	//editor_props.fullReset();
}

@command("Add a new blank entity to the level")
void newEntity() {
	if(editor_engine.level !is null) {
		editor_engine.level.spawn();
		//editor_props.fullReset();
	} else {
		writeln("Error: No level to add an entity to");
	}
}

@command("List all the resources")
void listResources() {
	foreach(v; editor_engine.resources.resources) {
		writeln(v.guid_string);
	}
}

@command("Update resource list")
void refreshResources() {
	editor_engine.resources.refresh();
}

@command("test command")
void test() {
	msgbox(editor_engine.ui, "This is a test \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\ntest!");
}

@command("Save current level out to a file")
void saveLevel() {
	if(editor_engine.level !is null) {
		import util.fileDialogue;
		import std.path;
		import std.range;

		string fileName;
		if(fileSaveDialogue(fileName, ExtensionFilter("Level", "*.lev"))) {
			if(extension(fileName).empty) {
				fileName ~= ".lev";
			} else if(extension(fileName) != ".lev") {
				writeln("Invalid file extension, use .lev");
				return;
			}

			editor_engine.level.saveLevel(fileName);
		}
	} else {
		writeln("No level to save");
	}
}

@command("Load level")
void loadLevel() {
	import util.fileDialogue;
	import std.path;
	import std.range;

	string fileName;
	if(fileLoadDialogue(fileName, ExtensionFilter("Level", "*.lev"))) {
		if(extension(fileName) != ".lev") {
			writeln("Invalid file extension, must be .lev");
			return;
		}

		editor_engine.switchLevelFile(fileName);
		//editor_props.fullReset();
	}
}

@command("Add a component to the currently selected entity")
void addComponent() {
	Engine eng = editor_engine;
	Entity e;
	if(auto entry = cast(Entity)(editor_props.selectedItem())) {
		e = entry;
	} else {
		writeln("Select the entity you want to add a component to");
		return;
	}
	
	auto p = componentSelectBox();
	if(p != null) e.addComponent(*p);
}


@command("Same as addComponent")
void addCom() {
	addComponent();
}


@command("Removes the currently selected entity or component")
void remove() {
	if(auto e = cast(Entity)editor_props.selectedItem()) {
		if(e.getParent() !is null) 
			writeln("Remove the component that owns the entity, not this");
		else 
			editor_engine.level.removeEntity(e);
	} else if(auto c = cast(Component)editor_props.selectedItem()) {
		c.removeFromOwner();
	} else {
		writeln("Select the entity or component you want to remove");
		return;
	}
}

@command("Duplicates the currently selected entity")
void dup() {
	if(auto e = cast(Entity)editor_props.selectedItem()) {
		editor_engine.level.spawn(e);
	} else {
		writeln("Select the entity you want to duplicate");
	}
}

@command("Save the currently selected entity as a prefab")
void savePrefab() {
	if(editor_props.currentSelect is null) {
		writeln("Select the entity you want to save");
		return;
	}


	if(auto e = cast(Entity)editor_props.selectedItem) {
		import util.fileDialogue;
		import std.path;
		import std.range;

		string fileName;
		if(fileSaveDialogue(fileName, ExtensionFilter("Prefab", "*.pfb"))) {
			if(extension(fileName).empty) {
				fileName ~= ".pfb";
			} else if(extension(fileName) != ".pfb") {
				writeln("Invalid file extension, use .pfb");
				return;
			}
			e.savePrefab(fileName);
		}
	} else {
		writeln("Select the entity you want to save");
	}
}

@command("Load and spawn a prefab from file")
Entity loadPrefab() {
	if(editor_engine.level !is null) {

		import util.fileDialogue;
		import std.path;
		import std.range;

		string fileName;
		if(fileLoadDialogue(fileName, ExtensionFilter("Prefab", "*.pfb"))) {
			if(extension(fileName) != ".pfb") {
				writeln("Invalid file extension, must be .pfb");
				return null;
			}

			return editor_engine.level.spawn(fileName);
		}
	} else {
		writeln("Error: No level to add an entity to");
	}
	return null;
}


@command("Set the grid size of the editor")
void setGridSize(float size) {
	if(editor_view !is null) editor_view.gridSize = size;
}

@command("Set the grid size of the editor")
void setGridHeight(float height) {
	if(editor_view !is null) editor_view.gridHeight = height;
}
