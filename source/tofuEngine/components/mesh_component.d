module tofuEngine.components.mesh_component;
import tofuEngine;
import graphics.render.meshBatcher;

import math.matrix;
import graphics.color;

mixin registerComponent!MeshComponent;
class MeshComponent : Component
{
	private MeshInstanceRef instance;

	GUID mesh;
	GUID texture;
	vec3 location;
	Quaternion rotation;
	vec3 scale = vec3(1,1,1);
	Color color = RGB(255,255,255);
	bool visable = true;

	override void initCom() {
		instance = tofu_Graphics.meshBatch.makeInstance();
		change();
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
		auto transform = owner.getTransform*modelMatrix(location, rotation, scale);
		instance.change(mesh, texture, transform, color, visable);
	}
}

