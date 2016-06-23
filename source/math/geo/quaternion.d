module math.geo.quaternion;
import std.traits;
import std.math;
import core.simd;
import util.integerSeq;
import math.geo.vector;


alias Quaternion = QuaternionT!float;
alias quatern = Quaternion;

/// A quaternion type, could have just used a vec4 but this allows for type checking which is always better
struct QuaternionT(T) {
	alias ELEMENT_TYPE = T;
	static assert(isNumeric!T);
	T[4] quat = [0,0,0,1];

	auto ref x() { return quat[0]; }
	auto ref y() { return quat[1]; }
	auto ref z() { return quat[2]; }
	auto ref w() { return quat[3]; }

	/// Constructs a quaternion for rotation
	this(VectorT!(3,T) axis, T angle) {
		axis = math.geo.vector.normalize(axis);
		T c = cast(T)cos(angle/2);
		T s = cast(T)sin(angle/2);
		quat = [s*axis.x,s*axis.y,s*axis.z,c];
	}

	this(VectorT!(3,T) ypr) {
		this(ypr.x, ypr.y, ypr.z);
	}

	this(T yaw, T pitch, T roll) {
		alias Q = typeof(this);
		alias V = VectorT!(3,T);
		auto y = Q(V(0,1,0), yaw);
		auto p = Q(V(0,0,1), pitch);
		auto r = Q(V(1,0,0), roll);
		this = y*p*r;
	}

	this(T[4] data...) {
		quat[] = data[];
	}

	auto rotate(VectorT!(3,T) v) {
		alias Q = typeof(this);
		alias V = VectorT!(3,T);
		auto p = this*Q(v.x, v.y, v.z, 0)*conjugate(this);
		return V(p.x, p.y, p.z);
	}

	auto opBinary(string op : "*",T)(QuaternionT!T b) {
		auto a = this;
		QuaternionT!T r;
		
		r.x = a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y;
		r.y = a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x;
		r.z = a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w;
		r.w = a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z;

		//ret[3] = (r[3]*q[3] - r[0]*q[0] - r[1]*q[1] - r[2]*q[2]);
		//ret[0] = (r[3]*q[0] + r[0]*q[3] - r[1]*q[2] + r[2]*q[1]);
		//ret[1] = (r[3]*q[1] + r[0]*q[2] + r[1]*q[3] - r[2]*q[0]);
		//ret[2] = (r[3]*q[2] - r[0]*q[1] + r[1]*q[0] + r[2]*q[3]);
		return r;
	}

	auto opOpAssign(string op, R)(R rhs) {
		this = opBinary!(op)(rhs);
		return this;
	}

	ref T opIndex(size_t i) {
		return quat[i];
	}
}

auto normalize(T)(QuaternionT!T q) {
	auto v = VectorT!(4,T)(q.quat);
	v = math.geo.vector.normalize(v);
	return QuaternionT!T(v.data);
}

auto conjugate(T)(QuaternionT!T i) {
	i.quat[0] = -i.quat[0];
	i.quat[1] = -i.quat[1];
	i.quat[2] = -i.quat[2];
	return i;
}

auto axisAngle(T)(QuaternionT!T i) {
	auto angle = acos(i.quat[3]);
	if(angle == 0) {
		return VectorT!(4,T)(1,0,0,0);
	}
	auto s = cast(T)sin(angle);
	auto axis = VectorT!(3,T)(i.quat[0]/s, i.quat[1]/s, i.quat[2]/s);
	axis = math.geo.vector.normalize(axis);
	return axis ~ (angle*2);
}

void swingTwist(T)(QuaternionT!T rotation, VectorT!(3,T) direction, out QuaternionT!T swing, out QuaternionT!T twist) {
    auto ra = VectorT!(3,T)( rotation.x, rotation.y, rotation.z ); 
    auto p = projection(ra, direction ); 
    twist = QuaternionT!T(p.x, p.y, p.z, rotation.w );
    twist = normalize(twist);
    swing = rotation * twist.conjugate;
}

auto rotationInAxis(T)(QuaternionT!T q, VectorT!(3,T) axis) {
	QuaternionT!T s,t;
	swingTwist(q,axis,s,t);
	auto aa = axisAngle(t);
	return aa.w*dot(aa.xyz, axis);
}

auto getYPR(T)(QuaternionT!T q) {
	import std.math;
	T yaw,pitch,roll;

	auto test = q.x*q.y + q.z*q.w;
	if (test > 0.4999) { // singularity at north pole
		yaw = 2 * atan2(q.x,q.w);
		pitch = cast(T)(PI/2);
		roll = 0;
	} else if (test < -0.4999) { // singularity at south pole
		yaw = -2 * atan2(q.x,q.w);
		pitch = - cast(T)(PI/2);
		roll = 0;
	} else {
		auto sqx = q.x*q.x;
		auto sqy = q.y*q.y;
		auto sqz = q.z*q.z;
		yaw = atan2(2*q.y*q.w-2*q.x*q.z , 1 - 2*sqy - 2*sqz);
		pitch = asin(2*test);
		roll = atan2(2*q.x*q.w-2*q.y*q.z , 1 - 2*sqx - 2*sqz);
	}

	return VectorT!(3,T)(yaw, pitch, roll);
}

// Make sure axisAngle is working
unittest{
	import math.conversion;
	float aaDif(vec3 axis, float angle) {
		axis = math.geo.vector.normalize(axis);
		angle = toRad(angle);
		auto q = quatern(axis, angle);
		auto aa = axisAngle(q);
		auto q2 = quatern(aa.xyz, aa.w);
		auto d = math.geo.vector.length(vec4(q.quat) - vec4(q2.quat));
		return d;
	}

	assert(aaDif(vec3(1,1,1), 20) < 0.00001);
	assert(aaDif(vec3(1,1,0), 40) < 0.00001);
	assert(aaDif(vec3(9,8,-3), 900) < 0.00001);
}


