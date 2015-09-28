#version 330	

in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;


void main()
{
	fragColor = vec4(n ,1);
}


