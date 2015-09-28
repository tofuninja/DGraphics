#version 330	

in vec3 fragNorm;
in vec3 fragWorldPos;
out vec4 fragColor;

void main()
{
	fragColor = vec4((fragNorm + vec3(1,1,1))/2.0f, 1);
}
