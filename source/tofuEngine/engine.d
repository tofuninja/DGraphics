module tofuEngine.engine;

import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import graphics.color;
import graphics.gui;
import graphics.hw;
import math.matrix;
import tofuEngine.level;
import tofuEngine.timing;
import tofuEngine.render;
import tofuEngine.component;
import tofuEngine.resources;
import tofuEngine.entity;
import tofuEngine.editor;

private alias alloc = Mallocator.instance;


version(tofu_EnableEditor){
	enum EDITOR_ENGINE = true;
} else {
	enum EDITOR_ENGINE = false;
}
enum GC_TRACK = false;
enum LEVEL_SIZE = 2048.0f;
enum LEVEL_ENTRY = "levels\\main.lev";

//void message_editor(string msg, ARGS...)(ARGS args) {
//    pragma(inline, true);
//    static if(EDITOR_ENGINE) {
//        import editor.messages;
//        message!(msg)(args);
//    }
//}

/*

TODO list 

x save entities
x save levels
x save prefabs
x load levels 
x figure out the main camera
x get the entity property box working working 
x get level resources working
x manipulate location, rotation, size of entities in the editor
x add timing information to the engine
x add a engine param to most of the component callbacks, i dont think they will need anything more than a reference to their owner and the engine
x get function buttons on the property box working
x get list selections working on the property box
x move the adding and removing from the entity octree and the name look up table into entity
x if name starts with '_' then dont put it into the name table
x add parent/child entity relation 
x add parent entity to entity
x make ChildEntity component 
x defult message handeler 
x calc transform based on parent
x child entity prefab button
x camera component 
x some concept of main camera
x ortho-cam
x stand alone game(sperate from editor)...
x levels as resorces
x select entity in editor selects components
x maybe move the ui system into the engine
x that ui lang thing was a bad idea
x text highlight

save states 
save saves 
load saves 
persistent entites 
dynamic entites 
prefabs as resorces 
build for both the game and the editor(I hate build systems :<) 
add a button to entity to save prefab 
add a button to level to save level
physics 
better graphics 
editor options
last open level
render game directy to fbo
defered rendering
shadow volumes
fix windowing





UI todo(this stuff honestly can be put off for a while) 
context menus
fonts need some work
use the resource system for fonts
chain fonts together
tree view sucks 
trees over all really suck, and they are only getting used in the tree view, I kinda hate them and want to get rid of them



Just some general ideas

Just rely on the console box to do most editor interactions, wayyyyy simpler
The property pane is also a pretty good idea, a really simple way to auto generate simple utility ui's 

I think the best thing to do is to try and keep the editor and the actual game as similar as possible
also... FUCK SECTORS, they make every thing insanely more complicated, like fuck, that just fucks every thing up

The engine only has 1 active level
Saves and levels are basically the same thing, with only slight differences
A save and a level are both just a list of serialized entities
A level contains the dynamic and non-dynamic(static) entities of the level that are created during level design 
A save just contains the dynamic entities 
So loading a level for the first time will 100% come from the level resource 
Once the level changes and gets saved, the dynamic entities will be saved out to the save
Then when its reloaded, the static part will be loaded from the level resource, but they rest will be loaded from the save

The persistent entities will have there own file separate from the level/save data

To make sure the saves are not huge, we will try to store as much data in the resource files
We will also treat "Levels" as saves managed by the resource system, and they wont ever change

Maybe we can break up a level into the static and the non-static halves 
The static part will always be loaded from the level resource, it will never be saved into a save file because it will never change
The non-static(dynamic) part will be the part that is stored into a save file

*/


//alias GUID = dstring; 
// Having guids as strings was bad, for one strings need to be allocated
// They are still constructed with strings, but they themselves are just 16 byte hashes
// In almost all cases, the 16 bytes will be smaller than the string
// Collisions are almost imposible so over all this seems like a pretty good way to go


/// Resource id, all resources will be referenced by a GUID
struct GUID{
	ubyte[16] hash; // having this public so that the serializer can get to it, otherwise should not be touched

