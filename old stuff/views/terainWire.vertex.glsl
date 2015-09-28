////// DGRAPHICS \\\\\\
#version 330

uniform mat4 mvp;
uniform mat4 mMat;

uniform vec3 texTrans;
uniform float waterHeight;

// Standard mesh input
in vec3 pos;
in vec3 norm;
in vec3 col;
in vec2 uv;

out vec4 color;
out vec2 texUV;
out vec3 n;
out vec3 worldPos;

uniform sampler2D text; 

void main()
{
	vec4 p;
	float uvx = uv.x * texTrans.z;
	float uvy = uv.y * texTrans.z;
	p.xyz = pos;
	p.w = 1;
	p.y = texture(text, vec2(uvx,uvy) + texTrans.xy).x;
	p.y = max(p.y, waterHeight);
	
	color.xyz = col;
	color.w = 1;
	
	texUV = uv;
	n = norm;
	
	worldPos = (mMat*p).xyz;
	gl_Position = mvp*p;
}