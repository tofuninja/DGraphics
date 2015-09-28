#version 330	

in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;

uniform sampler2D cloud;
uniform float cloudLayer;
uniform float time;

void main()
{
	float c = texture(cloud, texUV + vec2(time*0.01f,0)).x;
	c = smoothstep(0.5f,0.6f, c)*0.3f;
	fragColor = vec4(1,1,1,c*cloudLayer);
}
