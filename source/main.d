module main;
 
import std.stdio;
import graphics.Color;
import graphics.Image;
import graphics.bmp;
import math.matrix;
import graphics.render;

void main(string[] args)
{

	Image i = Image(100,100);

	auto v1 = vec2(10,15);
	auto v2 = vec2(75,40);
	auto v3 = vec2(33,66);


	foreach(vec2i p; triangleRaster(v1,v2,v3))
	{
		i[p] = Color(255,0,0);
	}



	foreach(vec2i p; lineRaster(v1,v2))
	{
		i[p] = Color(0,0,255);
	}

	i[v1] = Color(0,255,0);
	i[v2] = Color(0,255,0);
	i[v3] = Color(0,255,0);

	i.saveAsBmp("test.bmp");


}