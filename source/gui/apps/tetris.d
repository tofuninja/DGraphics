module gui.apps.tetris;

import std.stdio;
import std.container;
import graphics.Image;
import graphics.render;
import graphics.Color;
import graphics.hw.state;
import math.matrix;
import gui.Panel;

class Tetris : Panel
{
	enum boardW = 15;
	enum boardH = 25;
	enum boarder = 10;
	import std.random;
	enum bs = vec2(10,10);
	enum boardStart = vec2(boarder,boarder);
	Image blocks;
	tetrisPiece active;
	int time;

	int score = 0;
	
	public this(vec2 loc, Panel owner)
	{
		super(loc,bs * vec2(boardW,boardH) + vec2(boarder*2 + 100, boarder*2), owner);
		blocks = new Image(boardW, boardH);
		blocks.clear(Color(0,0,0,42));
		active = tetrisPiece(uniform(0,7));
		active.loc = ivec2(boardW/2 - 1,0);
		updateRender();
	}
	
	public this(vec2 loc)
	{
		this(loc, basePan);
	}
	
	private void leftClick()
	{
		moveActive(ivec2(-1,0));
	}
	
	private void rightClick()
	{
		moveActive(ivec2(1,0));
	}
	
	private void downClick()
	{
		while(moveActive(ivec2(0,1))){}
		
		foreach(ivec2 v; placePiece(active))
		{
			blocks[v] = active.c;
		}
		active = tetrisPiece(uniform(0,7));
		active.loc = ivec2(4,0);
		
		checkLines();
		updateRender();
	}
	
	private void rotClick()
	{
		moveActive(ivec2(0,0), 1);
	}

	override public void keyPress( int key, int scanCode, int action, int mods) 
	{
		import derelict.glfw3.glfw3;
		if(action == GLFW_PRESS || action == GLFW_REPEAT)
		{
			if(key == GLFW_KEY_A) leftClick();
			if(key == GLFW_KEY_D) rightClick();
			if(key == GLFW_KEY_SPACE) downClick();
			if(key == GLFW_KEY_S || key == GLFW_KEY_W) rotClick();
		}
	}

	override public void tick() 
	{
		time ++;
		if(time % 100 == 0)
		{
			bool b = moveActive(ivec2(0,1));
			if(!b)
			{
				foreach(ivec2 v; placePiece(active))
				{
					blocks[v] = active.c;
				}
				active = tetrisPiece(uniform(0,7));
				active.loc = ivec2(4,0);
				
				checkLines();
			}
			updateRender();
		}
		
		
	}
	
	private void updateRender()
	{
		import gui.Font;
		import std.conv;
		img.drawBoxFill(vec2(0,0),size, Color(100,100,100));
		
		for(int i = 0; i < blocks.Width; i++)
		{
			for(int j = 0; j < blocks.Height; j ++)
			{
				img.drawBoxFill(vec2(bs.x*i,bs.y*j) + boardStart,bs,blocks[i,j]);
			}
		}
		
		renderActive(img);

		img.drawText("Score\n" ~ score.to!string, vec2(bs.x*boardW + boarder * 2,10),Color(0,0,0));
		img.drawBox(boardStart, vec2(bs.x*blocks.Width,bs.y*blocks.Height), Color(0,0,0));
		img.drawBox(vec2(0,0),size, Color(0,0,0));
	}
	
	private void renderActive(Image img)
	{
		foreach(ivec2 v; placePiece(active))
		{
			img.drawBoxFill(vec2(v.x*bs.x, v.y*bs.y) + boardStart,bs,active.c);
		}
	}
	
	private ivec2[4] placePiece(tetrisPiece p)
	{
		import std.algorithm;
		ivec2[4] rtn;
		int rotate = p.rotation;
		
		for(int i = 0; i < 4; i++)
		{
			rtn[i] = p.parts[i];
			if(rotate == 1)
			{
				swap(rtn[i][0], rtn[i][1]);
				rtn[i].y = -rtn[i].y;
			}
			else if(rotate == 2)
			{
				rtn[i].x = -rtn[i].x;
				rtn[i].y = -rtn[i].y;
			}
			else if(rotate == 3)
			{
				swap(rtn[i][0], rtn[i][1]);
				rtn[i].x = -rtn[i].x;
			}
			rtn[i] = rtn[i] + p.loc;
		}
		return rtn;
	}
	
	private bool moveActive(ivec2 translation, int rotate = 0)
	{
		tetrisPiece n = active;
		n.loc = n.loc + translation;
		n.rotation += rotate;
		n.rotation %= 4;
		foreach(ivec2 v; placePiece(n))
		{
			if(blocks[v] != Color(0,0,0,42)) return false;
		}
		active = n;
		updateRender();
		return true;
	}
	
	private void checkLines()
	{
		int lines = 0;
		for(int i = 0; i < 22; i++)
		{
			int blocksOnLine = 0;
			for(int j = 0; j < 10; j++)
			{
				if(blocks[j,i] != Color(0,0,0,42)) blocksOnLine ++;
			}
			if(blocksOnLine == 10)
			{
				lines++;
				for(int j = i-1; j >= 0; j--)
				{
					for(int k = 0; k < 10; k++)
					{
						blocks[k,j + 1] = blocks[k,j];
					}
				}
				i--;
			}
		}
		
		if(lines > 0) score += 4 * 10^^lines;
		
		for(int i = 0; i < 2; i++)
		{
			int blocksOnLine = 0;
			for(int j = 0; j < 10; j++)
			{
				if(blocks[j,i] != Color(0,0,0,42)) blocksOnLine ++;
			}
			if(blocksOnLine > 0)
			{
				score = 0;
				blocks.clear(Color(0,0,0,42));
				return;
			}
		}
		
	}
	
	private struct tetrisPiece
	{
		ivec2[4] parts;
		ivec2 loc;
		int rotation = 1;
		Color c;
		
		this(int type)
		{
			switch(type)
			{
				case 1:// Line
				{
					parts = [ivec2(0,-1),ivec2(0,0),ivec2(0,1),ivec2(0,2)];
					c = Color(255,180,0); // orange
					break;
				}
				case 2:// left L
				{
					parts = [ivec2(-1,0),ivec2(0,0),ivec2(0,1),ivec2(0,2)];
					c = Color(255,255,0); // yellow
					break;
				}
				case 3:// Right L
				{
					parts = [ivec2(0,0),ivec2(-1,0),ivec2(-1,1),ivec2(-1,2)];
					c = Color(255,0,255); // purple
					break;
				}
				case 4:// left Bend
				{
					parts = [ivec2(-1,0),ivec2(-1,1),ivec2(0,1),ivec2(0,2)];
					c = Color(0,255,255); // teal
					break;
				}
				case 5:// Right Bend
				{
					parts = [ivec2(0,0),ivec2(0,1),ivec2(-1,1),ivec2(-1,2)];
					c = Color(0,255,0); // green
					break;
				}
				case 6:// T
				{
					parts = [ivec2(-1,0),ivec2(-1,1),ivec2(-1,2),ivec2(0,1)];
					c = Color(0,0,255); // blue
					break;
				}
				default:// Block
				{
					parts = [ivec2(-1,0),ivec2(0,0),ivec2(0,1),ivec2(-1,1)];
					c = Color(255,0,0); // red
					break;
				}
			}
		}
	}
}