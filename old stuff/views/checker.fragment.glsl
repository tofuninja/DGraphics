#version 330	


in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;

void main()
{
	int col = (int(texUV.x*10.0 )+ int(texUV.y*10.0))%2;
	fragColor = vec4(col,col,col,1);
}
