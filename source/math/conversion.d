module math.conversion;

/**
 * Degrees to radins 
 */
float toRad(float d)
{
	import std.math;
	return (d*PI)/180.0f;
}

// not really a math function but def a conversion function
/**
 * Convert a local to a slice of size 1
 */
auto toSlice(T)(ref T x)
{
	return (&x)[0..1];
}

auto lerp(float a, float b, float p)
{
	return a + (b-a)*p;
}