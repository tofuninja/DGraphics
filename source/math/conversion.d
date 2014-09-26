module math.conversion;

/**
 * Degrees to radins 
 */
float toRad(float d)
{
	import std.math;
	return (d*PI)/180.0f;
}