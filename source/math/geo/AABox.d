module math.geo.AABox;
import math.matrix;

alias AABox = AABoxT!float;

struct AABoxT(T) {
	VectorT!(3,T) center;
	VectorT!(3,T) size;

	this(VectorT!(3,T) center, VectorT!(3,T) size) {
		this.center = center;
		this.size = size;
	}

	VectorT!(3,T)[8] getCorners() {
		VectorT!(3,T)[8] ret;
		auto s = size/2;
		ret[0] = center + VectorT!(3,T)( s.x, s.y, s.z);
		ret[1] = center + VectorT!(3,T)( s.x, s.y,-s.z);
		ret[2] = center + VectorT!(3,T)( s.x,-s.y, s.z);
		ret[3] = center + VectorT!(3,T)( s.x,-s.y,-s.z);
		ret[4] = center + VectorT!(3,T)(-s.x, s.y, s.z);
		ret[5] = center + VectorT!(3,T)(-s.x, s.y,-s.z);
		ret[6] = center + VectorT!(3,T)(-s.x,-s.y, s.z);
		ret[7] = center + VectorT!(3,T)(-s.x,-s.y,-s.z);
		return ret;
	}

	AABoxT!T transform(MatrixT!(4,T) mat) {
		auto corners = getCorners();
		//import std.stdio;

		auto min_v = (mat*(corners[0] ~ 1)).xyz;
		auto max_v = (mat*(corners[0] ~ 1)).xyz;
		//writeln(corners[0], " ", min_v);

		for(uint i = 1; i < 8; i++) {
			auto v = (mat*(corners[i] ~ 1)).xyz;
			//writeln(corners[i], " ", v);
			if(v.x < min_v.x) min_v.x = v.x;
			if(v.y < min_v.y) min_v.y = v.y;
			if(v.z < min_v.z) min_v.z = v.z;
			if(v.x > max_v.x) max_v.x = v.x;
			if(v.y > max_v.y) max_v.y = v.y;
			if(v.z > max_v.z) max_v.z = v.z;
		} 

		return AABox(min_v + (max_v - min_v)/2.0f, max_v - min_v);
	}
}


