module graphics.camera;
import math.matrix;
import graphics.image;


public struct Camera
{
	public float fov;
	public float aspect;
	public float zoom;
	public float near;
	public float far;
	public vec3 eye;
	public vec3 lookAt;
	public vec3 up;

	public mat4 projMatrix()
	{
		return projectionMatrix(fov/zoom, aspect, near, far);
	}

	public mat4 viewMatrix()
	{
		return math.matrix.viewMatrix(eye, lookAt, up);
	}

	public mat4 camMatrix()
	{
		return projMatrix*viewMatrix;
	}

	public void setRot(vec3 rot)
	{
		auto rotMat = rotationMatrix(rot);
		lookAt = eye + (rotMat*vec4(0,0,1,1)).xyz;
	}

	public this(float fov, float aspect, float near = 0.01f, float far = 400f)
	{
		this.fov = fov;
		this.aspect = aspect;
		zoom = 1;
		this.near = near;
		this.far = far;
		eye = vec3(0,0,0);
		lookAt = vec3(0,0,1);
		up = vec3(0,1,0); 
	}
}

Camera lerp(Camera c1, Camera c2, float p)
{
	import math.conversion;
	Camera rtn;
	rtn.fov = lerp(c1.fov, c2.fov, p);
	rtn.aspect = lerp(c1.aspect, c2.aspect, p);
	rtn.zoom = lerp(c1.zoom, c2.zoom, p);
	rtn.near = lerp(c1.near, c2.near, p);
	rtn.far = lerp(c1.far, c2.far, p);
	rtn.eye = math.matrix.lerp(c1.eye, c2.eye, p);
	rtn.lookAt = math.matrix.lerp(c1.lookAt, c2.lookAt, p);
	rtn.up = math.matrix.lerp(c1.up, c2.up, p);
	return rtn;
}
