module graphics.font;

import derelict.freetype.ft;
import math.matrix;
import math.geo.rectangle;
import graphics.hw;

// TODO ability to mix fonts in 1 font object(use the extra fonts as back ups for glyphs the main font does not have)


version(Windows) {
	private enum ft_dll 	= "freetype.dll";
} else version(linux) {
	static assert(false); // TODO Not testsed
	private enum ft_dll 	= "libfreetype.so";
} else {
	static assert(false);
}

version(X86_64) {
	private enum lib_folder = "./libs/libs64/";
} else {
	private enum lib_folder = "./libs/";
}

private FT_Library ftlibrary;
private bool lib_loaded = false;

private void initFreetype() {
	DerelictFT.load([lib_folder ~ ft_dll]);
	auto error = FT_Init_FreeType(&ftlibrary);
	if ( error ) {
		import std.conv:to;
		throw new Exception("Freetype faild to init: " ~ error.to!string);
	}
}

string getFontLoaderVersionString() {
	import std.conv:to;
	int maj, min, pat;
	if(lib_loaded == false) initFreetype();
	FT_Library_Version(ftlibrary, &maj, &min, &pat);
	return "FreeType Version: " ~ maj.to!string ~ "." ~ min.to!string ~ "." ~ pat.to!string;
}

class Font
{
	public Glyph[dchar] glyphs;
	public hwTextureRef!(hwTextureType.tex2D) texture; 
	public int lineHeight = 0;
	public int ascent = 0;
	public int descent = 0;

	public this(float size, string[] files...) {
		if(lib_loaded == false) initFreetype();
		loadFont(files, size);
	}

	public ~this() {
		hwDestroy(texture);
	}

