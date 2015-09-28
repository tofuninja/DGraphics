////// DGRAPHICS \\\\\\
#version 330	


uniform vec3 texTrans;
in vec2 texUVf;
out vec4 fragColor;

uniform sampler2D text; 

void main()
{
	fragColor.xyz = vec3(1,1,1);
	fragColor.w = 1;
}
