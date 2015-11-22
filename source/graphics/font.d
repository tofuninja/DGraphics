module graphics.font;

import derelict.freetype.ft;
import math.matrix;
import math.geo.rectangle;
import graphics.hw.game;

class Font
{
	static FT_Library ftlibrary;

	public Glyph[dchar] glyphs;
	public texture2DRef texture; 
	public int lineHeight = 0;
	public int ascent = 0;
	public int descent = 0;

	public this(string file, float size)
	{
		loadFont(file, size);
	}

	public ~this()
	{
		Game.destroyTexture(texture);
	}

	private void loadFont(string file, float size)
	{
		import std.string;
		import std.stdio;
		import std.conv;
		FT_Face face;
		auto error = FT_New_Face(ftlibrary, file.toStringz(), 0, &face);

		if(error == FT_Err_Unknown_File_Format) throw new Exception("Invalid file format, it is not a font");
		else if(error) 							throw new Exception("Unable to load font file: " ~ error.to!string);

		error = FT_Set_Char_Size(
			face,    				/* handle to face object           */
			0,      			 	/* char_width in 1/64th of points  */
			cast(int)(size*64),   	/* char_height in 1/64th of points */
			72,     				/* horizontal device resolution    */
			72 );   				/* vertical device resolution      */

		if(error) throw new Exception("Font size not valid: " ~ error.to!string);

		lineHeight = cast(int)fontCordsToPixelY(face, face.height);
		ascent = cast(int)fontCordsToPixelY(face, face.ascender);
		descent = cast(int)fontCordsToPixelY(face, face.descender);

		// Load all the glyphs and put them into the glyphs array
		foreach(g; allGlyphs(face))
		{

			auto slot = face.glyph;
			error = FT_Load_Glyph(face,  g.id, FT_LOAD_DEFAULT);
			if ( error ) continue;
			FT_Glyph  glyph; error = FT_Get_Glyph(slot, &glyph);
			if ( error ) continue;

			FT_BBox  bbox;
			FT_Glyph_Get_CBox(glyph, FT_GLYPH_BBOX_PIXELS, &bbox);
			auto width  = bbox.xMax - bbox.xMin;
			auto height = bbox.yMax - bbox.yMin;



			import std.math;
			Glyph myglyph;
			myglyph.glyphChar = g.c;
			myglyph.id = g.id;
			myglyph.extent.size = ivec2(width + 2, height + 2);
			myglyph.advance = ivec2(slot.advance.x >> 6, slot.advance.y >> 6);
			glyphs[g.c] = myglyph;

			FT_Done_Glyph(glyph);
		}

		// Render all the glyphs to a texture
		{
			import math.geo.binpacker2d;
			import std.algorithm;
			import util.memory.malloc;
			auto r = map!((ref a) => &(a.extent))(glyphs.byValue);
			auto l = glyphs.length;
			auto binSize = binPack2D(r, l);
			uint s = nextPowerOf2(max(binSize.x,binSize.y));
			auto dest = mallocTA!ubyte(s*s);

			foreach(ref g; glyphs.byValue)
			{
				auto slot = face.glyph;
				error = FT_Load_Glyph(face, g.id, FT_LOAD_RENDER);
				if ( error ) continue;

				auto penx = g.extent.loc.x;
				auto peny = g.extent.loc.y;
				
				auto p = slot.bitmap.buffer;
				for(int i = 0; i < slot.bitmap.rows; i++)
				{
					for(int j = 0; j < slot.bitmap.width; j++)
					{
						dest[(penx + j) + (peny + i)*s] = p[j];
					}
					p += slot.bitmap.pitch;
				}

				g.offset.x = slot.bitmap_left;
				g.offset.y = -slot.bitmap_top;
			}

			// Create a texture and fill it with the data
			{
				textureCreateInfo2D info;
				info.format = colorFormat.R_u8;
				info.size = uvec3(s, s, 0);
				texture = Game.createTexture(info);
				
				textureSubDataInfo sub;
				sub.size = uvec3(s, s, 0);
				sub.data = dest;
				sub.format = colorFormat.R_u8;
				texture.subData(sub);
			}

			/*
			{
				// Save the fontmap texture inot an image
				import graphics.color;
				import graphics.image;
				Image img = new Image(s, s);
				for(int i = 0; i < s; i++)
				{
					for(int j = 0; j < s; j++)
					{
						img[i,j] = Color(0, 0, 0, dest[i + j*s]);
					}
				}
				img.saveImage(file ~ "_fonttexture.png");
			}
			*/

			/*
			// Save all supported chars into a text
			{
				import std.file;
				auto f = File(file ~ "_fonttext.txt", "w");
				foreach(g; glyphs)
				{
					f.writeln(g);
				}
			}*/

			freeT(dest);
		}

		FT_Done_Face(face);
	}

	public fRectangle measureString(dstring text)
	{
		fRectangle r = fRectangle(0,0,0,0);
		auto range = textLayout(text, vec2(0,0));
		if(range.empty) return r;
		r.loc = range.front.loc + range.front.glyph.offset;
		r.size = cast(vec2)range.front.glyph.extent.size;
		range.popFront();
		foreach(g; range)
		{
			if(g.glyph == null) continue;
			fRectangle n; 
			n.loc = g.loc + g.glyph.offset;
			n.size = cast(vec2)g.glyph.extent.size;
			expandToFit(r, n);
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
	public auto textLayout(dstring text, vec2 pen)
	{
		import std.range.primitives;
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
			public void popFront() 	
			{ 
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
				if(dc == '\t')
				{
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
		if(g != null)
		{
			r.tab_width = g.advance.x * 5; // Width of 5 spaces
		}
		else r.tab_width = 0; // No space? No tabs :/ 

		r.popFront();
		return r;
	}

}

struct Glyph
{
	private uint id;

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

private auto allGlyphs(FT_Face face)
{
	import std.range;
	struct result
	{
		private FT_Face f;
		glyphID front;
		bool empty;
		this(FT_Face F)
		{
			f = F;
			front.c = FT_Get_First_Char(f, &(front.id));
			empty = (front.id == 0);
		}
		void popFront()
		{
			front.c = FT_Get_Next_Char(f, front.c, &(front.id));
			empty = (front.id == 0);
		}
	}
	static assert(isInputRange!result);
	return result(face);
}

private uint nextPowerOf2(uint v)
{
	v--;
	v |= v >> 1;
	v |= v >> 2;
	v |= v >> 4;
	v |= v >> 8;
	v |= v >> 16;
	v++;
	return v;
}

private double fontCordsToPixelX(FT_Face face, short cord)
{
	FT_Size_Metrics*  metrics = &face.size.metrics; /* shortcut */
	double em_size, scale;
	em_size = 1.0 * face.units_per_EM;
	scale = metrics.x_ppem / em_size;
	return cord*scale;
}

private double fontCordsToPixelY(FT_Face face, short cord)
{
	FT_Size_Metrics*  metrics = &face.size.metrics; /* shortcut */
	double em_size, scale;
	em_size = 1.0 * face.units_per_EM;
	scale = metrics.y_ppem / em_size;
	return cord*scale;
}