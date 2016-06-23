module tofuEngine.components.lighting;

import tofuEngine;
import graphics.render.lightBatch;
import math.matrix;
import graphics.color;
import graphics.gui.propertyPane : ClamepedValue;

mixin registerComponent!PointLight;
class PointLight : Component
{
	private LightInstanceRef instance;
	vec3 location			= vec3(0,0,0);
	float radius			= 1;
	Color color				= RGB(255,255,255);
	ClamepedValue ambiant	= ClamepedValue(0,0,1);
	ClamepedValue intensity	= ClamepedValue(1,0,1);
	bool visable = true;


	override void initCom() {
		auto l = owner.getTransform*(location~1);
		instance = tofu_Graphics.lightBatch.makeInstance(l.xyz, radius, color, ambiant.value, intensity.value, visable);
	}

	override void destCom() {
		instance.remove();
	}

	void message(OwnerMoveMsg msg) {
		change();
	}

	void message(EditorSelectMsg msg) {
		instance.setDebugBox(msg.selected);
	}

	void message(EditorChangeMsg msg) {
		change();
	}

	private void change() {
		auto l = owner.getTransform*(location~1);
		instance.change(l.xyz, radius, color, ambiant.value, intensity.value, visable);
	}
}


mixin registerComponent!GlobalLight;
class GlobalLight : GlobalComponent
{
	Color color = RGB(255,255,255);
	ClamepedValue intensity = ClamepedValue(0,0,1);
	bool enabled = true; 

	override void initCom() {
		change();
	}

	override void destCom() {
		
	}

	void message(EditorChangeMsg msg) {
		change();
	}

	private void change() {
		if(!enabled) {
			tofu_Graphics.lightBatch.globalColor = RGB(255,255,255);
			tofu_Graphics.lightBatch.globalIntensity = 1;
		} else {
			tofu_Graphics.lightBatch.globalColor = color;
			tofu_Graphics.lightBatch.globalIntensity = intensity.value;
		}
	}
}
