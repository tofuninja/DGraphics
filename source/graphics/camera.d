module graphics.camera;
import math.matrix;
import graphics.hw.state;
import graphics.image;
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
		invalidate(this);
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
	img.drawFrustrum(projectionMatrix(c.fov/c.zoom, c.aspect,c.near,c.near + (c.far - c.near)/10)*c.viewMatrix, renderCam);
}

struct cameraPath
{
	import std.typecons;
	import std.container;
	import std.algorithm;
	import std.exception;

	public int minTime;
	public int maxTime;
	private int count = 0;
	private DList!(Tuple!(int, camera)) frames;

	public void addFrame(int time, camera cam)
	{
		cam.invalidate();
		auto r = frames[].find!"a[0] > b"(time);
		if(r.empty) frames.insertBack(tuple(time, cam));
		else frames.insertBefore(r, tuple(time, cam));

		if(count == 0)
		{
			minTime = time;
			maxTime = time;
		}
		else
		{
			minTime = min(minTime, time);
			maxTime = max(maxTime, time);
		}
		count ++;
	}

	public camera getCamAtTime(int time)
	{
		enforce(count > 0, "Can not get camera without any key frames");
		if(count == 1) return frames.front[1];
		if(time <= minTime) return frames.front[1];
		if(time >= maxTime) return frames.back[1];

		bool found = false;
		Tuple!(int, camera) cam1;
		Tuple!(int, camera) cam2;
		foreach(v; frames)
		{
			if(v[0] > time)
			{
				cam2 = v;
				break;
			}
			cam1 = v;
		}
		return lerp(cam1[1], cam2[1], (cast(float)time - cast(float)cam1[0])/(cast(float)cam2[0] - cast(float)cam1[0]));
	}
}

void saveCameraPath(cameraPath c, string filePath)
{
	import std.stdio;
	import std.typecons;
	auto f = File(filePath, "w");
	foreach(Tuple!(int, camera) v; c.frames)
	{
		camera cam = v[1];
		f.writeln(v[0], ":", cam.fov, " ", cam.aspect, " ", cam.zoom, " ", cam.near, " ", cam.far, " ", cam.eye, " ", cam.rot);
	}
}

cameraPath loadCameraPath(string filePath)
{
	import std.stdio;
	import std.typecons;
	import std.format;
	auto f = File(filePath, "r");

	cameraPath rtn;

	foreach(char[] line; f.byLine)
	{
		if(line == "" || line == "\n") continue;
		int time;
		float fov, aspect, zoom, near, far, eye_x, eye_y, eye_z, rot_x, rot_y, rot_z;
		camera c;
		line.formattedRead("%s:%s %s %s %s %s [%s;%s;%s] [%s;%s;%s]", &time, &fov, &aspect, &zoom, &near, &far, &eye_x, &eye_y, &eye_z, &rot_x, &rot_y, &rot_z);
		c.fov = fov;
		c.aspect = aspect;
		c.zoom = zoom;
		c.near = near;
		c.far = far;
		c.eye = vec3(eye_x, eye_y, eye_z);
		c.rot = vec3(rot_x, rot_y, rot_z);
		rtn.addFrame(time,c);
	}
	return rtn;
}