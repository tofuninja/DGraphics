module graphics.camera;
import math.matrix;
import graphics.GraphicsState;
import graphics.Image;
import graphics.mesh;

public struct camera
{
	public mat4 projMatrix;
	public mat4 viewMatrix;
	public float fov;
	public float aspect;
	public float zoom;
	public float near;
	public float far;
	public vec3 eye;
	public vec3 rot;

	public this(float fov, float aspect, float near = -1, float far = -100)
	{
		this.fov = fov;
		this.aspect = aspect;
		zoom = 1;
		this.near = near;
		this.far = far;
		eye = vec3(0,0,0);
		rot = vec3(0,0,0);
	}
}

void invalidate(ref camera c)
{
	auto rotMat = rotationMatrix(c.rot);
	c.projMatrix = projectionMatrix(c.fov/c.zoom, c.aspect, c.near, c.far);
	c.viewMatrix = viewMatrix(c.eye, c.eye + (rotMat*vec4(0,0,-1,1)).xyz, (rotMat*vec4(0,1,0,1)).xyz);
}

camera lerp(camera c1, camera c2, float p)
{
	import math.conversion;
	camera rtn;
	rtn.fov = lerp(c1.fov, c2.fov, p);
	rtn.aspect = lerp(c1.aspect, c2.aspect, p);
	rtn.zoom = lerp(c1.zoom, c2.zoom, p);
	rtn.near = lerp(c1.near, c2.near, p);
	rtn.far = lerp(c1.far, c2.far, p);
	rtn.eye = math.matrix.lerp(c1.eye, c2.eye, p);
	rtn.rot = math.matrix.lerp(c1.rot, c2.rot, p);
	rtn.invalidate();
	return rtn;
}

void drawCam(Image img, camera c, camera renderCam)
{
	import graphics.mesh;
	img.drawFrustrum(projectionMatrix(c.fov, c.aspect,c.near,c.near + (c.far - c.near)/10)*c.viewMatrix, renderCam);
}