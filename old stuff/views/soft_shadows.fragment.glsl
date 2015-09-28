#version 330	

// Light and box locations
uniform vec3 box1;
uniform vec3 box2;
uniform vec3 box3;
uniform float box_size;
uniform vec3  light_loc;
uniform float light_intensity; 
uniform float light_size;

in vec4 color;
in vec2 texUV;
in vec3 n;
in vec3 worldPos;
out vec4 fragColor;


// Ray intersection found at
// https://github.com/hpicgs/cgsee/wiki/Ray-Box-Intersection-on-the-GPU

struct Ray 
{
    vec3 origin;
    vec3 direction;
    vec3 inv_direction;
    int sign[3];
};

Ray makeRay(vec3 origin, vec3 direction) 
{
	Ray rtn;
    vec3 inv_direction = vec3(1.0) / direction;
	rtn.origin = origin;
	rtn.direction = direction;
	rtn.inv_direction = inv_direction;
	rtn.sign[0] = (inv_direction.x < 0) ? 1 : 0;
	rtn.sign[1] = (inv_direction.y < 0) ? 1 : 0;
	rtn.sign[2] = (inv_direction.z < 0) ? 1 : 0;
	return rtn;
}

void intersection_distances_no_if(in Ray ray, in vec3 aabb[2], out float tmin, out float tmax)
{
    float tymin, tymax, tzmin, tzmax;
    tmin = (aabb[ray.sign[0]].x - ray.origin.x) * ray.inv_direction.x;
    tmax = (aabb[1-ray.sign[0]].x - ray.origin.x) * ray.inv_direction.x;
    tymin = (aabb[ray.sign[1]].y - ray.origin.y) * ray.inv_direction.y;
    tymax = (aabb[1-ray.sign[1]].y - ray.origin.y) * ray.inv_direction.y;
    tzmin = (aabb[ray.sign[2]].z - ray.origin.z) * ray.inv_direction.z;
    tzmax = (aabb[1-ray.sign[2]].z - ray.origin.z) * ray.inv_direction.z;
    tmin = max(max(tmin, tymin), tzmin);
    tmax = min(min(tmax, tymax), tzmax);
    // post condition:
    // if tmin > tmax (in the code above this is represented by a return value of INFINITY)
    //     no intersection
    // else
    //     front intersection point = ray.origin + ray.direction * tmin (normally only this point matters)
    //     back intersection point  = ray.origin + ray.direction * tmax
}

bool boxIntersect(in Ray r, in vec3 box)
{
	
	float tmin;
	float tmax;
	vec3 aabb[2];
	aabb[0] = vec3(-box_size,-box_size,-box_size) + box;
	aabb[1] = vec3(box_size,box_size,box_size) + box;
	
	intersection_distances_no_if(r, aabb, tmin, tmax);
		
	return !(tmin > tmax) && tmin > -0.001;
}

bool allBoxIntersect(vec3 start, vec3 end)
{
	vec3 direction = (end - start);
	direction = direction / length(direction);
	Ray r = makeRay(start, direction);

	return boxIntersect(r, box1) || boxIntersect(r, box2) || boxIntersect(r, box3);
}

void main()
{
	int i,j;
	float totalLight = 0.0f;
	for(i = 0; i < 16; i++)
	{
		for(j = 0; j < 16; j++)
		{
			bool hit = allBoxIntersect(worldPos, light_loc + vec3(i*light_size, 0, j*light_size));
			totalLight += (light_intensity)*float(!hit);
		}
	}

	fragColor = vec4(totalLight,totalLight,totalLight,1);
}
