#version 330	

in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;


void main()
{
	fragColor = mix(vec4(0, 0, 1, 1),vec4(0.6f, 0.8f, 1.0f, 1), min(length(worldPos)/100.0f, 1));
}