	private void loadFont(string[] all_files, float size) {
		import std.string;
		import std.stdio;
		import std.conv;
		import math.geo.binpacker2d;
		import std.algorithm;
		import std.experimental.allocator;
		import std.experimental.allocator.mallocator;
		alias alloc = Mallocator.instance;

		FT_Face[] all_faces = alloc.makeArray!FT_Face(all_files.length);
		scope(exit) alloc.dispose(all_faces);

		foreach(font_index,file; all_files) {
			FT_Face face;
			auto error = FT_New_Face(ftlibrary, file.toStringz(), 0, &face);
			all_faces[font_index] = face;
			
			if(error == FT_Err_Unknown_File_Format) throw new Exception("Invalid file format, it is not a font");
			else if(error) 							throw new Exception("Unable to load font file: " ~ error.to!string);

			error = FT_Set_Char_Size(
				face,    				/* handle to face object           */
				0,      			 	/* char_width in 1/64th of points  */
				cast(int)(size*64),   	/* char_height in 1/64th of points */
				72,     				/* horizontal device resolution    */
				72 );   				/* vertical device resolution      */

			if(error) throw new Exception("Font size not valid: " ~ error.to!string);
			
			if(font_index == 0) {
				//auto bb_min = vec2(fontCordsToPixelX(face, cast(short)face.bbox.xMin), fontCordsToPixelY(face, cast(short)face.bbox.yMin));
				//auto bb_max = vec2(fontCordsToPixelX(face, cast(short)face.bbox.xMax), fontCordsToPixelY(face, cast(short)face.bbox.yMax));
				//auto bb_dif = bb_max - bb_min;
				//auto ma = fontCordsToPixelX(face, face.max_advance_width);
				lineHeight = cast(int)fontCordsToPixelY(face, face.height);
				ascent = cast(int)fontCordsToPixelY(face, face.ascender);
				descent = cast(int)fontCordsToPixelY(face, face.descender);
			}

			// Load all the glyphs and put them into the glyphs array
			foreach(g; allGlyphs(face)) {

				// Skip glyphs we already have
				if(g.c in glyphs) continue;

				auto slot = face.glyph;
				error = FT_Load_Glyph(face,  g.id, FT_LOAD_DEFAULT);
				if ( error ) continue;
				FT_Glyph  glyph; 
				error = FT_Get_Glyph(slot, &glyph);
				if ( error ) continue;

				FT_BBox  bbox;
				FT_Glyph_Get_CBox(glyph, FT_GLYPH_BBOX_PIXELS, &bbox);
				auto width  = bbox.xMax - bbox.xMin;
				auto height = bbox.yMax - bbox.yMin;

				import std.math;
				Glyph myglyph;
				myglyph.glyphChar = g.c;
				myglyph.id = g.id;
				myglyph.font_id = cast(uint)font_index;
				myglyph.extent.size = ivec2(width + 2, height + 2);
				myglyph.advance = ivec2(slot.advance.x >> 6, slot.advance.y >> 6);
				glyphs[g.c] = myglyph;

				FT_Done_Glyph(glyph);
			}

		}

		// Render all the glyphs to a texture
		{
			auto r = map!((ref a) => &(a.extent))(glyphs.byValue);
			auto l = glyphs.length;
			auto binSize = binPack2D(r, l);
			uint s = nextPowerOf2(max(binSize.x,binSize.y));
			auto dest = alloc.makeArray!ubyte(s*s);

			foreach(ref g; glyphs.byValue) {
				auto face = all_faces[g.font_id];
				auto slot = face.glyph;
				auto error = FT_Load_Glyph(face, g.id, FT_LOAD_RENDER);
				if ( error ) continue;

				auto penx = g.extent.loc.x;
				auto peny = g.extent.loc.y;
				
				auto p = slot.bitmap.buffer;
				for(int i = 0; i < slot.bitmap.rows; i++) {
					for(int j = 0; j < slot.bitmap.width; j++) {
						dest[(penx + j) + (peny + i)*s] = p[j];
					}
					p += slot.bitmap.pitch;
				}

				g.offset.x = slot.bitmap_left;
				g.offset.y = -slot.bitmap_top;
			}

			// Create a texture and fill it with the data
			{
				hwTextureCreateInfo!(hwTextureType.tex2D) info;
				info.format = hwColorFormat.R_n8;
				info.size = uvec3(s, s, 0);
				texture = hwCreate(info);
				
				hwTextureSubDataInfo sub;
				sub.size = uvec3(s, s, 0);
				sub.data = dest;
				sub.format = hwColorFormat.R_n8;
				texture.subData(sub);
			}

			/*
			{
				// Save the fontmap texture inot an image
				import graphics.color;
				import graphics.image;
				Image img = new Image(s, s);
				for(int i = 0; i < s; i++) {
					for(int j = 0; j < s; j++) {
						img[i,j] = Color(0, 0, 0, dest[i + j*s]);
					}
				}
				img.saveImage(all_files[0] ~ "_fonttexture.png");
			}
			*/

			/*
			// Save all supported chars into a text
			{
				import std.file;
				auto f = File(file ~ "_fonttext.txt", "w");
				foreach(g; glyphs) {
					f.writeln(g);
				}
			}*/

			alloc.dispose(dest);
		}

		foreach(face; all_faces)
			if(face != null) FT_Done_Face(face);
	}

	public fRectangle measureString(dstring text) {
		fRectangle r = fRectangle(0,-ascent,1,lineHeight);
		auto range = textLayout(text, vec2(0,0));
		if(range.empty) return r;

		//range.popFront();
		foreach(g; range) {
			if(g.glyph == null) {
				fRectangle n;
				n.loc = g.loc;
				n.size = vec2(1,lineHeight);
				expandToFit(r, n);
			} else {
				fRectangle n; 
				n.loc = g.loc + cast(vec2)g.glyph.offset;
				n.size = cast(vec2)g.glyph.extent.size;
				expandToFit(r, n);
			}
		}
		
		return r;
	}

