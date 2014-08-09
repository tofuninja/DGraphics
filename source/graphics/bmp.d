module graphics.bmp;

import graphics.Image;
import std.stdio;

/**
 * Save an image as a bitmap, 
 * currently only supports saving in 32bit color format using 
 * the BITMAPINFOHEADER header format. 
 */
/*
public void saveAsBmp(Image img, string file)
{
	File f = File(file,"w");
	scope(exit) f.close();

	// Header
	uint file_size = 14 + 40 + (img.Width*img.Height*4);
	uint reserved = 0;
	uint offset = 14 + 40; 

	// BITMAPINFOHEADER 
	uint header_size = 40;
	int width = img.Width;
	int height = -img.Height;
	ushort planes = 1; 
	ushort bitsPerPixel = 32;
	uint compression = 0; // no compression
	uint image_size = (img.Width*img.Height*4);
	int pixelsPerMeter_H = 2835;
	int pixelsPerMeter_V = 2835;
	uint palette_size = 0;
	uint important_colors = 0;

	f.write("BM");
	f.rawWrite([file_size,reserved,offset,header_size]);
	f.rawWrite([width,height]);
	f.rawWrite([planes,bitsPerPixel]);
	f.rawWrite([compression,image_size]);
	f.rawWrite([pixelsPerMeter_H,pixelsPerMeter_V]);
	f.rawWrite([palette_size,important_colors]);
	f.rawWrite(img.m_data);
	f.flush();
}
*/