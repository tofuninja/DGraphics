module graphics.image;
import graphics.color;
import math.matrix;
import graphics.hw;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.experimental.allocator.gc_allocator;
import derelict.freeimage.freeimage;

version(Windows) {
	private enum fi_dll 	= "Freeimage.dll";
} else version(linux) {
	static assert(false); // TODO Not testsed
	private enum fi_dll 	= "libfreeimage.so";
} else {
	static assert(false);
}

version(X86_64) {
	private enum lib_folder = "./libs/libs64/";
} else {
	private enum lib_folder = "./libs/";
}

private string freeImgError = "";
private bool lib_inited = false;
private void initFreeimage() {
	DerelictFI.load([lib_folder ~ fi_dll]);
	FreeImage_SetOutputMessage(&freeImgErrorHandler);
}

string getImageLoaderVersionString() {
	import std.conv:to;
	if(lib_inited == false) initFreeimage();
	auto fiv = FreeImage_GetVersion();
	int z;
	for(z = 0; fiv[z] != 0; z++) {}
	return "FreeImage Version: " ~ fiv[0 .. z].to!string;
}

class Image
{
	protected int m_width = 0;
	protected int m_height = 0;
	protected Color[] m_data;

	this(Image img) {
		m_width = img.m_width;
		m_height = img.m_height;
		m_data = Mallocator.instance.makeArray!Color(img.m_data.length);
		m_data[] = img.m_data[];
	}

	this(int width, int height) {
		m_width = width;
		m_height = height;
		m_data = Mallocator.instance.makeArray!Color(width*height);// new Color[width*height];
	}

	~this() {
		Mallocator.instance.dispose(m_data);
	}

	@property int Width() { return m_width; }
	@property int Height() { return m_height; }
	@property Color[] Data() { return m_data; }

	Color opIndex(int x, int y) {
		if(x<0 || y<0 || x>=m_width || y>=m_height) {
			return  Color(0); // Silently fail... 
		}
		return getPixel(x,y);
	}

	void opIndexAssign(Color c, int x, int y) {
		if(x<0 || y<0 || x>=m_width || y>=m_height) {
			return; // Silently fail... 
		}
		setPixel(x, y, c);
	}

	Color opIndex(ivec2 index) {
		return opIndex(index.x,index.y);
	}

	void opIndexAssign(Color c, ivec2 index) {
		opIndexAssign(c, index.x, index.y);
	}

	Color opIndex(vec2 index) {
		return opIndex(cast(int)index.x,cast(int)index.y);
	}
	
	void opIndexAssign(Color c, vec2 index) {
		opIndexAssign(c, cast(int)index.x, cast(int)index.y);
	}

	public Color getPixel(int x, int y) {
		return m_data[x + y*m_width];
	}

	public void setPixel(int x, int y, Color c) {
		m_data[x + y*m_width] = c;
	}

	public Image dup() {
		return new Image(this);
	}
}

/** 
 * Save Image to file
 * 
 * Quality is only used if saving to jpeg, value from 0 to 100
 */
