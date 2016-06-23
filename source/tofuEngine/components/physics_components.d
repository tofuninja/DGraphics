module tofuEngine.components.physics_components;
import derelict.ode.ode;
import tofuEngine;
import math.matrix;
import util.serial2:SerialSkip;

private dWorldID phy_world;
private dSpaceID phy_space;
private dJointGroupID phy_contactgroup;
private enum GROUND_HEIGHT = 0;
private enum MAX_CONTACTS = 4;


version(Windows) {
	package enum ode_dll	= "ode.dll";
} else version(linux) {
	static assert(false); // TODO Not testsed
	package enum ode_dll	= "ode.so";
} else {
	static assert(false);
}

version(X86_64) {
	package enum lib_folder = "./libs/libs64/";
} else {
	package enum lib_folder = "./libs/";
}

string getPhysicsEngineVersionString() {
	// There does not seem to be a way for me to get the version from ode itself so just print the one I am useing 
	return "Open Dynamics Engine (ODE) Version: 0.13.1";
}

void initPhysics() {
	DerelictODE.load([lib_folder~ode_dll]);
	dInitODE();

	phy_world = dWorldCreate();
	phy_space = dHashSpaceCreate(null);
	dWorldSetGravity(phy_world, 0, -9.81, 0);
	dWorldSetERP(phy_world, 0.2);
	dWorldSetCFM(phy_world, 1e-5);
	dWorldSetContactMaxCorrectingVel(phy_world, 0.9);
	dWorldSetContactSurfaceLayer(phy_world, 0.001);
	dWorldSetAutoDisableFlag(phy_world, 1);
	//{
	//    import math.geo.plane;
	//    auto ground = Plane(vec3(0,GROUND_HEIGHT,0), vec3(0,GROUND_HEIGHT,1), vec3(1,GROUND_HEIGHT,0));
	//    dCreatePlane(phy_space, ground.N.x, ground.N.y, ground.N.z, ground.D);
	//}

	phy_contactgroup = dJointGroupCreate(0);
}

void deinitPhysics() {
	dJointGroupDestroy(phy_contactgroup);
	dSpaceDestroy(phy_space);
	dWorldDestroy(phy_world);
}

void thinkPhysics() {
	dSpaceCollide(phy_space, null, &nearCallback);
	dWorldQuickStep(phy_world, 0.05);
	dJointGroupEmpty(phy_contactgroup);
}

extern(C) private void nearCallback(void *data, dGeomID o1, dGeomID o2) nothrow @nogc {
	// Get the dynamics body for each geom
	dBodyID b1 = dGeomGetBody(o1);
	dBodyID b2 = dGeomGetBody(o2);

	import std.stdio;
	printf("collide");
}




class Collider : Component { 
	protected dGeomID geo;
	vec3 location = vec3(0,0,0);
	quatern rotation;
	bool physicsEnabled = false;
	float mass = 0;
	
	override void initCom() {
		static if(EDITOR_ENGINE) {
			auto phySettings = getGlobalComponent!PhysicsSettings();
			drawColliders = phySettings.OutlineColliders;
			if(drawColliders) 
				t.setTimer(dur!"seconds"(0), this);
		}
	}

	override void destCom() {
		dGeomDestroy(geo);
	}

	void message(OwnerMoveMsg msg) {
		change();
	}

	static if(EDITOR_ENGINE) {
		import core.time:dur;
		private bool selected = false;
		private bool drawColliders = false;
		private Timer t;

		void message(EditorSelectMsg msg) {
			selected = msg.selected;
			if(selected) 
				t.setTimer(dur!"seconds"(0), this);
		}

		void message(DrawCollidersMsg msg) {
			drawColliders = msg.draw;
			if(drawColliders) 
				t.setTimer(dur!"seconds"(0), this);
		}

		void message(TimerMsg msg) {
			float[6] bounds;
			dGeomGetAABB(geo, bounds.ptr); 
			auto min = vec3(bounds[0], bounds[2], bounds[4]);
			auto max = vec3(bounds[1], bounds[3], bounds[5]);
			auto size = max-min;
			auto center = min + size/2;

			if(selected) tofu_Graphics.drawDebugCube(center, size, vec3(1,0,0));

			drawDebugOutline();
			if(selected || drawColliders)
				t.setTimer(dur!"seconds"(0), this);
		}

		void message(EditorChangeMsg msg) {
			change();
		}
	}

	protected void change() {
		auto t = owner.getTransform*modelMatrix(location, rotation, vec3(1,1,1));

		dGeomSetPosition(geo, t[0,3], t[1,3], t[2,3]);
		t = transpose(t);
		dGeomSetRotation(geo, t.data[0..12]);
	} 

	dMass getMass() {
		dMass m;
		dMassSetZero(&m);
		return m;
	}

	dMass getTranslatedMass() {
		auto m = getMass();
		auto t = owner.getTransform*modelMatrix(location, rotation, vec3(1,1,1));
		auto flip = transpose(t);
		dMassRotate(&m, flip.data[0..12]);
		dMassTranslate(&m, t[0,3], t[1,3], t[2,3]);
		return m;
	}

	void drawDebugOutline() {}
}



mixin registerComponent!BoxCollider;
class BoxCollider : Collider { 
	vec3 scale = vec3(1,1,1);
	override void initCom() {
		super.initCom(); 
		this.geo = dCreateBox(phy_space, scale.x, scale.y, scale.z);
		change();
	}

	override protected void change() {
		super.change;
		dGeomBoxSetLengths(geo, scale.x, scale.y, scale.z);
	}

	override dMass getMass() {
		dMass m;
		dMassSetZero(&m);
		dMassSetBoxTotal(&m, mass, scale.x, scale.y, scale.z);
		return m;
	}

	override void drawDebugOutline() {
		auto t = owner.getTransform*modelMatrix(location, rotation, scale/2);
		tofu_Graphics.drawDebugCube(t, vec3(0,1,1));
	}
}

mixin registerComponent!PhysicsBody;
class PhysicsBody : Component
{
	private dBodyID bod;
	float overrideMass = 0; 

	override void initCom() {
		if(owner.getParent is null) {

		}
	}

	override void destCom() {

	}
}


// Global physics settings 
mixin registerComponent!PhysicsSettings;
class PhysicsSettings : GlobalComponent
{
	@SerialSkip 
	bool OutlineColliders = EDITOR_ENGINE;
	
	override void initCom() {
		
	}

	override void destCom() {

	}

	void message(EditorChangeMsg msg) {
		auto nmsg = DrawCollidersMsg(OutlineColliders);
		tofu_Level.broadcastAll(nmsg);
	}

}

struct DrawCollidersMsg{
	bool draw;
}