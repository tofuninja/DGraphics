#version 440

layout(std140, binding = 0) uniform sceneUniforms
{
  mat4 projection;
};

layout(location = 0)in vec3 loc;
layout(location = 1)in vec3 norm;
layout(location = 2)in vec3 uv;
layout(location = 3)in mat4 transform;

out vec3 fragNorm;
out vec3 fragWorldPos;

void main()
{
	vec4 p = vec4(loc, 1);
	fragNorm = norm;
	fragWorldPos = (transform*p).xyz;
	gl_Position = projection*transform*p;
}