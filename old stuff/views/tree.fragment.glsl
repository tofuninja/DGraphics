#version 330	


in vec4 color;
in vec2 texUV;
in vec2 mapLoc;
in vec3 n;
flat in int InstanceID;
in float h;
in float gr;
in float cloudV;

out vec4 fragColor;

uniform float time;
uniform float snowTop;
uniform sampler2D noisetext;
uniform sampler2D grass;
uniform sampler2D cloud;

void main()
{
	vec2 iUV = texUV + vec2(InstanceID%10, InstanceID%10)*0.3f;
	float rn = texture(noisetext, iUV/4.0f).x;
	float rn2 = texture(noisetext, iUV).x;
	//float gr = texture(grass, mapLoc).x;
	//float cloudV = texture(cloud, mapLoc + vec2(time*0.01f,0)).x;
	
	fragColor.xyz = vec3(0,0.2f*rn + 0.4f - gr*0.3f,0);
	fragColor = mix(fragColor, vec4(1,1,1,1), rn2*(max(h,snowTop)-snowTop)/(0.8-snowTop));
	fragColor *= 1.3f - smoothstep(0.5f,0.6f, cloudV)*0.3f;
	fragColor.w = 1;
}