	this(typeof(null)) {
		hash[] = 0;
	}

	this(R)(R guid) {
		import std.array;
		import std.algorithm;
		import std.digest.md;
		import std.range : isInputRange;
		static assert(isInputRange!R);

		hash = md5Of(guid.map!(
			(a) { 
				dchar dc = a;
				ubyte[dchar.sizeof] ub = (cast(ubyte*)(&dc))[0 .. dchar.sizeof];
				return ub;
			}));
	}
}

unittest{ 
	string s = "test";
	dstring ds = "test";
	auto g1 = GUID(s);
	auto g2 = GUID(ds);
	assert(g1.hash == g2.hash);
}

private __gshared Engine gloablEngine;
Engine tofu_Engine() {
	pragma(inline, true);
	return gloablEngine;
}

Renderer tofu_Graphics() {
	pragma(inline, true);
	return gloablEngine.renderer;
}

EngineClock tofu_Clock() {
	pragma(inline, true);
	return gloablEngine.clock;
}

ResourceManager tofu_Resources() {
	pragma(inline, true);
	return gloablEngine.resources;
}

Level tofu_Level() {
	pragma(inline, true);
	return gloablEngine.level;
}

Base tofu_UI() {
	pragma(inline, true);
	return gloablEngine.ui;
}

static if(EDITOR_ENGINE){
	EditorOverlay tofu_Editor(){
		pragma(inline, true);
		return gloablEngine.editor;
	}
}

struct tofu_EngineStartInfo{
	string title;
	uint width = 640;
	uint height = 480;
	bool fullScreen  = false;
	string asset_folder = "./assets";
}

void tofu_StartEngine(tofu_EngineStartInfo info){
	import core.thread : thread_isMainThread;
	assert(thread_isMainThread(), "Must be in main thread to start engine");
	assert(gloablEngine is null, "Only one engine can be running");
	gloablEngine = new Engine(info);
}

void tofu_RunEngineLoop(){
	gloablEngine.engineLoop();
}


/// The engine!
class Engine : hwICallback{
	Renderer renderer;					// Renders the engine
	EngineClock clock; 					// Keeps tracks of time
	ComponentManager componentTypes;	// Keeps track of the component types
	ResourceManager resources;			// Keeps track of all the resources 
	Level level;						// The current level
	Base ui; 							// The ui 
	uint width;
	uint height;
	string title;

	static if(EDITOR_ENGINE){
		package EditorOverlay editor;
	}

	private this(tofu_EngineStartInfo einfo) {
		width = einfo.width;
		height = einfo.height;
		title = einfo.title;

		// Init game window
		{
			import std.conv;
			hwInitInfo info;
			info.fullscreen = einfo.fullScreen;
			info.size = ivec2(width,height);
			info.title = title;
			info.show = false;
			hwInit(info);
			hwCmd(this);
		}

		clock = new EngineClock();
		ui = new Base(this);
		resources = new ResourceManager(einfo.asset_folder);
		componentTypes = comMan;
		renderer = new Renderer();

		static if(EDITOR_ENGINE){
			ui.fillFirst = true;
			editor = new EditorOverlay();
			ui.addDiv(editor);
		}

		{
			import std.experimental.logger;
			import graphics.hw:hwGetVersionString;
			import graphics.image:getImageLoaderVersionString;
			import graphics.font:getFontLoaderVersionString;
			import graphics.mesh:getMeshLoaderVersionString;
			import tofuEngine.components.physics_components:getPhysicsEngineVersionString;
			log(hwGetVersionString());
			log(getImageLoaderVersionString());
			log(getFontLoaderVersionString());
			log(getMeshLoaderVersionString());
			log(getPhysicsEngineVersionString());
			static if(EDITOR_ENGINE){
				log("\nType \"help\" for a list of commands");
				log("Hold right click to rotate camera");
				log("Hold right click and press WASD to move camera");
			}
		}
		
		{
			import tofuEngine.components.physics_components;
			initPhysics();
		}
	}

