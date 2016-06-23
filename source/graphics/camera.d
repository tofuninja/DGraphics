module graphics.camera;
import math.matrix;
// If the camera is ortho, will just reinterpret the fov to the width of the ortho box
public struct Camera
{
	import math.conversion;
	float fov    = toRad(70);
	float aspect = 1;
	float near   = 1.0f;
	float far    = 2.0f;
	vec3 eye     = vec3(0,0,0);
	vec3 lookAt  = vec3(0,0,1);
	vec3 up      = vec3(0,1,0);
	bool ortho   = false;

	public mat4 projMatrix() {
		if(ortho) return orthoMatrix(fov, aspect, near, far);
		else return projectionMatrix(fov, aspect, near, far);
	}

	public mat4 viewMatrix() {
		return math.matrix.viewMatrix(eye, lookAt, up);
	}

	public mat4 camMatrix() {
		return projMatrix*viewMatrix;
	}

	/// Rotates the camera around the eye by the yaw pich roll vector ypr
	public void setRot(vec3 ypr) {
		auto rotMat = rotationMatrix(quatern(ypr));
		lookAt = eye + (rotMat*vec4(0,0,1,1)).xyz;
	}

	/// Sets the cameras look at point to be at
	public void setLookAt(vec3 at) {
		lookAt = at;
	}

	/// Sets the cameras eye point to be e
	public void setEye(vec3 e) {
		eye = e;
	}

	/// Moves the camera relitive to its current orientation
	public void moveRelitive(vec3 m) {
		auto f = normalize(lookAt-eye);
		auto r = normalize(cross(up, f));
		auto u = up;
		auto d = m.x*r + m.y*u + m.z*f;
		eye = eye + d;
		lookAt = lookAt + d;
	}

	/// Rotates the camera relitive to its current orientation
	public void rotateRelitive(vec2 angles) {
		auto f = normalize(lookAt-eye);
		auto r = normalize(cross(up, f));
		auto rotMat = rotationMatrix(quatern(up, angles.x))*rotationMatrix(quatern(r, angles.y));
		auto f4 = vec4(0,0,0,1);
		f4.xyz = f;
		lookAt = eye + (rotMat*f4).xyz;
	}

	public this(float fov, float aspect, vec3 upVector = vec3(0,1,0), float near = 0.01f, float far = 400f) {
		this.fov = fov;
		this.aspect = aspect;
		this.near = near;
		this.far = far;
		eye = vec3(0,0,0);
		lookAt = vec3(0,0,1);
		up = upVector; 
	}
}

Camera lerp(Camera c1, Camera c2, float p) {
	import math.conversion: mlerp=lerp;
	Camera rtn;
	rtn.fov = mlerp(c1.fov, c2.fov, p);
	rtn.aspect = mlerp(c1.aspect, c2.aspect, p);
	rtn.near = mlerp(c1.near, c2.near, p);
	rtn.far = mlerp(c1.far, c2.far, p);
	rtn.eye = math.matrix.lerp(c1.eye, c2.eye, p);
	rtn.lookAt = math.matrix.lerp(c1.lookAt, c2.lookAt, p);
	rtn.up = math.matrix.lerp(c1.up, c2.up, p);
	return rtn;
}
