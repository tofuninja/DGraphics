module math.geo.box_sphere_intersect;
import math.matrix;

bool Box_Sphere_Intersect(vec3 Bmin, vec3 Bmax, vec3 center, float radius) {
	float dmin = 0;
	for(uint i = 0; i < 3; i++ ) {
		if(center[i] < Bmin[i]) {
			auto t = center[i] - Bmin[i];
			dmin += t*t;
		} else {
			if(center[i] > Bmax[i]) {
				auto t = center[i] - Bmax[i];
				dmin += t*t;
			}
		}
	}

	if( dmin < radius*radius) return true;
	return false;
} 