	/// The main engine loop, returns when the engine closes
	private void engineLoop() {

		// Set a blank level
		//static if(EDITOR_ENGINE)
			switchLevel();
		//else 
		//	switchLevel(GUID(LEVEL_ENTRY));

		hwCmd(hwVisibilityCommand(true));
		//message_editor!"starting"();
		
		import util.memory.gcTracker;
		static if(GC_TRACK) auto track = GCTracker();
		while(!hwState().shouldClose) {
			hwRenderStateInfo state;
			state.fbo = hwState().mainFbo;
			state.viewport = hwState().mainViewport;
			hwCmd(state);
			
			// Clear screen to a nice beige :)
			hwClearCommand clear;
			clear.colorClear = Color(0,0,0,0);
			clear.depthClear = -1;
			hwCmd(clear);

			// Clock update 
			clock.doFrame();
			
			hwPollEvents();

			// Physics think
			{
				import tofuEngine.components.physics_components;
				thinkPhysics();
			}
			
			level.processSpawns();
			clock.runTimers();
			renderer.render(hwState().mainFbo, hwState().mainViewport);
			ui.doFrame();
			hwSwapBuffers();
			if(hwState().keyboard[hwKey.ESCAPE]) break;
		}

		{
			hwCmd(hwVisibilityCommand(false));
		}

		// take down physics
		{
			import tofuEngine.components.physics_components;
			deinitPhysics();
		}
	}




	/// Sets the current level to a blank level
	void switchLevel() {
		switchLevel(alloc.make!Level());
	}

	/// Set the current level to the level stored in the file
	void switchLevelFile(string file) {
		auto l = alloc.make!Level();
		l.loadLevel(file);
		switchLevel(l);
	}

	/**
	*
	* Switches to the specified level
	* Unloads and saves the current level
	*
	*/
	void switchLevel(GUID levelName) {
		string path = resources.get!LevelInfo(levelName).path;
		if(path == "") switchLevel();
		else switchLevelFile(path);
	}

	private void switchLevel(Level lev) {
		// TODO save old level
		if(level !is null) {
			level.closeLevel();
			alloc.dispose(level);
		}
		level = lev;
		level.openLevel();
		//message_editor!"levelSwitch"(level);
		static if(EDITOR_ENGINE) tofu_Editor.addItem(level);
	}






	///// Saves the dynamic portion of the level out to a .sav in the current save slot folder
	//void saveGame()
	//{

	//}






	//void setView(EngineView view)
	//{
	//    assert(renderer is null, "Only one engine view can be set at a time");
	//    renderer = view;
	//}


	// Input callbacks
	void onKey(hwKey k, hwKeyModifier mods, bool down) {
		ui.doKey(k, mods, down);
	}
	void onChar(dchar c) {
		ui.doChar(c);
	}
	void onMouseMove(vec2 loc) {
		ui.doHover(loc);
	}
	void onMouseClick(vec2 loc, hwMouseButton btn, bool down) {
		ui.doClick(loc, btn, down);
	}
	void onWindowResize(vec2) {
		// we need to still update the ui during resize
		ui.invalidate();
		hwRenderStateInfo state;
		state.fbo = hwState().mainFbo;
		state.viewport = hwState().mainViewport;
		hwCmd(state);

		hwClearCommand clear;
		clear.colorClear = Color(0,0,0,0);
		clear.depthClear = -1;
		hwCmd(clear);

		// render
		renderer.render(hwState().mainFbo, hwState().mainViewport);

		// UI think, then blit the UI to the main FBO 
		ui.doFrame();

		// Swap buffers
		hwSwapBuffers();
	}
	void onScroll(vec2 loc, int scroll) {
		ui.doScroll(loc, scroll);
	}
}





// A few basic messages


struct OwnerMoveMsg {} 

struct EditorChangeMsg {}

struct EditorSelectMsg {
	bool selected = false;
}

struct DuplicateMsg{
	Component source;
	Entity sourceOwner;
}

struct EditorAddMsg{}
