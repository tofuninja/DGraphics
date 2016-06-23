module math.geo.box_ray_intersect;
import math.matrix;

private enum RIGHT 	= 0;
private enum LEFT 	= 1;
private enum MIDDLE = 2;

bool Box_Ray_Intersect(vec3 minB, vec3 maxB, vec3 origin, vec3 dir, out vec3 coord) {
	bool inside = true;
	ubyte[3] quadrant;
	float[3] candidatePlane;

	/* Find candidate planes; this loop can be avoided if
   	rays cast all from the eye(assume perpsective view) */
	for(uint i = 0; i < 3; i++) {
		if(origin[i] < minB[i]) {
			quadrant[i] = LEFT;
			candidatePlane[i] = minB[i];
			inside = false;
		} else if (origin[i] > maxB[i]) {
			quadrant[i] = RIGHT;
			candidatePlane[i] = maxB[i];
			inside = false;
		} else {
			quadrant[i] = MIDDLE;
		}
	}

	/* Ray origin inside bounding box */
	if(inside) {
		coord = origin;
		return true;
	}

	/* Calculate T distances to candidate planes */
	float[3] maxT;
	for (uint i = 0; i < 3; i++) {
		if (quadrant[i] != MIDDLE && dir[i] != 0)
			maxT[i] = (candidatePlane[i]-origin[i]) / dir[i];
		else
			maxT[i] = -1.;
	}
	/* Get largest of the maxT's for final choice of intersection */
	int whichPlane = 0;
	for (uint i = 1; i < 3; i++) {
		if (maxT[whichPlane] < maxT[i])
			whichPlane = i;
	}

	/* Check final candidate actually inside box */
	if (maxT[whichPlane] < 0) return false;

	for (uint i = 0; i < 3; i++) {
		if (whichPlane != i) {
			coord[i] = origin[i] + maxT[whichPlane] *dir[i];
			if (coord[i] < minB[i] || coord[i] > maxB[i])
				return false;
		} else {
			coord[i] = candidatePlane[i];
		}
	}

	return true; /* ray hits box */
}	
