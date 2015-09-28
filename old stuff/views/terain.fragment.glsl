////// DGRAPHICS \\\\\\
#version 330	

uniform float snowTop;
uniform vec3 texTrans;
uniform float time;
uniform float waterHeight;

uniform sampler2D text; 
uniform sampler2D watertext; 
uniform sampler2D noisetext; 
uniform sampler2D grass; 
uniform sampler2D cloud;


in vec2 texUV;
in float cloudV;
in float h;
in float gr;
out vec4 fragColor;


void main()
{
	vec2 nuv = texUV *texTrans.z + texTrans.xy;
	float river = texture(watertext, nuv).x;
	//float gr = texture(grass, nuv).x;
	//float cloudV = texture(cloud, nuv + vec2(time*0.01f,0)).x;
	//float h = texture(text, nuv).x;
	float rn = texture(noisetext, nuv + vec2(time*0.01f,0)).x;
	rn += texture(noisetext, nuv*2 + vec2(0,time*0.02f)).x/2.0f;
	rn += texture(noisetext, nuv*4 + vec2(-time*0.03f,0)).x/4.0f;
	rn += texture(noisetext, nuv*16 + vec2(time*0.04f,0)).x/16.0f;
	rn = rn/20.0f + 0.7f;
	float rn2 = texture(noisetext, nuv*2).x;
	rn2 += texture(noisetext, nuv*16).x/8;
	float rn3 = texture(noisetext, nuv*32).x;

	float s = smoothstep(0.2f, 0.21f, rn2*15*(max(h,snowTop)-snowTop)/(1.0f-snowTop));
	float mtnColor = 5*(h - snowTop) + 0.4f;
	
	fragColor.xyz = vec3((gr)*0.6f,(1-gr)*0.5f + 0.2f,0)*(0.9f + rn3*0.05f);
	fragColor = (1-s)*fragColor + s*vec4(mtnColor,mtnColor,mtnColor,1);
	fragColor = mix(fragColor, vec4(1,1,0,1), min(1,0.01f/(h - waterHeight+0.001f)));
	if(river > 0.4 || h < waterHeight) fragColor = vec4(0,0.3f,rn,1);
	
	fragColor *= 1.3f - smoothstep(0.5f,0.6f, cloudV)*0.3f;
	
	fragColor.w = 1;
}