void saveImage(T)(Image i, T path, int quality = 100) if(is(T == string) || is(T == wstring) || is(T == dstring)) {
	import std.conv;
	if(lib_inited == false) initFreeimage();

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
	for(int x = 0; x < width; x++) {
		for(int y = 0; y < height; y++) {
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
	if(fileFormat == FIF_JPEG) {
		FIBITMAP* temp = FreeImage_ConvertTo24Bits(img);
		FreeImage_Unload(img);
		img = temp;
		if(img is null) throw new Exception("Image failed to convert");
		flags = quality;
	}

	// Save image
	bool saved = (FreeImage_SaveU(fileFormat, img, wpath.ptr, flags) != 0);
	FreeImage_Unload(img);
	if(!saved) throw new Exception("Failed to save image(" ~ path ~ "):" ~ freeImgError);
}

/**
 * Load image from file
 */
Image loadImage(T)(T path) if(is(T == string) || is(T == wstring) || is(T == dstring)) {
	return loadImage(path, GCAllocator.instance);
}

Image loadImage(T, Alloc)(T path, Alloc alloc) if(is(T == string) || is(T == wstring) || is(T == dstring)) {
	if(lib_inited == false) initFreeimage();
	// Convert the string to a type we can work with
	auto malloc = Mallocator.instance;
	version(Windows) alias pchar = wchar;
	else alias pchar = dchar;
	pchar[] p = malloc.makeArray!pchar(path.length + 1);
	scope(exit) malloc.dispose(p);
	foreach(i,v; path) p[i] = v;
	p[$-1] = 0;
	

	// Get image file type
	FREE_IMAGE_FORMAT fileFormat = FreeImage_GetFileTypeU(p.ptr, 0);
	if(fileFormat == FIF_UNKNOWN)
		fileFormat = FreeImage_GetFIFFromFilenameU(p.ptr);
	if(fileFormat == FIF_UNKNOWN) throw new Exception("Unknown file type");

	// Load image
	int flags = 0;
	if(fileFormat == FIF_JPEG) flags = JPEG_ACCURATE;
	FIBITMAP* img = FreeImage_LoadU(fileFormat, p.ptr, flags);
	if(img is null) throw new Exception("Image " ~ path ~ " failed to load");

	return finishImgLoad(img, alloc);
}

/**
 * Load image from ubyte[], name is used to aid free image from guessing the file type
 */
Image loadImageMem(T = string)(ubyte[] data, T name = "") if(is(T == string) || is(T == wstring) || is(T == dstring)) {
	if(lib_inited == false) initFreeimage();
	auto mem = FreeImage_OpenMemory(cast(ubyte*)data.ptr, data.length);
	if(mem == null) throw new Exception("Failed to read memory");
	scope(exit) FreeImage_CloseMemory(mem);

	// Get image file type
	FREE_IMAGE_FORMAT fileFormat = FreeImage_GetFileTypeFromMemory(mem, 0);
	if(fileFormat == FIF_UNKNOWN && name.length != 0) {
		
		// Convert the string to a type we can work with
		auto malloc = Mallocator.instance;
		version(Windows) alias pchar = wchar;
		else alias pchar = dchar;
		pchar[] p = malloc.makeArray!pchar(name.length + 1);
		scope(exit) malloc.dispose(p);
		foreach(i,v; name) p[i] = v;
		p[$-1] = 0;

		fileFormat = FreeImage_GetFIFFromFilenameU(p.ptr);
	}
	if(fileFormat == FIF_UNKNOWN) throw new Exception("Unknown file type");

	// Load image
	int flags = 0;
	if(fileFormat == FIF_JPEG) flags = JPEG_ACCURATE;
	FIBITMAP* img = FreeImage_LoadFromMemory(fileFormat, mem, flags);
	if(img is null) throw new Exception("Image " ~ name ~ " failed to load");

	return finishImgLoad(img, GCAllocator.instance);
}

private Image finishImgLoad(Alloc)(FIBITMAP* img, Alloc alloc) {
	// Convert if needed
	FREE_IMAGE_TYPE imgType = FreeImage_GetImageType(img);
	if(imgType != FIT_BITMAP) {
		FIBITMAP* temp = FreeImage_ConvertToStandardType(img, false);
		FreeImage_Unload(img);
		img = temp;
		if(img is null) throw new Exception("Image failed to convert");
	}

	uint bpp = FreeImage_GetBPP(img);
	if(bpp != 32) {
		FIBITMAP* temp = FreeImage_ConvertTo32Bits(img);
		FreeImage_Unload(img);
		img = temp;
		if(img is null) throw new Exception("Image failed to convert");
	}

	// Get image data
	uint width = FreeImage_GetWidth(img);
	uint height = FreeImage_GetHeight(img);
	Image rtn = alloc.make!Image(width,height);

	for(int x = 0; x < width; x++) {
		for(int y = 0; y < height; y++) {
			RGBQUAD color;
			if(FreeImage_GetPixelColor(img, x, height-y-1, &color)) {
				rtn[x,y] = Color(color.rgbRed, color.rgbGreen, color.rgbBlue, color.rgbReserved);
			} else {
				rtn[x,y] = Color(0,0,0,0);
			}
		}
	}

	// Unload Image
	FreeImage_Unload(img);

	return rtn;
}


private extern(C) void freeImgErrorHandler(FREE_IMAGE_FORMAT fif, const(char)* msg) nothrow
{
	import std.conv;
	try
	{
		int z;
		for(z = 0; msg[z] != 0; z++) {}
		freeImgError = msg[0 .. z].to!string;
	}
	catch(Exception) {}
}

void clear(Image img, Color c) {
	import std.stdio;
	for(int i = 0; i < img.Width; i++) {
		for(int j = 0; j < img.Height; j++) {
			img[i, j] = c;
		}
	}
}

bool loadImageDialog(ref Image img) {
	version(Windows) {
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
	} else {
		static assert(false, "Only supported on windows");
	}
}

bool saveImageDialog(Image img) {
	version(Windows) {
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
	} else {
		static assert(false, "Only supported on windows");
	}
}

/**
 * Create a texture an fill it with the image data
 * After creation, the texture and the image are in 
 * no way associated.
 */
public hwTextureRef!(hwTextureType.tex2D) generateTexture(Image i) {
	import math.geo.rectangle;
	hwTextureCreateInfo!(hwTextureType.tex2D) info;
	info.size = uvec3(i.Width, i.Height, 1);
	auto tex = hwCreate(info);

	hwTextureSubDataInfo subinfo;
	subinfo.format = hwColorFormat.RGBA_n8;
	subinfo.size = uvec3(i.Width, i.Height, 0);
	subinfo.offset = uvec3(0,0,0);
	subinfo.level = 0;
	subinfo.data = i.Data;
	tex.subData(subinfo);
	return tex;
}