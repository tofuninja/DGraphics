#version 330	

in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;

uniform vec3 eye;
uniform mat4 depthCam;
uniform vec3 depthCamplaneNorm;
uniform float depthCamplaneD;


uniform sampler2D depthImage;
uniform sampler2D depthDepthImage;
uniform samplerCube enviroMap;
uniform vec3 planeNorm;
uniform vec3 planeUp;
uniform vec3 planeOrig;
uniform float planeD;
uniform float planeSize;

float planeIntersection(vec3 o, vec3 dir, vec3 pn, float pd)
{
	return -(dot(o,pn) + pd) / dot(dir, pn);
}

float planeIntersection(vec3 o, vec3 dir, vec3 A, vec3 B, vec3 C)
{
	vec3 n = normalize(cross((B - A),(C - A)));
	float d = -dot(n, A);
	return planeIntersection(o, dir, n, d);
}

bool pointInFrustrum(vec3 p, mat4 frustrum)
{
	vec4 r = frustrum*vec4(p, 1);
	r /= r.w;
	return ( r.x >= -1.01 && r.x <= 1.01 && r.y >= -1.01 && r.y <= 1.01 && r.z >= -1.01 && r.z <= 1.01);
}

bool clipRay(vec3 ro, vec3 rd, out float near, out float far)
{
	mat4 inv = inverse(depthCam); 
	vec4 a = (inv * vec4(-1, 1,-1, 1));
	vec4 b = (inv * vec4(-1,-1,-1, 1));
	vec4 c = (inv * vec4( 1,-1,-1, 1));
	vec4 d = (inv * vec4( 1, 1,-1, 1));
	vec4 e = (inv * vec4(-1, 1, 1, 1));
	vec4 f = (inv * vec4(-1,-1, 1, 1));
	vec4 g = (inv * vec4( 1,-1, 1, 1));
	vec4 h = (inv * vec4( 1, 1, 1, 1));
	
	vec3 A = (a/a.w).xyz;
	vec3 B = (b/b.w).xyz;
	vec3 C = (c/c.w).xyz;
	vec3 D = (d/d.w).xyz;
	vec3 E = (e/e.w).xyz;
	vec3 F = (f/f.w).xyz;
	vec3 G = (g/g.w).xyz;
	vec3 H = (h/h.w).xyz;
	
	float mink = 99999, maxk = -99999, k;
	
	k = planeIntersection(ro, rd, A, B, C);
	if(pointInFrustrum(ro + k*rd, depthCam))
	{ mink = min(mink, k); maxk = max(maxk, k); }
	
	k = planeIntersection(ro, rd, A, B, F);
	if(pointInFrustrum(ro + k*rd, depthCam))
	{ mink = min(mink, k); maxk = max(maxk, k); }
	
	k = planeIntersection(ro, rd, B, C, F);
	if(pointInFrustrum(ro + k*rd, depthCam))
	{ mink = min(mink, k); maxk = max(maxk, k); }
	
	k = planeIntersection(ro, rd, D, C, G);
	if(pointInFrustrum(ro + k*rd, depthCam))
	{ mink = min(mink, k); maxk = max(maxk, k); }
	
	k = planeIntersection(ro, rd, E, A, D);
	if(pointInFrustrum(ro + k*rd, depthCam))
	{ mink = min(mink, k); maxk = max(maxk, k); }
	
	k = planeIntersection(ro, rd, E, F, G);
	if(pointInFrustrum(ro + k*rd, depthCam))
	{ mink = min(mink, k); maxk = max(maxk, k); }
	
	if(mink<0) mink = 0;
	//return true;
	near = mink;
	far = maxk;
	return mink <= maxk;
}

bool depthIntersect(vec3 ro, vec3 rd, out vec4 output_color)
{
	vec4 ap,bp;

	float n, f; 
	if(!clipRay(ro, rd, n, f)) return false;
	
	//output_color = vec4(1,0,n,1);
	//return true;
	
	ap = depthCam*vec4(ro + rd*n, 1);
	bp = depthCam*vec4(ro + rd*f, 1);
	
	ap = ap/ap.w;
	bp = bp/bp.w;
	
	//ap.xy = ap.xy/2 + vec2(0.5, 0.5);
	//bp.xy = bp.xy/2 + vec2(0.5, 0.5);

	//if(abs(1 - bp.z) > 0.3) bp.z = 0.9;
	int		stepsN 	= int(max(ceil(abs((ap.x-bp.x)*320)), ceil(abs((ap.y-bp.y)*320))));
	vec3 	s0 		= ap.xyz; 
	float 	zr0 	= ap.z;
	
	for(int i = 0; i < stepsN; i++)
	{
		vec3  s1  	= ap.xyz + ((bp.xyz - ap.xyz) * ((i+1.0) / float(stepsN)));
		float zr1 	= ap.z   + ((bp.z   - ap.z  ) * ((i+1.0) / float(stepsN)));
		
		//              A         B                         C           D   
		// k = Line[(0, zr0), (1, zr1)] intersect Line[(0, Z[s0]), (1, Z[s1])])
		
		float A = zr0;
		float B = zr1;
		float C = texture(depthDepthImage, s0.xy/2.0 + vec2(0.5,0.5)).x*2.0 - 1.0;
		float D = texture(depthDepthImage, s1.xy/2.0 + vec2(0.5,0.5)).x*2.0 - 1.0;
		
		float k = (A-C)/((D-C)-(B-A));
		if (k >= 0 && k <= 1) // Intersection 
		{
			vec2 t = (s0 + (s1-s0)*k).xy;
			float z = texture(depthDepthImage, t/2.0 + vec2(0.5,0.5)).x*2.0 - 1.0;
			if(abs(z - 1) > 0.01 ) //&& t.x > 0 && t.x < 1 && t.y > 0 && t.y < 1)
			{
				vec4 tCol = texture(depthImage, t/2.0 + vec2(0.5,0.5));
				output_color = vec4(tCol.xyz, 1);
				return true;
			}
		}
		s0 = s1; 
		zr0 = zr1;
	}
	return false;
	
	
	
}



void main()
{
	float near, far;
	vec3 reflection = reflect(normalize(worldPos-eye), normalize(n));
	float pIntercept = planeIntersection(worldPos, reflection, planeNorm, planeD);
	
	float pY = (worldPos + reflection*pIntercept - planeOrig).z/planeSize + 0.5;
	float pX = (worldPos + reflection*pIntercept - planeOrig).x/planeSize + 0.5;
	
	fragColor = texture(enviroMap, reflection);
	
	if(pIntercept > 0 && pX > 0 && pX < 1 && pY > 0 && pY < 1)
	{
		int col = (int(pX*10.0 )+ int(pY*10.0))%2;
		fragColor = vec4(col,col,col,1);
	}
	
	vec4 depthColor;
	if(depthIntersect(worldPos, reflection, depthColor))
	{
		fragColor = depthColor;
	}
	
}
