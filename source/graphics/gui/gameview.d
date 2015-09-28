module graphics.gui.gameview;

import graphics.hw.game;
import graphics.gui.siderender;

import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import math.conversion;
import util.event;
import graphics.mesh;
import graphics.camera;


class GameView : SideRender
{
	SceneUniforms uniforms;
	MeshBatch batch;
	Mesh mesh;
	MeshInstance instance;
	Camera cam;
	public this()
	{
		super(500,500);
		mesh = loadMeshAsset("WusonBlitz.b3d")[0];
		batch = MeshBatch(mesh);
		batch.insert(instance);

		instance.transform = modelMatrix(vec3(0,0,0), vec3(0,0,0), vec3(1,1,1));
		instance.visible = true;

		uniforms = new SceneUniforms();
		cam = Camera(toRad(70), 1);
		cam.eye = vec3(0,0,-5);
		uniforms.projection = cam.camMatrix();
		uniforms.update();
	}

	uint time = 0;
	override protected void render(fboRef fbo, iRectangle viewport)
	{
		time ++;
		// Render Logic here
		renderStateInfo state;
		state.fbo = fbo;
		state.viewport = viewport;
		Game.cmd(state);
		
		// Clear side render to a nice beige as the default :)
		clearCommand clear;
		clear.colorClear = Color(255,255,200,255);
		clear.depthClear = 1;
		Game.cmd(clear);
		instance.transform = modelMatrix(vec3(0,0,0), vec3(time*0.05f,time*0.05f,time*0.05f), vec3(1,1,1));
		batch.runBatch(uniforms, viewport, fbo);
	}
}