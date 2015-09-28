#version 330	


in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;

uniform sampler2D text; 

void main()
{
	fragColor.xyz = texture(text, texUV).xyz;
	fragColor.w = 1;
}
