module editor.messages;
import editor.io;
import editor.ui;
import tofuEngine;

// Very simple messaging between the engine and the editor, gets compiled out of the non-editor engine

void message(string msg, ARGS...)(ARGS) {
	assert(false);
}

void message(string msg : "starting")() {
	// nothing
}

void message(string msg : "levelSwitch")(Level l) {
	if(editor_props !is null) editor_props.addItem(l);
}

void message(string msg : "addEntity")(Entity e) {
	if(editor_props !is null) editor_props.addItem(e);
}

void message(string msg : "removeEntity")(Entity e) {
	if(editor_props !is null) editor_props.removeItem(e);
}

void message(string msg : "addComponent")(Entity e, Component c) {
	if(editor_props !is null) editor_props.addItem(c);
}

void message(string msg : "removeComponent")(Component c) {
	if(editor_props !is null) editor_props.removeItem(c);
}

void message(string msg : "loadPrefab")(Entity e) {
	//if(editor_props !is null) editor_props.loadPrefab(e);
}

