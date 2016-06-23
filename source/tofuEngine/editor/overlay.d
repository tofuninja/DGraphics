module tofuEngine.editor.overlay;

import tofuEngine;
import graphics.hw;
import graphics.gui;
import container.rstring;
import container.clist;
import math.matrix;
import std.experimental.logger;


enum editorCamSpeed = 0.008f;
enum editorCamRotateSpeed = 0.0001f;
enum editorEntRotateSpeed = 0.01f;



class EditorOverlay : div {
	Console ed_console;
	EditorMainArea ed_main_area;
	EditorProperties ed_properties;

	this(){
		auto vs = new VerticalSplit();
		vs.flipSplit = true;
		vs.split = 80f;
		vs.border = false;
		vs.back = false;
		addDiv(vs);

		auto hs = new HorizontalSplit();
		hs.flipSplit = true;
		hs.split = 200;
		hs.back = false;
		hs.border = false;
		vs.addDiv(hs);

		ed_console = new Console();
		//consoleCommandGenerator!(editor.concmds)(ed_console);
		ed_console.border = false;
		vs.addDiv(ed_console);

		ed_main_area = new EditorMainArea(this);
		hs.addDiv(ed_main_area);

		ed_properties = new EditorProperties(this);
		hs.addDiv(ed_properties);

		sharedLog = new ConsoleLogger(LogLevel.all, ed_console);
	}

	override protected void stylizeProc() {
		if(children.length > 0){
			auto d = children.peekBack();
			d.bounds.loc = vec2(0,0);
			d.bounds.size = this.bounds.size;
		}
	}

	void addItem(Object o){
		ed_properties.addItem(o);
	}

	void removeItem(Object o){
		ed_properties.removeItem(o);
	}
}

class ConsoleLogger : Logger {
	Console con;
    this(LogLevel lv, Console c) @safe {
        super(lv);
		con = c;
    }
    override void writeLogMsg(ref LogEntry payload) @trusted {
		alias errwriteln = (args){ 
			import std.stdio;
			stderr.writeln(args);
		};
        con.writeln(payload.msg);
		errwriteln(payload.msg);
    }
}
                                                            
private class EditorMainArea : div {
	EditorOverlay over;
	bool editorMouseCamMove = false;
	bool camDidMove = false;
	vec2 lastMouse;
	CList!(debugGrid*) grids;
	debugGrid camGrid;
	vec2 rightClickLoc;

	float defaultGridGap = 1f;
	bool lockGrid = true;
	float mainGridHeight = 0f;

	this(EditorOverlay o){
		canClick = true;
		canFocus = true;
		over = o;
		camGrid.enable(true, this);
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		switch(k){
			case hwKey.EQUAL: {
				if(!down) return;
				defaultGridGap *= 2;
				log("Grid Size is ", defaultGridGap);
				return;
			} case hwKey.MINUS: {
				if(!down) return;
				defaultGridGap /= 2;
				log("Grid Size is ", defaultGridGap);
				return;
			} case hwKey.L: {
				if(!down) return;
				lockGrid =! lockGrid;
				if(lockGrid) log("Grid Locking Enabled");
				else log("Grid Locking Disabled");
				return;
			} case hwKey.LEFT_BRACKET: {
				if(!down) return;
				mainGridHeight--;
				log("Grid Height is ", mainGridHeight);
				return;
			} case hwKey.RIGHT_BRACKET: {
				if(!down) return;
				mainGridHeight++;
				log("Grid Height is ", mainGridHeight);
				return;
			} 
			default:
		}
		over.ed_properties.doKey(k, mods, down);
	}

