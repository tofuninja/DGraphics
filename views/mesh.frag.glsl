#version 420	

in vec3 fragNorm;
in vec2 fragUv; 
in vec3 fragWorldPos;
layout(location = 0) out vec3 outColor;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) out uvec4 outId;

layout(binding = 0) uniform sampler2D text; 

void main() {
	outColor = texture(text, fragUv).xyz;
	outNormal = fragNorm;
	outWorldPos = fragWorldPos;
	outId = uvec4(0,0,0,0);
}
