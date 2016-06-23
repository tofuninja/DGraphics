module tofuEngine.components.camera_component;
import tofuEngine;
import math.matrix;
import graphics.camera;
import graphics.gui.propertyPane : NoPropertyPane, PropertyPaneButton;
import math.conversion;
struct SetCameraMsg{} 

CameraComponent currentCam;

// We do not keep track of the active cam during saves so something will
// need to set the camera on the start of the level

mixin registerComponent!CameraComponent;
class CameraComponent : Component {
	bool setOnInit = false;
	float fov    = toRad(45.0f);
	float near   = 0.01f;
	float far    = 400.0f;
	bool ortho   = false;
	private vec3 eye;
	private vec3 lookat;
	private vec3 up;

	override void initCom() {
		change();
		if(setOnInit && !EDITOR_ENGINE) {
			currentCam = this;
		}
	}

	override void destCom() {
		if(currentCam is this) 
			currentCam = null;
	}

	void message(OwnerMoveMsg msg) {
		change();
	}

	void message(EditorChangeMsg msg) {
		change();
	}

	void change() {
		auto mat = owner.getTransform;
		eye = (mat*vec4(0,0,0,1)).xyz;
		lookat = (mat*vec4(0,0,1,1)).xyz;
		up = (mat*vec4(0,1,0,1)).xyz-eye;
	}

	void message(SetCameraMsg msg) {
		currentCam = this;
	}

	Camera getCam() {
		auto c = Camera();
		c.fov = fov;
		if(c.fov <= 0) c.fov = 0.000001f;
		c.near = near;
		c.far = far;
		c.eye = eye;
		c.lookAt = lookat;
		c.up = up;
		c.ortho = ortho;
		return c;
	}

	static if(EDITOR_ENGINE) {
		import core.time:dur;
		private bool selected = false;
		private Timer t;

		void message(EditorSelectMsg msg) {
			selected = msg.selected;
			if(selected) 
				t.setTimer(dur!"seconds"(0), this);
		}

		void message(TimerMsg msg) {
			import graphics.hw;
			auto c = getCam();
			c.aspect = tofu_Graphics.getAspect();
			c.near = 0.3;
			c.far = 5;
			auto mat = c.camMatrix();
			auto inv = mat.inverse();
			vec3 getCorner(vec3 v) { 
				auto p = inv*(v~1);
				return (p/p.w).xyz;
			}
			auto v1 = getCorner(vec3(-1, 1,-1));
			auto v2 = getCorner(vec3( 1, 1,-1));
			auto v3 = getCorner(vec3(-1,-1,-1));
			auto v4 = getCorner(vec3( 1,-1,-1));
			auto v5 = getCorner(vec3(-1, 1, 1));
			auto v6 = getCorner(vec3( 1, 1, 1));
			auto v7 = getCorner(vec3(-1,-1, 1));
			auto v8 = getCorner(vec3( 1,-1, 1));

			tofu_Graphics.drawDebugLine(v1,v2,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v2,v4,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v4,v3,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v3,v1,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v5,v6,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v6,v8,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v8,v7,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v7,v5,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v1,v5,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v2,v6,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v4,v8,vec3(0,0,0));
			tofu_Graphics.drawDebugLine(v3,v7,vec3(0,0,0));

			if(selected)
				t.setTimer(dur!"seconds"(0), this);
		}

		@PropertyPaneButton
		void SetAsCam() {
			currentCam = this;
		}

		@PropertyPaneButton
		void ResetCam() {
			currentCam = null;
		}
	}
}
