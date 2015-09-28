#version 330

uniform sampler2D grass;
uniform sampler2D cloud;
uniform sampler2D noisetext;
uniform mat4 vp;
uniform float time;


// Standard mesh input
in vec3 pos;
in vec3 norm;
in vec3 col;
in vec2 uv;
in vec3 translate;
in vec3 scale;


out vec4 color;
out vec2 texUV;
out vec2 mapLoc;
out vec3 n;
out float h;
out float gr;
out float cloudV;
flat out int InstanceID; 


void main()
{
	vec4 p;
	
	mapLoc = (translate.xz + vec2(30,30))/60.0f;
	
	gr = texture(grass, mapLoc).x;
	cloudV = texture(cloud, mapLoc + vec2(time*0.01f,0)).x;
	
	
	p.xyz = pos*scale + translate;
	p.w = 1;
	
	h = p.y/20.f;
	
	color.xyz = col;
	color.w = 1;
	
	texUV = uv;
	n = norm;
	InstanceID = gl_InstanceID; 
	gl_Position = vp*p;
}