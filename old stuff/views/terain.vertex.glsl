////// DGRAPHICS \\\\\\
#version 330

uniform mat4 mvp;
uniform mat4 mMat;
uniform sampler2D text; 
uniform sampler2D grass; 
uniform sampler2D cloud;
uniform vec3 texTrans;
uniform float waterHeight;
uniform float time;

// Standard mesh input
in vec3 pos;
in vec3 norm;
in vec3 col;
in vec2 uv;

out vec4 color;
out vec2 texUV;
out vec3 n;
out vec3 worldPos;

out float cloudV;
out float h;
out float gr;



void main()
{
	vec4 p;
	vec2 nuv = uv*texTrans.z + texTrans.xy;
	gr = texture(grass, nuv).x;
	cloudV = texture(cloud, nuv + vec2(time*0.01f,0)).x;
	h = texture(text, nuv).x;
	
	
	p.xyz = pos;
	p.w = 1;
	p.y = h;
	p.y = max(p.y, waterHeight);
	
	color.xyz = col;
	color.w = 1;
	
	texUV = uv;
	n = norm;
	
	
	
	worldPos = (mMat*p).xyz;
	gl_Position = mvp*p;
}