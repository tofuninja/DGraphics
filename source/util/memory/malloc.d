module util.memory.malloc;

import std.c.stdlib : free, malloc;

auto mallocT(T, ARGS...)(auto ref ARGS args)
{
	import std.conv;
	auto mem = malloc(T.sizeof);
	auto arr = mem[0 .. T.sizeof];
	return emplace!(T)(arr, args);
}

void freeT(T)(T* t)
{
	t.destroy();
	free(t);
}

void freeT(T)(T[] t)
{
	t.destroy();
	free(t.ptr);
}

auto mallocTA(T)(size_t count)
{
	import std.conv;
	auto mem = malloc(T.sizeof*count);
	auto arr = (cast(T*)mem)[0 .. count];
	foreach(ref i; arr) i = T.init;
	return arr;
}