	override protected void thinkProc() {
		auto time = tofu_Clock.getTimeStamp;
		auto cam = &(tofu_Graphics.getCurrentCamera());

		// set cam grid settings
		float rount_to(float x) { import std.math : round; return round(x/defaultGridGap)*defaultGridGap; }
		camGrid.transform = translationMatrix(rount_to(cam.eye.x), mainGridHeight, rount_to(cam.eye.z));
		camGrid.size = 32;
		camGrid.color = vec3(1,1,1);
		camGrid.capturePastEdge = true;

		if(editorMouseCamMove) {
			if(!hwState.mouseButtons[hwMouseButton.MOUSE_RIGHT]) editorMouseCamMove = false;
			else {
				vec2 dif = lastMouse - hwState.mousePos;
				dif = -dif * editorCamRotateSpeed * time.delta_ms;
				cam.rotateRelitive(dif);

				// Move cam with WASD
				vec3 camMove = vec3(0,0,0); 
				if(hwState.keyboard[hwKey.W])		camMove.z = editorCamSpeed;
				else if(hwState.keyboard[hwKey.S])	camMove.z = -editorCamSpeed;
				if(hwState.keyboard[hwKey.D])		camMove.x = editorCamSpeed;
				else if(hwState.keyboard[hwKey.A])	camMove.x = -editorCamSpeed;
				camMove = camMove*time.delta_ms;
				cam.moveRelitive(camMove);

				if(dif != vec2(0,0) || camMove != vec3(0,0,0)) camDidMove = true;
			}
		} else {
			debugGrid* intersect;
			auto p = getCursorOnGrid(hwState.mousePos, intersect);
			if(intersect != null){
				auto world = translationMatrix(normalize(cam.lookAt-cam.eye)*(-0.005f))*intersect.transform*translationMatrix(p.x,0,p.y);
				import std.math:PI,sin,cos;

				enum LINE_COUNT = 4;
				enum PI_ADV = PI/LINE_COUNT;
				enum LINE_RADIUS = 0.3f;
				for(int i = 0; i < LINE_COUNT; i++){
					auto color = (i%2 == 0) ? vec3(1,0,0) : vec3(0,0,1);
					auto s = sin(PI_ADV*i)*LINE_RADIUS;
					auto c = cos(PI_ADV*i)*LINE_RADIUS;
					tofu_Graphics.drawDebugLine((world*vec4( s, 0, c, 1)).xyz, (world*vec4(-s, 0, -c, 1)).xyz, color);
				}
			}
		}
		
		// Render grids
		{
			foreach(grid; grids[]){
				import std.math : abs, ceil;
				auto gap = (grid.gap>0)? grid.gap : defaultGridGap;
				int size = cast(int)ceil(abs(grid.size/gap));
				tofu_Graphics.drawDebugGrid(grid.transform, size, gap, grid.color);
			}
		}

		tofu_Graphics.drawDebugIndicator(modelMatrix(vec3(0,0.0001f,0), quatern(), vec3(1,1,1)), 1);
		lastMouse = hwState.mousePos;
	}

	override protected void clickProc(vec2 loc,hwMouseButton button,bool down) {
		if(button == hwMouseButton.MOUSE_RIGHT) {
			if(down) {
				camDidMove = false;
				editorMouseCamMove = true;
			} else if(!camDidMove) {
				rightClickLoc = loc;
				debugGrid* intersect;
				auto p = getCursorOnGrid(loc, intersect);
				if(intersect != null){
					openContextMenu([
						"Add Entity Here"
					]);
				}

				
			} else camDidMove = false;
		} else if(button == hwMouseButton.MOUSE_LEFT && down){
			debugGrid* intersect;
			auto p = getCursorOnGrid(loc, intersect);
			if(intersect != null){
				auto world = intersect.localToWorld(p);
				auto e = getClosestEntity(1, world);
				if(e !is null){
					tofu_Editor.ed_properties.top.selectItem(e);
				}
			}
		}
	}

	override protected void menuProc(int index,dstring text) {
		switch(index){
			case 0 : { // Add Entity Here
				debugGrid* intersect;
				auto p = getCursorOnGrid(rightClickLoc, intersect);
				if(intersect != null){
					auto world = intersect.localToWorld(p);
					Entity e = tofu_Level.spawn();
					e.move(world);
				}
				return;
			}
			default:
		}
	}
	
