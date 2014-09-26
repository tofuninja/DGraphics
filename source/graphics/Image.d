module graphics.Image;
import graphics.Color;
import math.matrix;


struct Image
{
	private int m_width = 0;
	private int m_height = 0;
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

	ref Color opIndex(int x, int y)
	{
		static Color failRtn = Color(0);
		if(x<0 || y<0 || x>=m_width || y>=m_height) 
		{
			failRtn = Color(0);
			return failRtn; // Silently fail... 
		}
		return m_data[x + y*m_width];
	}

	ref opIndex(ivec2 index)
	{
		return opIndex(index.x,index.y);
	}

	ref Color opIndex(vec2 index)
	{
		return opIndex(cast(int)index.x,cast(int)index.y);
	}

	public Image dup()
	{
		Image rtn;
		rtn.m_width = m_width;
		rtn.m_height = m_height;
		rtn.m_data = m_data.dup;
		return rtn;
	}

	public ref Color pixel(int x, int y)
	{
		return m_data[x + y*m_width];
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

void clear(Image img, Color c)
{
	import std.stdio;
	for(int i = 0; i < img.Width; i++)
	{
		for(int j = 0; j < img.Height; j++)
		{
			img[i, j] = c;
		}
	}
}

Image convolve(int n)(Image img, matrix!(n,n, float) kernal)
{
	static assert(n % 2 == 1, "Kernal Matrix must be square and have an odd size");
	
	Image cpy = Image(img.Width, img.Height);

	for(int i = n/2; i < img.Width - n/2; i++)
	{
		for(int j = n/2; j < img.Height - n/2; j++)
		{
			
			vec4 sum = vec4(0,0,0,0);
			
			for(int k = 0; k < n; k++)
			{
				for(int l = 0; l < n; l++)
				{
					Color c = img[i + k - n/2, j + l - n/2];
					sum = sum + c.to!vec4 * kernal[k,l];
				}
			}
			cpy[i,j] = sum.to!Color;
			cpy[i,j].A = 255;
		}
	}
	return cpy;
}


bool loadImageDialog(ref Image img)
{
	import core.sys.windows.windows;
	import std.string;

	int rtn;
	OPENFILENAMEA file;
	
	file.lStructSize = OPENFILENAMEA.sizeof;
	file.hwndOwner = null;
	file.lpstrFilter = "Image\0*.tif;*.tiff;*.jpg;*.jpeg;*.png\0\0".toStringz;
	file.lpstrCustomFilter = null;
	file.nFilterIndex = 1;
	char[1000] buffer;
	buffer[0] = 0;
	file.lpstrFile = buffer.ptr;
	file.nMaxFile = 1000;
	file.nMaxFileTitle = 0;
	file.lpstrInitialDir = null;
	file.lpstrTitle = null;
	file.Flags = 0;
	
	rtn = GetOpenFileNameA(&file);
	if(rtn == 0) return false;
	
	int z;
	for(z = 0; buffer[z] != 0 && z < 1000; z++) {}
	string filename = buffer[0 .. z].idup;
	img = loadImage(filename);
	return true;
}

bool saveImageDialog(Image img)
{
	import core.sys.windows.windows;
	import std.string;

	int rtn;
	OPENFILENAMEA file;
	
	file.lStructSize = OPENFILENAMEA.sizeof;
	file.hwndOwner = null;
	file.lpstrFilter = "Image\0*.tif;*.tiff;*.jpg;*.jpeg;*.png\0\0".toStringz;
	file.lpstrCustomFilter = null;
	file.nFilterIndex = 1;
	char[1000] buffer;
	buffer[0] = 0;
	file.lpstrFile = buffer.ptr;
	file.nMaxFile = 1000;
	file.nMaxFileTitle = 0;
	file.lpstrInitialDir = null;
	file.lpstrTitle = null;
	file.Flags = 0;
	
	rtn = GetSaveFileNameA(&file);
	if(rtn == 0) return false;
	
	int z;
	for(z = 0; buffer[z] != 0 && z < 1000; z++) {}
	string filename = buffer[0 .. z].idup;
	saveImage(img, filename);
	return true;
}

void drawImage(Image dest, Image src, vec2 loc)
{
	for(int i = 0; i < src.Width; i++)
	{
		for(int j = 0; j < src.Height; j++)
		{
			dest[cast(int)loc.x + i, cast(int)loc.y + j] = alphaBlend(src[i,j],dest[cast(int)loc.x + i, cast(int)loc.y + j]);
		}
	}
}