	/*
	 * Returns an range of layoutPos that is the text layed out
	 * The layout engin can basicly do what ever it wants with the text you give it
	 * 
	 * Things the layout engin will not guarantee
	 *      - ordering of the chars in the layout range possibly will not match the ordering of the chars in the input
	 *      - the layout range possibly will not contain all the chars in the input(most likly wont)
	 *      - the layout range possibly will contain chars that were not in the input, what ever it dertermins to be the correct way to layout the text
	 */
	public auto textLayout(dstring text, vec2 pen) {
		import std.range;
		struct Result{
			private dstring data;
			private Font font;
			private uint loc = 0;
			private vec2 pen_loc; 
			private vec2 line_start; 
			private uint line_count = 0;
			private float tab_width; 

			public bool empty = false;;
			public LayoutPos front;
			public void popFront() { 
				if(loc >= data.length) {
					empty = true;
					return;
				}

				dchar dc = data[loc];
				loc ++;

				// Special chars
				if(dc == '\r') {
					popFront(); // We skip '/r'
					return;
				}
				if(dc == '\n') {
					front.glyph = null;
					front.c = dc;
					front.loc = pen_loc;

					line_count++;
					pen_loc = line_start + vec2(0, font.lineHeight*line_count);
					return;
				}
				if(dc == '\t') {
					import std.math;
					front.glyph = null;
					front.c = dc;
					front.loc = pen_loc;

					pen_loc.x = ceil((pen_loc.x + 1 - line_start.x)/tab_width)*tab_width + line_start.x;
					return;
				}
				
				auto g = dc in font.glyphs;
				if(g == null) // We skip chars we dont have a glyph for... 
				{
					popFront();
					return;
				}

				front.glyph = g;
				front.c = dc;
				front.loc = pen_loc;
				pen_loc = pen_loc + cast(vec2)g.advance;
			} 
		}
		static assert(isInputRange!Result);


		Result r;
		r.data = text;
		r.font = this;
		r.pen_loc = pen;
		r.line_start = pen;

		// Get the size of a tab
		auto g = ' ' in glyphs;
		if(g != null) {
			r.tab_width = g.advance.x * 5; // Width of 5 spaces
		} else r.tab_width = 0; // No space? No tabs :/ 

		r.popFront();
		return r;
	}

}

struct Glyph
{
	private uint id;
	private uint font_id;

	ivec2 advance;
	ivec2 offset;
	iRectangle extent;
	dchar glyphChar;

}

struct LayoutPos
{
	Glyph* glyph = null;
	dchar c; 
	vec2 loc; 
}

private struct glyphID
{
	dchar c;
	uint id;
}

private auto allGlyphs(FT_Face face) {
	import std.range;
	struct result
	{
		private FT_Face f;
		glyphID front;
		bool empty;
		this(FT_Face F) {
			f = F;
			front.c = FT_Get_First_Char(f, &(front.id));
			empty = (front.id == 0);
		}
		void popFront() {
			front.c = FT_Get_Next_Char(f, front.c, &(front.id));
			empty = (front.id == 0);
		}
	}
	static assert(isInputRange!result);
	return result(face);
}

private uint nextPowerOf2(uint v) {
	v--;
	v |= v >> 1;
	v |= v >> 2;
	v |= v >> 4;
	v |= v >> 8;
	v |= v >> 16;
	v++;
	return v;
}

private double fontCordsToPixelX(FT_Face face, short cord) {
	FT_Size_Metrics*  metrics = &face.size.metrics; /* shortcut */
	double em_size, scale;
	em_size = 1.0 * face.units_per_EM;
	scale = metrics.x_ppem / em_size;
	return cord*scale;
}

private double fontCordsToPixelY(FT_Face face, short cord) {
	FT_Size_Metrics*  metrics = &face.size.metrics; /* shortcut */
	double em_size, scale;
	em_size = 1.0 * face.units_per_EM;
	scale = metrics.y_ppem / em_size;
	return cord*scale;
}