	vec2 getCursorOnGrid(vec2 mouse, out debugGrid* grid_intersect){
		auto windowSize = tofu_Graphics.getSize();
		auto inv = inverse(tofu_Graphics.getCurrentCamera().camMatrix());
		mouse = 2*(mouse/windowSize) - vec2(1,1);
		mouse.y = -mouse.y;
		auto s = (inv*(mouse~vec2(-1, 1)));
		auto e = (inv*(mouse~vec2( 1, 1)));
		auto start = (s/s.w).xyz;
		auto end   = (e/e.w).xyz;
		auto dir = normalize(end-start);

		float cur_dist = float.infinity;
		vec2 cur_return = vec2(0,0);
		grid_intersect = null;

		foreach(grid; grids[]){
			import math.geo.plane;
			if(grid.captureMouse == false) continue;

			Plane p = Plane(grid.transform);
			float dist;
			if(ray_plane_intersect(p, start, dir, dist)) {
				if(dist < cur_dist && dist >= 0) {
					import std.math : abs;
					auto local = (inverse(grid.transform)*((start + dist*dir)~1)).xz;
					auto size = grid.size;
					if(grid.capturePastEdge || (local.x.abs <= size && local.y.abs <= size)){
						cur_return = local;
						if(lockGrid){
							auto gap = (grid.gap>0)? grid.gap : defaultGridGap;
							alias rount_to = (ref x, y) { import std.math : round; x = round(x/y)*y; };
							rount_to(cur_return.x, gap);
							rount_to(cur_return.y, gap);
						}
						cur_dist = dist;
						grid_intersect = grid;
					}
				}
			}
		}

		return cur_return;
	}

	Entity getClosestEntity(float maxDist, vec3 center){
		octMapArgs a;
		a.r = maxDist/(LEVEL_SIZE/2);
		a.c = center/(LEVEL_SIZE/2);
		a.center = center;
		a.curDist = maxDist;
		a.cur = null;
		import container.octree : OctreeMap;
		OctreeMap!(check, find)(tofu_Level.octree, a);
		return a.cur;
	}
}

bool check(vec3 center, vec3 size, ref octMapArgs arg){
	import math.geo.box_sphere_intersect;
	auto sd2 = size/2;
	return Box_Sphere_Intersect(center-sd2, center+sd2, arg.c, arg.r);
}

void find(Entity e, ref octMapArgs arg){
	auto d = length(e.getLocation-arg.center);
	if(d < arg.curDist){
		arg.curDist = d;
		arg.cur = e;
	}
}

private struct octMapArgs{
	float r;
	vec3 c;
	vec3 center;
	float curDist;
	Entity cur;
}

struct debugGrid {
	mat4 transform;
	float size;
	float gap = 0;
	vec3 color;
	bool capturePastEdge = false;
	bool captureMouse = true;

	private CList!(debugGrid*).Node* node = null;

	void enable(bool b){
		enable(b, tofu_Editor.ed_main_area);
	}

	private void enable(bool b, EditorMainArea m){
		static if(EDITOR_ENGINE){
			if(b && node == null){
				node = m.grids.insert(&this);
			} else if(!b && node != null){
				m.grids.removeNode(node);
				node = null;
			}
		}
	}

	bool isEnabled(){
		return (node != null);
	}

	vec3 localToWorld(vec2 loc){
		return (transform*vec4(loc.x, 0, loc.y, 1)).xyz;
	}
}

class EditorProperties : VerticalSplit { 
	Scrollbox scroll;
	EditorRootTree top;
	PropertyPane bot;
	EngineTree currentSelect;
	EditorOverlay over;

	this(EditorOverlay o) {
		over = o;
		scroll = new Scrollbox();
		scroll.fillFirst = true;
		top = new EditorRootTree();
		bot = new PropertyPane();
		bot.eventHandeler = &handeler;
		scroll.addDiv(top);
		addDiv(scroll);
		addDiv(bot);
		percentageSplit = true;
		split = 0.5f;
	}

	private void handeler(EventArgs e) {
		if(e.type == EventType.ValueChange && e.origin is bot) {
			if(currentSelect !is null) currentSelect.change();
		}
	}

	Object selectedItem() {
		if(currentSelect !is null) return currentSelect.item;
		return null;
	}

	void addItem(Object i) {
		top.addItem(i);
		top.selectItem(i);
	}

	void removeItem(Object i) {
		top.removeItem(i);
	}

	void selectItem(Object i) {
		top.selectItem(i);
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		top.doKey(k, mods, down);
	}
	
}

class EngineTree : TreeView {
	Object item; 
	this() {
		expanded = true;
	}
	override void selectProc(bool select) {
		auto o = tofu_Editor.ed_properties;
		o.currentSelect = null;
		o.bot.clearData();
		if(select) {
			o.currentSelect = this;
		}
	}

	void change() {}
	void addItem(Object i) {}
	void setData(T)(ref T t) {
		tofu_Editor.ed_properties.bot.setData(t);
	}

	void clearData() {
		tofu_Editor.ed_properties.bot.clearData();
	}

