module math.conversion;

/**
 * Degrees to radins 
 */
float toRad(T)(T d) {
	import std.math;
	return cast(T)((d*PI)/180.0L);
}

/**
 * Radins to degrees
 */
float toDeg(T)(T r) {
	import std.math;
	return cast(T)((r*180.0L)/PI);
}

// not really a math function but def a conversion function
/**
 * Convert a local to a slice of size 1
 */
auto toSlice(T)(ref T x) {
	return (&x)[0..1];
}

auto lerp(float a, float b, float p) {
	return a + (b-a)*p;
}