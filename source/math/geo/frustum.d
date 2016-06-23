module math.geo.frustum;
import math.matrix;
import math.geo.plane;
import math.geo.AABox;

import std.stdio;

alias frustum = frustumT!float;

struct frustumT(T) {
	//private matrix!(4,4,T) m;
	private PlaneT!T[6] p_dat;

	public this(MatrixT!(4,T) mat) {
		//m = mat;
		dmat4 dmat = cast(dmat4)mat;
		auto inv = dmat.inverse();

		auto a = (inv * dvec4(-1, 1,-1, 1));
		auto b = (inv * dvec4(-1,-1,-1, 1));
		auto c = (inv * dvec4( 1,-1,-1, 1));
		auto d = (inv * dvec4( 1, 1,-1, 1));
		auto e = (inv * dvec4(-1, 1, 1, 1));
		auto f = (inv * dvec4(-1,-1, 1, 1));
		auto g = (inv * dvec4( 1,-1, 1, 1));
		auto h = (inv * dvec4( 1, 1, 1, 1));

		//auto center = (inv * matrix!(4,1,T)( 0,0,0, 1));
		//auto CENTER = (center/center.w).xyz;

		auto A = cast(VectorT!(3,T)) ((a/a.w).xyz);
		auto B = cast(VectorT!(3,T)) ((b/b.w).xyz);
		auto C = cast(VectorT!(3,T)) ((c/c.w).xyz);
		auto D = cast(VectorT!(3,T)) ((d/d.w).xyz);
		auto E = cast(VectorT!(3,T)) ((e/e.w).xyz);
		auto F = cast(VectorT!(3,T)) ((f/f.w).xyz);
		auto G = cast(VectorT!(3,T)) ((g/g.w).xyz);
		auto H = cast(VectorT!(3,T)) ((h/h.w).xyz);

		p_dat[0] = PlaneT!T(A, C, B);
		p_dat[1] = PlaneT!T(A, B, F);
		p_dat[2] = PlaneT!T(B, C, F);
		p_dat[3] = PlaneT!T(D, G, C);
		p_dat[4] = PlaneT!T(E, H, A);
		p_dat[5] = PlaneT!T(E, F, G);
	}

	public int intersect(AABoxT!T box) {
		auto vCorner = box.getCorners();
		int iTotalIn = 0;

		for(int p = 0; p < 6; p++) {
			
			int iInCount = 8;
			int iPtIn = 1;
			
			for(int i = 0; i < 8; i++) {
				// test this point against the planes
				if(p_dat[p].intersect(vCorner[i]) > 0) {
					iPtIn = 0;
					iInCount--;
				}
			}
			if(iInCount == 0)
				return 1;
			iTotalIn += iPtIn;
		}

		if(iTotalIn == 6)
			return -1;

		return 0;
	}
}