#version 440

layout(std140, binding = 0) uniform sceneUniforms
{
  mat4 projection;
  vec4 size;
};

layout(location = 0)in vec3 loc;
layout(location = 1)in vec3 norm;
layout(location = 2)in vec2 uv;
layout(location = 3)in mat4 transform;

out vec3 fragNorm;
out vec2 fragUv; 
out vec3 fragWorldPos;


void main() {
	vec4 p = vec4(loc, 1);
	fragUv = uv;
	fragUv.y = 1 - fragUv.y;
	fragWorldPos = (transform*p).xyz;
	fragNorm = normalize((transform*vec4(loc+norm,1)).xyz - fragWorldPos);
	gl_Position = projection*transform*p;
}