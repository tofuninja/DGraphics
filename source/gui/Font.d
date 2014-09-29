module gui.Font;

import graphics.Image;
import graphics.Color;
import math.matrix;

private Image fontImg;

public void initFont()
{
	fontImg = loadImage("CGA8x8thin.png");
}

public void drawText(Image img, string text, vec2 loc, Color color)
{
	int line = 0;
	int charOnLine = 0;
	for(int i = 0; i < text.length; i++)
	{
		char c = text[i];
		if(c == '\n')
		{
			line++;
			charOnLine = 0;
		}
		else
		{
			int row = c % 16;
			int col = c / 16;
			for(int x = 0; x < 8; x++)
			{
				for(int y = 0; y < 8; y++)
				{
					Color fontCol = fontImg[row*8 + x, (col*8 + y)];
					if(fontCol.G != 0)
						img[vec2(x + charOnLine*8,y + line*10) + loc] = alphaBlend(color, img[vec2(x + i*8,y) + loc]);
				}
			}

			charOnLine++;
		}

	}
}

public vec2 renderSize(string text)
{
	import std.algorithm;
	int line = 0;
	int charOnLine = 0;
	int maxCharOnLine = 0;
	for(int i = 0; i < text.length; i++)
	{
		char c = text[i];
		if(c == '\n')
		{
			line++;
			charOnLine = 0;
		}
		else
		{
			int row = c % 16;
			int col = c / 16;
			charOnLine++;
		}
		maxCharOnLine = max(maxCharOnLine, charOnLine);
	}

	return vec2(maxCharOnLine*8,(line + 1)*8);
}