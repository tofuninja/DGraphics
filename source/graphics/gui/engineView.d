module graphics.gui.engineView;

import graphics.hw;
import graphics.gui.siderender;
import graphics.gui;
import graphics.simplegraphics;
import graphics.color;
import graphics.camera;
import math.geo.rectangle;
import math.matrix;
import math.conversion;
import math.geo.AABox;
import graphics.gui.engineProperties;
import tofuEngine;

class EditorView : div
{
	bool editorMouseCamMove = false;
	vec2 lastMouse;
	ValueSmoother!(3, vec2) m_smooth;
	bool showGrid = true;
	bool lockToGrid = false;
	float gridHeight = 0;
	float gridSize = 1;
	vec3 mouseInWorld;

	Entity currentCopy = null;

	this() {
		canFocus = true;
		canClick = true;
	}

	override protected void initProc() {
		super.initProc();
		m_smooth.init(hwState().mousePos);
	}

	override protected void thinkProc() {
		import editor.ui;
		auto state = hwState();
		auto eng = base.engine;
		auto time = eng.clock.getTimeStamp;
		auto w = state.keyboard[hwKey.W];
		auto a = state.keyboard[hwKey.A];
		auto s = state.keyboard[hwKey.S];
		auto d = state.keyboard[hwKey.D];
		auto ctrl  = state.keyboard[hwKey.LEFT_CONTROL] || state.keyboard[hwKey.RIGHT_CONTROL];
		auto shift = state.keyboard[hwKey.LEFT_SHIFT]   ||   state.keyboard[hwKey.RIGHT_SHIFT];
		auto alt   = state.keyboard[hwKey.LEFT_ALT]     ||     state.keyboard[hwKey.RIGHT_ALT];
		auto left  = state.mouseButtons[hwMouseButton.MOUSE_LEFT]; 
		auto right  = state.mouseButtons[hwMouseButton.MOUSE_RIGHT]; 
		auto windowSize = eng.renderer.getSize();
		auto pos   = m_smooth.smooth(state.mousePos);
		auto c = eng.renderer.cam;
		auto thisCam = true;
		{
			import tofuEngine.components.camera_component;
			if(currentCam !is null) {
				c = currentCam.getCam();
				thisCam = false;
			}
		}
		c.aspect = eng.renderer.getAspect();

		auto mw = mouseToWorld(pos, c, windowSize, gridHeight);
		float editorCamSpeed = 0.008f;
		float editorCamRotateSpeed = 0.0001f;
		float editorEntRotateSpeed = 0.01f;
		mouseInWorld = mw;
		

		// Draw origin
		eng.renderer.drawDebugLine(vec3(0,0.001f,0), vec3(1,0.001f,0), vec3(0.5f,0,0));
		eng.renderer.drawDebugLine(vec3(0,0.001f,0), vec3(0,1.001f,0), vec3(0,0.5f,0));
		eng.renderer.drawDebugLine(vec3(0,0.001f,0), vec3(0,0.001f,1), vec3(0,0,0.5f));

		// Draw indicator around selected entity
		{
			Entity select;
			
			
			if(auto e = cast(Entity)editor_props.selectedItem())
				select = e;
			else if(auto com = cast(Component)editor_props.selectedItem())
				select = com.owner;
			

			while(select !is null) {
				//auto loc = select.getWorldLocation;
				//auto rot = select.getRotation;
				//auto rotate(vec3 v, Quaternion q)
				//{
				//    auto rotmat = rotationMatrix(q);
				//    vec4 v4;
				//    v4.xyz = v;
				//    v4.w   = 1;
				//    return (rotmat*v4).xyz;
				//}
				//drawDebugLine(loc+vec3(0,0.001f,0), loc+rotate(vec3(1,0.001f,0), rot), vec3(1,0,0));
				//drawDebugLine(loc+vec3(0,0.001f,0), loc+rotate(vec3(0,1.001f,0), rot), vec3(0,1,0));
				//drawDebugLine(loc+vec3(0,0.001f,0), loc+rotate(vec3(0,0.001f,1), rot), vec3(0,0,1));
				auto mat = select.getTransform();
				eng.renderer.drawDebugLine((mat*vec4(0,0.001f,0,1)).xyz, (mat*vec4(1,0.001f,0,1)).xyz, vec3(1,0,0));
				eng.renderer.drawDebugLine((mat*vec4(0,0.001f,0,1)).xyz, (mat*vec4(0,1.001f,0,1)).xyz, vec3(0,1,0));
				eng.renderer.drawDebugLine((mat*vec4(0,0.001f,0,1)).xyz, (mat*vec4(0,0.001f,1,1)).xyz, vec3(0,0,1));

				select = select.getParent();
			}
		}
		

		

		if(hasFocus) {
			// Draw mouse world
			if(!editorMouseCamMove) {
				eng.renderer.drawDebugLine(mw-vec3(0.3f,0.001f,0), mw+vec3(0.3f,0.001f,0), vec3(1,0,0));
				eng.renderer.drawDebugLine(mw-vec3(0,0.001f,0.3f), mw+vec3(0,0.001f,0.3f), vec3(0,0,1));
			}

			// Entity Moves
			if(auto e = cast(Entity)editor_props.selectedItem()) {
				if(state.keyboard[hwKey.Y]) { // Y move entity
					auto h = calcNewHeight(pos, c, windowSize, e);
					if(lockToGrid) 
						h = (cast(int)(h/gridSize))*gridSize;
					auto loc = e.getWorldLocation;
					loc.y = h;
					e.moveWorld(loc);
					editor_props.invalidate();
				
				} else if(state.keyboard[hwKey.X]) { // X move entity
					auto loc = mw;
					if(lockToGrid) 
						loc = cast(vec3)(cast(ivec3)(loc/gridSize))*gridSize;
					loc.y = e.getLocation.y;
					loc.z = e.getLocation.z;
					e.moveWorld(loc);
					editor_props.invalidate();
				} else if(state.keyboard[hwKey.Z]) { // Z move entity
					auto loc = mw;
					if(lockToGrid) 
						loc = cast(vec3)(cast(ivec3)(loc/gridSize))*gridSize;
					loc.y = e.getLocation.y;
					loc.x = e.getLocation.x;
					e.moveWorld(loc);
					editor_props.invalidate();
				} else if(shift) { // XZ plane move entity
					auto loc = mw;
					if(lockToGrid) 
						loc = cast(vec3)(cast(ivec3)(loc/gridSize))*gridSize;
					loc.y = e.getLocation.y;
					e.moveWorld(loc);
					editor_props.invalidate();
				} 
			}
			
			if(thisCam) {
				// Move cam with WASD
				vec3 camMove; 
				if(w) camMove.z = editorCamSpeed;
				else if(s) camMove.z = -editorCamSpeed;
				if(d) camMove.x = editorCamSpeed;
				else if(a) camMove.x = -editorCamSpeed;
				camMove = camMove*time.delta_ms;
				eng.renderer.cam.moveRelitive(camMove);
			}
		}

		// rotate with mouse
		if(editorMouseCamMove) {
			if(!right) {
				//hwCmd(hwCursorMode.normal); 
				editorMouseCamMove = false;
			} else if(thisCam) {
				vec2 dif = lastMouse - pos;
				dif = -dif * editorCamRotateSpeed * time.delta_ms;
				eng.renderer.cam.rotateRelitive(cast(vec2)dif);
			}
		}
	
		lastMouse = pos;

		// draw grid
		if(showGrid) renderGrid(eng.renderer, c.eye, gridSize, 50, vec3(1)*0.5f, gridHeight);
	}

