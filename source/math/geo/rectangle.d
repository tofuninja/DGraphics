﻿module math.geo.rectangle;

import math.matrix;

alias Rectangle = RectangleT!float;
alias fRectangle = RectangleT!float;
alias dRectangle = RectangleT!double;
alias iRectangle = RectangleT!int;
alias uRectangle = RectangleT!uint;

struct RectangleT(T = float)
{
	alias tvec2 = matrix!(2,1, T);

	public this(T x, T y, T w, T h)
	{
		loc = tvec2(x,y);
		size = tvec2(w,h);
		if(size.x < 0) size.x = 0;
		if(size.y < 0) size.y = 0;
	}

	public this(tvec2 LOC, tvec2 SIZE)
	{
		loc = LOC;
		size = SIZE;
		if(size.x < 0) size.x = 0;
		if(size.y < 0) size.y = 0;
	}

	tvec2 loc;
	tvec2 size;
}

bool contains(T)(RectangleT!T rect, matrix!(2,1,T) point)
{
	return 
		point.x >= rect.loc.x && 
		point.y >= rect.loc.y &&
		point.x <= rect.loc.x + rect.size.x &&
		point.y <= rect.loc.y + rect.size.y;
}



auto topLeft(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l = target.loc - child.loc;
	return l;
}

auto centerLeft(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l;
	l.y = target.loc.y + (target.size.y - child.size.y)/2.0f - child.loc.y;
	l.x = target.loc.x - child.loc.x;
	return l;
}

auto bottomLeft(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l;
	l.x = target.loc.x - child.loc.x;
	l.y = target.loc.y + target.size.y - child.size.y - child.loc.y;
	return l;
}

auto topCenter(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l;
	l.x = target.loc.x + (target.size.x - child.size.x)/2.0f - child.loc.x;
	l.y = target.loc.y - child.loc.y;
	return l;
}

auto center(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l = target.loc + (target.size - child.size)/2.0f - child.loc;
	return l;
}

auto bottomCenter(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l;
	l.x = target.loc.x + (target.size.x - child.size.x)/2.0f - child.loc.x;
	l.y = target.loc.y + target.size.y - child.size.y - child.loc.y;
	return l;
}

auto topRight(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l;
	l.x = target.loc.x + target.size.x - child.size.x - child.loc.x;
	l.y = target.loc.y - child.loc.y;
	return l;
}

auto centerRight(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l;
	l.x = target.loc.x + target.size.x - child.size.x - child.loc.x;
	l.y = target.loc.y + (target.size.y - child.size.y)/2.0f - child.loc.y;
	return l;
}

auto bottomRight(T)(RectangleT!T target, RectangleT!T child)
{
	matrix!(2,1,T) l = target.loc + target.size - child.size - child.loc;
	return l;
}

auto alignIn(T)(RectangleT!T target, RectangleT!T child, string alignment)
{
	matrix!(2,1,T) p; 
	switch(alignment)
	{
		case "top-left": 		p = target.topLeft(child); 		break;
		case "center-left": 	p = target.centerLeft(child); 	break;
		case "bottom-left": 	p = target.bottomLeft(child); 	break;
		case "top-center": 		p = target.topCenter(child); 	break;
		case "center-center": 
		case "center": 			p = target.center(child); 		break;
		case "bottom-center": 	p = target.bottomCenter(child); 	break;
		case "top-right": 		p = target.topRight(child); 		break;
		case "center-right": 	p = target.centerRight(child); 	break;
		case "bottom-right": 	p = target.bottomRight(child); 	break;
		default: 				p = target.topLeft(child); 		break;
	}

	return p;
}

auto clip(T)(RectangleT!T clip, RectangleT!T child)
{
	import std.algorithm;

	auto x = clamp(child.loc.x, clip.loc.x, clip.loc.x + clip.size.x);
	auto y = clamp(child.loc.y, clip.loc.y, clip.loc.y + clip.size.y);
	auto w = clamp(child.loc.x + child.size.x, clip.loc.x, clip.loc.x + clip.size.x) - x;
	auto h = clamp(child.loc.y + child.size.y, clip.loc.y, clip.loc.y + clip.size.y) - y;
	return RectangleT!T(x,y,w,h);
}

void expandToFit(T)(ref RectangleT!T expandMe, RectangleT!T fit)
{
	import std.algorithm;

	auto x = min(expandMe.loc.x, fit.loc.x);
	auto y = min(expandMe.loc.y, fit.loc.y);
	auto w = max(expandMe.loc.x + expandMe.size.x, fit.loc.x + fit.size.x) - x;
	auto h = max(expandMe.loc.y + expandMe.size.y, fit.loc.y + fit.size.y) - y;
	expandMe = RectangleT!T(x,y,w,h); 
}

bool intersects(T)(RectangleT!T a, RectangleT!T b)
{
	import std.stdio;
	foreach(p; a.points) if(b.contains(p)) return true;
	foreach(p; b.points) if(a.contains(p)) return true;
	return false;
}

auto points(T)(RectangleT!T rec)
{
	import std.range.primitives;
	struct Result{
		private RectangleT!T r;
		private uint count;
		public bool empty;
		public matrix!(2,1,T) front;
		public void popFront() 	
		{ 
			count++;
			switch(count)
			{
				case 1:
					front = r.loc;
					front.x = front.x + r.size.x;
					break;
				case 2:
					front = r.loc + r.size;
					break;
				case 3:
					front = r.loc;
					front.y = front.y + r.size.y;
					break;
				default:
					empty = true;
			}
		} 
	}

	static assert(isInputRange!Result);
	return Result(rec, 0, false, rec.loc);
}