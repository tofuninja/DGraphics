module util.memory.shrinkSubArray;

import std.experimental.allocator;

bool shrinkSubArray(T, Allocator)(auto ref Allocator all, ref T[] array, size_t start, size_t end) {
	assert(start <= end);
	assert(start <  array.length);
	assert(end   <= array.length);
	if(start == end) return true;
	auto dif = end - start;
	for(size_t i = end; i < array.length; i++)
		array[i-dif] = array[i];
	return all.strinkArray(array, dif);
}