	override protected void clickProc(vec2 loc, hwMouseButton button, bool down) {
		auto state = hwState();
		auto ctrl  = state.keyboard[hwKey.LEFT_CONTROL] || state.keyboard[hwKey.RIGHT_CONTROL];
		auto shift = state.keyboard[hwKey.LEFT_SHIFT]   ||   state.keyboard[hwKey.RIGHT_SHIFT];
		auto alt   = state.keyboard[hwKey.LEFT_ALT]     ||     state.keyboard[hwKey.RIGHT_ALT];

		if(down && button == hwMouseButton.MOUSE_RIGHT) {
			editorMouseCamMove = true;
			//hwCmd(hwCursorMode.captured);
		} else if(down && button == hwMouseButton.MOUSE_LEFT) {
			if(base.engine.level !is null && base.engine.level.entityCount != 0) {
				float dist = 10;
				Entity closest = null;
				foreach(e; base.engine.level.entityRange) {
					auto d = length(e.getLocation - mouseInWorld);
					if(d < dist) {
						closest = e;
						dist = d;
					}
				}
				if(closest !is null) {
					import editor.ui;
					editor_props.selectItem(closest);
				}
			}
		}
	}

	override protected void keyProc(hwKey k, hwKeyModifier mods, bool down) {
		auto eng = base.engine;
		import editor.ui;
		import editor.io;

		if(!down) return;

		switch(k) {
			case hwKey.L:
				lockToGrid = !lockToGrid;
				writeln("Grid lock ", lockToGrid?"enabled":"disabled");
				break;
			case hwKey.LEFT_BRACKET:
				gridSize /= 2.0f;
				writeln("Grid Size = ", gridSize);
				gridHeight = cast(int)(gridHeight/gridSize)*gridSize;
				break;
			case hwKey.RIGHT_BRACKET:
				gridSize *= 2.0f;
				writeln("Grid Size = ", gridSize);
				gridHeight = cast(int)(gridHeight/gridSize)*gridSize;
				break;
			case hwKey.DELETE:
				{
					import editor.concmds;
					remove();
				}
				break;
			case hwKey.F1:
				if(base.engine.level !is null) {
					Entity e = base.engine.level.spawn();
					auto loc = mouseInWorld;
					if(lockToGrid) 
						loc = cast(vec3)(cast(ivec3)(loc/gridSize))*gridSize;
					e.move(loc);
				}
				break;
			case hwKey.F2:
				{
					import editor.concmds;
					addCom();
				}
				break;
			case hwKey.F3:
				{
					import editor.concmds;
					Entity e = loadPrefab();
					if(e !is null) {
						auto loc = mouseInWorld;
						if(lockToGrid) 
							loc = cast(vec3)(cast(ivec3)(loc/gridSize))*gridSize;
						e.move(loc);
					}
				}
				break;
			case hwKey.F5:
				{
					import editor.concmds;
					saveLevel();
				}
				break;
			case hwKey.F9:
				{
					import editor.concmds;
					loadLevel();
				}
				break;
			case hwKey.NUM_0:
				gridHeight = 0;
				writeln("Grid Height = ", gridHeight);
				break;
			case hwKey.G: 
				showGrid = !showGrid;
				break;
			case hwKey.EQUAL: 
				gridHeight += gridSize;
				writeln("Grid Height = ", gridHeight);
				break;
			case hwKey.MINUS: 
				gridHeight -= gridSize;
				writeln("Grid Height = ", gridHeight);
				break;
			case hwKey.C:{
				if(!mods.ctrl) break;
				if(auto e = cast(Entity)editor_props.selectedItem()) {
					if(currentCopy !is null) deleteEntity(currentCopy);
					currentCopy = e.duplicate();
				}

				break;
			} 
			case hwKey.V:{
				if(!mods.ctrl) break;
				if(currentCopy !is null && base.engine.level !is null) {
					currentCopy.move(mouseInWorld);
					auto e = base.engine.level.spawn(currentCopy);
				}
				
				break;
			} 
			case hwKey.O:
				{
					import tofuEngine.components.camera_component;
					if(currentCam is null) {
						if(auto e = cast(Entity)editor_props.selectedItem()) {
							eng.renderer.cam.lookAt = e.getLocation;
							eng.renderer.cam.eye    = e.getLocation + vec3(2,2,-5);
						} else {
							eng.renderer.cam.lookAt = vec3(0,0,0);
							eng.renderer.cam.eye    = vec3(2,2,-5);
						}
					}
				}
				break;
			default:
		}
	}
}

