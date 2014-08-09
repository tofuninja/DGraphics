module graphics.Image;
import graphics.Color;
import math.matrix;


struct Image
{
	private int m_width;
	private int m_height;
	private Color[] m_data;

	this(int width, int height)
	{
		m_width = width;
		m_height = height;
		m_data = new Color[width*height];
	}

	@property int Width()  { return m_width; }
	@property int Height()  { return m_height; }
	@property Color[] Data()  { return m_data; }

	Color opIndex(int x, int y)
	{
		if(x<0 || y<0 || x>=m_width || y>=m_height) return Color(0); // Silently fail... 
		return m_data[x + y*m_width];
	}

	Color opIndexAssign(Color c, int x, int y)
	{
		if(x>=0 && y>=0 && x<m_width && y<m_height) m_data[x + y*m_width] = c; // Silently fail... 
		return c;
	}

	Color opIndex(vec2i index)
	{
		return opIndex(index.x,index.y);
	}
	
	Color opIndexAssign(Color c, vec2i index)
	{
		return opIndexAssign(c, index.x, index.y);
	}


	Color opIndex(vec2 index)
	{
		return opIndex(cast(int)index.x,cast(int)index.y);
	}
	
	Color opIndexAssign(Color c, vec2 index)
	{
		return opIndexAssign(c, cast(int)index.x, cast(int)index.y);
	}
}

/** 
 * Save Image to file
 * 
 * Quality is only used if saving to jpeg, value from 0 to 100
 */
void saveImage(T)(Image i, T path, int quality = 100) if(is(T == string) || is(T == wstring) || is(T == dstring))
{
	import derelict.freeimage.freeimage;
	import std.conv;

	wstring wpath = wtext(path~'\0');


	// Get image file type
	FREE_IMAGE_FORMAT fileFormat = FreeImage_GetFIFFromFilenameU(wpath.ptr);
	if(fileFormat == FIF_UNKNOWN) throw new Exception("Unknown file type");

	// Allocate Image
	uint bpp = 32;
	int width = i.Width;
	int height = i.Height;
	FIBITMAP* img = FreeImage_Allocate(width, height, bpp, 0, 0, 0); 
	if(img is null) throw new Exception("Image failed allocate");

	// Fill in image data
	for(int x = 0; x < width; x++)
	{
		for(int y = 0; y < height; y++)
		{
			Color col = i[x, height-y-1];

			RGBQUAD color;
			color.rgbRed 		= *(cast(byte*)(&col.Red)); 
			color.rgbGreen 		= *(cast(byte*)(&col.Green)); 
			color.rgbBlue 		= *(cast(byte*)(&col.Blue)); 
			color.rgbReserved 	= *(cast(byte*)(&col.Alpha)); 
			FreeImage_SetPixelColor(img, x, y, &color);
		}
	}


	int flags = 0;

	//  Do jpeg specific stuff
	if(fileFormat == FIF_JPEG)
	{
		FIBITMAP* temp = FreeImage_ConvertTo24Bits(img);
		FreeImage_Unload(img);
		img = temp;
		if(img is null) throw new Exception("Image failed to convert");
		flags = quality;
	}

	// Save image
	bool saved = (FreeImage_SaveU(fileFormat, img, wpath.ptr, flags) != 0);
	FreeImage_Unload(img);
	if(!saved) throw new Exception("Failed to save image");
}

/**
 * Load image from file
 */
Image loadImage(T)(T path) if(is(T == string) || is(T == wstring) || is(T == dstring))
{
	import derelict.freeimage.freeimage;
	import std.string;
	import std.conv;

	wstring wpath = wtext(path~'\0');


	// Get image file type
	FREE_IMAGE_FORMAT fileFormat = FreeImage_GetFileTypeU(wpath.ptr, 0);
	if(fileFormat == FIF_UNKNOWN)
		fileFormat = FreeImage_GetFIFFromFilenameU(wpath.ptr);
	if(fileFormat == FIF_UNKNOWN) throw new Exception("Unknown file type");

	// Load image
	int flags = 0;
	if(fileFormat == FIF_JPEG) flags = JPEG_ACCURATE;
	FIBITMAP* img = FreeImage_LoadU(fileFormat, wpath.ptr, flags);
	if(img is null) throw new Exception("Image failed to load");


	// Convert if needed
	FREE_IMAGE_TYPE imgType = FreeImage_GetImageType(img);
	if(imgType != FIT_BITMAP)
	{
		FIBITMAP* temp = FreeImage_ConvertToStandardType(img, false);
		FreeImage_Unload(img);
		img = temp;
		if(img is null) throw new Exception("Image failed to convert");
	}

	uint bpp = FreeImage_GetBPP(img);
	if(bpp != 32)
	{
		FIBITMAP* temp = FreeImage_ConvertTo32Bits(img);
		FreeImage_Unload(img);
		img = temp;
		if(img is null) throw new Exception("Image failed to convert");
	}

	// Get image data
	uint width = FreeImage_GetWidth(img);
	uint height = FreeImage_GetHeight(img);
	Image rtn = Image(width,height);

	for(int x = 0; x < width; x++)
	{
		for(int y = 0; y < height; y++)
		{
			RGBQUAD color;
			if(FreeImage_GetPixelColor(img, x, height-y-1, &color))
			{
				rtn[x,y] = Color(color.rgbRed, color.rgbGreen, color.rgbBlue, color.rgbReserved);
			}
			else
			{
				rtn[x,y] = Color(0,0,0,0);
			}
		}
	}

	// Unload Image
	FreeImage_Unload(img);

	return rtn;
}