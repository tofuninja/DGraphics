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
				//assert(g.extent.size.x == slot.bitmap.width);
				//assert(g.extent.size.y == slot.bitmap.rows);
				//assert(g.advance.x == slot.advance.x >> 6);
				//assert(g.advance.y == slot.advance.y >> 6);
			}

			/*
			{
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
				img.saveImage("fonttexture.png");
			}*/


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

			freeT(dest);
		}

		FT_Done_Face(face);


	}

	public fRectangle measureString(dstring text)
	{
		auto font = this;
		vec2 min, max;
		min = vec2( 999999, 999999);
		max = vec2(-999999,-999999);
		vec2 textloc = vec2(0,0);
		vec2 lineStart = textloc;
		int lineCount = 0; 
		float tabWidth = font.glyphs[' '].advance.x * 5; // Width of 5 spaces
		
		vec2 minVec2(vec2 a, vec2 b)
		{
			float x,y;
			x = (a.x < b.x)? a.x : b.x;
			y = (a.y < b.y)? a.y : b.y;
			return vec2(x,y);
		}
		
		vec2 maxVec2(vec2 a, vec2 b)
		{
			float x,y;
			x = (a.x > b.x)? a.x : b.x;
			y = (a.y > b.y)? a.y : b.y;
			return vec2(x,y);
		}
		
		foreach(dc; text)
		{
			// Special chars
			if(dc == '\r') continue;
			if(dc == '\n') {
				lineCount++;
				textloc = lineStart + vec2(0, font.lineHeight*lineCount);
				continue;
			}
			if(dc == '\t')
			{
				import std.math;
				textloc.x = ceil((textloc.x + 1 - lineStart.x)/tabWidth)*tabWidth + lineStart.x;
				continue;
			}
			
			auto gp = dc in font.glyphs;
			Glyph g;
			if(gp) 	g = *gp;
			else 	g = font.glyphs['█'];
			
			vec2 offset = cast(vec2)g.offset; 
			vec2 loc = textloc + offset;
			vec2 size = cast(vec2)g.extent.size - vec2(2,2);
			
			min = minVec2(min, loc);
			min = minVec2(min, loc + size);
			max = maxVec2(max, loc);
			max = maxVec2(max, loc + size);
			
			textloc = textloc + cast(vec2)g.advance;
		}
		
		return fRectangle(min, (max-min));
	}

	public vec2 locateChar(dstring text, int index)
	{
		auto font = this;

		vec2 textloc = vec2(0,0);
		vec2 lineStart = textloc;
		int lineCount = 0; 
		float tabWidth = font.glyphs[' '].advance.x * 5; // Width of 5 spaces

		int i = 0;
		foreach(dc; text)
		{
			// Special chars
			if(dc == '\r') continue;
			if(dc == '\n') {
				if(i == index) break;
				lineCount++;
				textloc = lineStart + vec2(0, font.lineHeight*lineCount);
				continue;
			}
			if(dc == '\t')
			{
				import std.math;
				if(i == index) break;
				textloc.x = ceil((textloc.x + 1 - lineStart.x)/tabWidth)*tabWidth + lineStart.x;
				continue;
			}
			
			auto gp = dc in font.glyphs;
			Glyph g;
			if(gp) 	g = *gp;
			else 	g = font.glyphs['█'];

			if(i == index) break;
			textloc = textloc + cast(vec2)g.advance;
			i++;
		}
		
		return textloc;
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

uint nextPowerOf2(uint v)
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