module math.generation.sphere;

import math.matrix;

vec3[] sphereMesh(uint res) {
	auto points = new vec3[3*4*(4^^res)];
	uint current = 0;

	void tesalate(uint depth, vec3[3] tri...) {
		if(depth == 0) {
			points[current + 0] = tri[0];
			points[current + 1] = tri[1];
			points[current + 2] = tri[2];
			current += 3;
			return;
		}
		
		auto a = normalize(tri[0] + (tri[1] - tri[0])/2.0f);
		auto b = normalize(tri[1] + (tri[2] - tri[1])/2.0f);
		auto c = normalize(tri[2] + (tri[0] - tri[2])/2.0f);
		tesalate(depth - 1, a, b, c);
		tesalate(depth - 1, tri[0], a, c);
		tesalate(depth - 1, tri[1], b, a);
		tesalate(depth - 1, tri[2], c, b);
	}

	enum p1 = normalize(vec3( 1, 1, 1));
	enum p2 = normalize(vec3( 1,-1,-1));
	enum p3 = normalize(vec3(-1, 1,-1));
	enum p4 = normalize(vec3(-1,-1, 1));

	tesalate(res, p1, p3, p2);
	tesalate(res, p3, p4, p2);
	tesalate(res, p1, p4, p3);
	tesalate(res, p1, p2, p4);
	return points;
}