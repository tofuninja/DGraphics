module graphics.GraphicsState;
// Global Graphics State

import derelict.opengl3.gl3;




// State
private int texUnitCount;





/**
 * Init Graphics State after openGl has been inited
 */
public void initializeGraphicsState()
{
	glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &texUnitCount);

	TextureBindPoints = new TextureImageUnit[texUnitCount];
	foreach(int i; 0 .. texUnitCount)
	{
		TextureBindPoints[i] = TextureImageUnit(i);
	}

	debug
	{
		import std.stdio;
		writeln("Texture Unit Count: ", texUnitCount);
	}
}

/**
 * The number of Texture Image Units avalible for binding
 */
public int TextureUnitCount() { return texUnitCount; }

/**
 * Represents a bind point for Textures
 */
public struct TextureImageUnit
{
	import graphics.Texture;
	private int loc = 0;

	private this(int bindLoc)
	{
		loc = bindLoc;
	}

	/**
	 * Location of bind point
	 */
	@property public int location() { return loc; }

	/**
	 * Bind texture to this texture bind point
	 */
	public void bind(Texture tex)
	{
		glActiveTexture(GL_TEXTURE0 + loc);
		glBindTexture(tex.textureType, tex.textureID);
	}
}

/**
 * Texture Bind Points
 */
public TextureImageUnit[] TextureBindPoints;