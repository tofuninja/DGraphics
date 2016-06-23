module math.geo.plane;
import math.matrix;

alias Plane = PlaneT!float;

struct PlaneT(T) {
	VectorT!(3,T) N;
	T D;

	this(VectorT!(3,T) A, VectorT!(3,T) B, VectorT!(3,T) C) {
		N = normalize(cross((B - A),(C - A)));
		D = -dot(N, A);
	}
	
	this(MatrixT!(4,T) mat) {
		alias vec3 = VectorT!(3,T);
		auto a = (mat*vec4(0,0,0,1)).xyz;
		auto b = (mat*vec4(0,0,1,1)).xyz;
		auto c = (mat*vec4(1,0,0,1)).xyz;
		this(a,b,c);
	}

	T intersect(VectorT!(3,T) v) {
		return dot( N~D, v~1);
	}
}

bool ray_plane_intersect(T)(PlaneT!T p, VectorT!(3,T) ray_start, VectorT!(3,T) ray_dir, out T dist) {
	auto d = dot(ray_dir, p.N);
	auto n = -(dot(ray_start, p.N) + p.D);

	if(d == 0) {
		dist = 0;
		return false;
	}
	
	dist = n/d;
	return true;
}