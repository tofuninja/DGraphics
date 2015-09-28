module main;
 
import graphics.hw;
import math.matrix;
import math.geo.rectangle;
import editor.ui;


/* 	MAIN  */
void main(string[] args)
{
	// Init game
	{
		gameInitInfo info;
		info.fullscreen = false;
		info.size = ivec2(1000,800);
		Game.init(info);
	}
	
	startEditor();
}