	bool selectItem(Object i) {
		if(i is item) {
			setSelect(true);
			//base.makeFocus(this);
			return true;
		}
		foreach(d; children[]) if(auto et = cast(EngineTree)d) if(et.selectItem(i)) return true;
		return false;
	}

	bool removeItem(Object i) {
		EngineTree found;
		foreach(d; children[]) if(auto et = cast(EngineTree)d) {
			if(et.item is i) {
				found = et;
				break;
			} else {
				if(et.removeItem(i)) return true;
			}
		}
		if(found !is null) {
			found.setSelect(false);
			found.removeItemProc();
			this.removeDiv(found);
			return true;
		}
		return false;
	}

	void removeItemProc(){}
}

class EditorRootTree : EngineTree { 
	LevelTree lev; 
	this(){
		lev = new LevelTree();
		this.addDiv(lev);
	}

	override protected void stylizeProc() {
		text = "~~ Tofu Engine ~~";
		//icon = '\uF11B';
	}

	override void addItem(Object i) {
		lev.addItem(i);
	}

	override void selectProc(bool select) {
		super.selectProc(select);

		//if(select && item !is null) {
		//    auto l = cast(Level)item;
		//    setData(l);
		//}
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		if(down){
			switch(k){
				case hwKey.F1:{

					return;
				}
				default:
			}
		}
		auto cs = tofu_Editor.ed_properties.currentSelect;
		if(cs !is this && cs !is null) cs.div.doKey(k,mods,down);
	}
}

class LevelTree : EngineTree { 
	EntityListTree entList;
	GlobalComponentListTree gcomsList;

	override protected void stylizeProc() {
		if(auto l = cast(Level)item) {
			if(l.name == "") text = "Level: no-name";
			else if(l.name != text) text = "Level: " ~ l.name.to!dstring;
			icon = '\uF0E8';
		} else {
			text = "No Level";
			icon = '\uF05E';
		}
	}

	override void addItem(Object i) {
		if(auto l = cast(Level)i) {
			expanded = true;
			clearData();
			clearSelect();
			children.clear();
			item = l;
			gcomsList = new GlobalComponentListTree();
			addDiv(gcomsList);
			entList = new EntityListTree();
			addDiv(entList);
		} else if(entList) entList.addItem(i);
	}

	override void selectProc(bool select) {
		super.selectProc(select);
		if(select && item !is null) {
			auto l = cast(Level)item;
			setData(l);
		}
	}
}

class GlobalComponentListTree : EngineTree {
	override protected void initProc() {
		super.initProc;
		foreach(ent; tofu_Engine.componentTypes.registered_components) {
			if(ent.isGlobal()) {
				auto c = ent.global;
				EditorGetEntryMsg msg;
				c.broadcast(msg);
				if(msg.entry !is null)
					addDiv(msg.entry);
				else
					addDiv(new GlobalComTree(c));
			}
		}
	}
	
	override protected void stylizeProc() {
		text = "Global Components";
		icon = '\uF0AC';
	}
}

class GlobalComTree : ComTree {
	this(GlobalComponent c){ super(c); }
	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		EngineTree.keyProc(k,mods,down);
	}
	override protected void menuProc(int index,dstring text) {
		EngineTree.menuProc(index,text);
	}
	override protected void clickProc(vec2 loc,hwMouseButton button,bool down) {
		EngineTree.clickProc(loc,button,down);
	}
}

class EntityListTree : EngineTree {
	private int currentC = -1;
	override protected void initProc() {
		super.initProc;
		auto l = tofu_Level;
		foreach(e; l.entityRange) {
			addEnt(e);
		}
	}

	override protected void stylizeProc() {
		import std.conv : to;
		auto l = tofu_Level;
		int c = l.entityCount();
		if(c != currentC) text = "Entities(" ~ c.to!dstring ~ ")";
		currentC = c;
		icon = '\uF1B3';
	}

	override void addItem(Object i) {
		if(auto e = cast(Entity)i) {
			addEnt(e);
		} else if(auto com = cast(Component)i) {
			foreach(c; children[]) {
				auto et = cast(EntityTree)c;
				if(et.item is com.owner()) {
					et.addItem(i);
					return;
				}
			}
		}
	}

	void addEnt(Entity e) {
		addDiv(new EntityTree(e));
	}

	override protected void clickProc(vec2 loc,hwMouseButton button,bool down) {
		super.clickProc(loc,button,down);
		if(down && button == hwMouseButton.MOUSE_RIGHT){
			openContextMenu(["Add Entity"]);
		}
	}