vec3 mouseToWorld(vec2 mouse, Camera cam, vec2 wh, float planeHeight) {
	import math.geo.plane;
	mouse = 2*(mouse/wh) - vec2(1,1);
	mouse.y = -mouse.y;
	auto inv = inverse(cam.camMatrix());
	auto s = (inv*(mouse~vec2(-1,1)));
	auto e = (inv*(mouse~vec2(1,1)));
	auto start = (s/s.w).xyz;
	auto end = (e/e.w).xyz;
	auto dir = normalize(end-start);

	Plane p = Plane(vec3(0, planeHeight, 0), vec3(0, planeHeight, 1), vec3(1, planeHeight, 0));
	float dist;
	if(ray_plane_intersect(p, start, dir, dist)) {
		if(dist > 0) {
			auto r = start + dist*dir;
			r.y = planeHeight; // just to make sure it comes out right
			return r;
		}
	}
	return vec3(0,0,0);
}

float calcNewHeight(vec2 mouse, Camera cam, vec2 wh, Entity ent) {
	import math.geo.plane;
	auto loc = ent.getWorldLocation;
	auto camLoc = cam.eye;
	camLoc.y = loc.y;
	auto B = normalize(cross(vec3(0,1,0), camLoc-loc));
	
	mouse = 2*(mouse/wh) - vec2(1,1);
	mouse.y = -mouse.y;
	auto inv = inverse(cam.camMatrix());
	auto s = (inv*(mouse~vec2(-1,1)));
	auto e = (inv*(mouse~vec2(1,1)));
	auto start = (s/s.w).xyz;
	auto end = (e/e.w).xyz;
	auto dir = normalize(end-start);

	Plane p = Plane(loc, loc + B, loc + vec3(0,1,0));
	float dist;
	if(ray_plane_intersect(p, start, dir, dist)) {
		if(dist > 0) {
			auto r = start + dist*dir;
			return r.y;
		}
	}
	return 0;
}




/// Smooths a value over time
struct ValueSmoother(int i, V) {
	uint loc = 0;
	V[i] pos;

	this(V p) {
		init(p);
	}

	void init(V p) {
		pos[] = p;
	}

	V smooth(V p) {
		pos[loc] = p;
		loc = (loc+1)%i;

		V average;
		foreach(v; pos) {
			average = average+v;
		}
		average = average/i;
		return average;
	}
}

private void renderGrid(Renderer view, vec3 camLoc, float dist, float size, vec3 color, float height) {
	import std.math;
	auto off = round(size/dist)*dist/2.0f;
	camLoc.x = round(camLoc.x/dist)*dist - off;
	camLoc.y = height;
	camLoc.z = round(camLoc.z/dist)*dist - off;
	uint count = cast(uint)(abs(round(size/dist)));
	for(uint i = 0; i <= count; i++)
		view.drawDebugLine(camLoc + vec3(i*dist,0,0), camLoc + vec3(i*dist,0,size), color);

	for(uint i = 0; i <= count; i++)
		view.drawDebugLine(camLoc + vec3(0,0,i*dist), camLoc + vec3(size,0,i*dist), color);
}

