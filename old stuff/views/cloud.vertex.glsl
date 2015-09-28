#version 330

uniform mat4 mvp;
uniform mat4 mMat;

// Standard mesh input
in vec3 pos;
in vec3 norm;
in vec3 col;
in vec2 uv;

out vec4 color;
out vec2 texUV;
out vec3 n;
out vec3 worldPos;

void main()
{
	vec4 p;
	
	p.xyz = pos;
	p.w = 1;
	
	color.xyz = col;
	color.w = 1;
	
	texUV = uv;
	n = norm;
	
	worldPos = (mMat*p).xyz;
	gl_Position = mvp*p;
}