	override protected void menuProc(int index,dstring text) {
		if(index == 0){
			tofu_Level.spawn();
		}
	}
	
	
}

class EntityTree : EngineTree {
	private entityProperties currentEnt;
	this(Entity e) { item = e; }

	override protected void initProc() {
		super.initProc;
		foreach(c; (cast(Entity)item).getComponents()) {
			addCom(c);
		}
	}

	override void addItem(Object i) {
		if(auto c = cast(Component)i) addCom(c);
	}

	void addCom(Component c) {
		EditorGetEntryMsg msg;
		c.broadcast(msg);
		if(msg.entry !is null)
			addDiv(msg.entry);
		else
			addDiv(new ComTree(c));
	}

	override protected void stylizeProc() {
		auto e = cast(Entity)item;
		if(e.name == "") text = "no-name";
		else if(e.name != text) text = e.name.to!dstring;
		icon = '\uF1B2';
	}

	override void selectProc(bool select) {
		super.selectProc(select);
		auto e = cast(Entity)item;
		if(select) {
			currentEnt = entityProperties(e);
			setData(currentEnt);
		}
		auto msg = EditorSelectMsg(select);
		e.broadcast(msg);
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		if(down && k == hwKey.DELETE) {
			if(auto ent = cast(Entity)item) {
				ent.kill();
			}
		}
	}

	override protected void thinkProc() {
		super.thinkProc;
		if(auto e = cast(Entity)item){
			float s = selected? 0.6f:0.2f;
			float i = selected? 1.0f:0.5f;
			tofu_Graphics.drawDebugIndicator(e.getTransform()*scalingMatrix(s,s,s),i);
		}
	}
	
	override protected void clickProc(vec2 loc,hwMouseButton button,bool down) {
		super.clickProc(loc,button,down);
		if(down && button == hwMouseButton.MOUSE_RIGHT){
			openContextMenu(["Add Component", "Delete Entity"]);
		}
	}

	override protected void menuProc(int index,dstring text) {
		auto e = cast(Entity)item;
		if(index == 0){
			auto p = componentSelectBox();
			if(p != null) e.addComponent(*p);
		} else if(index == 1){
			e.kill();
		}
	}
}

class ComTree : EngineTree { 
	this(Component c) { item = c; }
	override protected void initProc() {
		super.initProc;
		auto msg = EditorEntryMsg(this);
		(cast(Component)item).broadcast(msg);
	}

	override void change() {
		auto com = cast(Component)item;
		EditorChangeMsg msg;
		com.broadcast(msg);
	}

	override protected void stylizeProc() {
		auto com = cast(Component)item;
		text = com.entry.name;
		icon = '\uF12E';
	}

	override void selectProc(bool select) {
		super.selectProc(select);
		auto com = cast(Component)item;
		if(select) com.editProperties(tofu_Editor.ed_properties.bot);
		auto msg = EditorSelectMsg(select);
		com.broadcast(msg);
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		if(down && k == hwKey.DELETE) {
			if(auto com = cast(Component)item) {
				com.removeFromOwner();
			}
		} 
	}

	override protected void clickProc(vec2 loc,hwMouseButton button,bool down) {
		super.clickProc(loc,button,down);
		if(down && button == hwMouseButton.MOUSE_RIGHT){
			openContextMenu(["Delete Component"]);
		}
	}

	override protected void menuProc(int index,dstring text) {
		if(index == 0){
			if(auto com = cast(Component)item) {
				com.removeFromOwner();
			}
		} 
	}
}

//private entityProperties currentEnt;
private struct entityProperties {
	@NoPropertyPane
		private Entity me;

	rstring name;
	vec3 location;
	Quaternion rotation;
	bool dynamic;
	bool persistent;

	this(Entity me) {
		this.me = me;
		onStylize();
	}

	void onStylize() {
		if(me is null) return;
		name = me.getName;
		location = me.getLocation;
		rotation = me.getRotation;
		dynamic = me.dynamic;
		persistent = me.persistent;
	}

	void onChange() {
		if(me is null) return;
		me.move(location, rotation);
		me.setName(name);

		me.dynamic = dynamic;
		me.persistent = persistent;
	}
}

struct EditorEntryMsg{
	EngineTree entry;
}

struct EditorGetEntryMsg{
	EngineTree entry = null;
}