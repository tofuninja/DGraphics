module graphics.hw.structs;

import graphics.hw.game;
import math.matrix;
import math.geo.rectangle;
import graphics.color;

//    _____        __         _____ _                   _       
//   |_   _|      / _|       / ____| |                 | |      
//     | |  _ __ | |_ ___   | (___ | |_ _ __ _   _  ___| |_ ___ 
//     | | | '_ \|  _/ _ \   \___ \| __| '__| | | |/ __| __/ __|
//    _| |_| | | | || (_) |  ____) | |_| |  | |_| | (__| |_\__ \
//   |_____|_| |_|_| \___/  |_____/ \__|_|   \__,_|\___|\__|___/
//                                                              
//                                                              
// Used in the creation of the many game resorces, including the game it self

public struct gameInitInfo
{
	string title		= "Game";
	ivec2 size 			= ivec2(500, 500);
	bool fullscreen 	= false;
	bool resizeable		= true;
	bool boarder		= true;
	bool show		 	= true;
}

public struct gameStateInfo
{
	bool initialized = false; 
	uint uniformAlignment;
	bool shouldClose;
	bool[key.count] keyboard;
	bool[mouseButton.count] mouseButtons;
	vec2 mousePos;
	float fps;
	uint totalFrames;
	fboRef mainFbo;
	iRectangle mainViewport;
	// TODO window size
	// TODO window location
}

/**
 * Keeps track of rendering state
 */
struct renderStateInfo
{
	// TODO add alpha blend state
	// TODO add stencil test state
	// TODO add alpha test state
	// TODO add polygon offset state
	// TODO add scissor state
	// TODO add seamless cubemap state
	// TODO add primitive restart state
	// TODO add back face culling state
	
	public bool 			depthTest 			= false;
	public cmpFunc 			depthFunction 		= cmpFunc.less;
	public bool 			blend				= false;
	public blendStateInfo	blendState;
	public renderMode 		mode 				= renderMode.triangles;
	public fboRef 			fbo;
	public shaderRef 		shader; 
	public vaoRef			vao;
	public iRectangle		viewport			= iRectangle(ivec2(0,0),ivec2(1,1));
	public bool[8]			enableClip;
	public bool 			backFaceCulling		= false;
	public frontFaceMode	frontOrientation	= frontFaceMode.counter_clockwise;
}

public struct blendStateInfo
{
	public blendMode		colorBlend			= blendMode.add;
	public blendMode		alphaBlend			= blendMode.add;
	public blendParameter 	srcColor			= blendParameter.one;
	public blendParameter 	dstColor			= blendParameter.zero;
	public blendParameter 	srcAlpha			= blendParameter.one;
	public blendParameter 	dstAlpha			= blendParameter.zero;
}

public struct textureCreateInfo(textureType T = textureType.tex2D)
{
	enum textureType		type 			= T;
	colorFormat				format 			= colorFormat.RGBA_u8;
	uvec3 					size 			= uvec3(0,0,0);
	uint 					levels			= 1;
	bool 					renderBuffer 	= false;
}

alias textureCreateInfo1D = textureCreateInfo!(textureType.tex1D);
alias textureCreateInfo2D = textureCreateInfo!(textureType.tex2D);
alias textureCreateInfo3D = textureCreateInfo!(textureType.tex2D);

public struct textureViewCreateInfo(textureType T)
{
	textureRef!(T)			source;
	colorFormat				format 	= colorFormat.RGBA_u8;
	uint 					index	= 0;
}

public struct samplerCreateInfo
{
	filterMode			minFilter		= filterMode.nearest;
	filterMode			magFilter 		= filterMode.nearest;
	mipmapFilterMode	mipFilter 		= mipmapFilterMode.none;
	wrapMode			wrap_x			= wrapMode.edge;
	wrapMode			wrap_y			= wrapMode.edge;
	wrapMode			wrap_z			= wrapMode.edge;
	Color				boarderColor	= Color(0,0,0,255);
}

public struct shaderCreateInfo
{
	string vertShader = null;
	string fragShader = null;
	string geomShader = null;
	string tescShader = null;
	string teseShader = null;
}

public struct fboCreateInfo
{
	public struct colorAttachment
	{
		textureRef!(textureType.tex2D) 	tex;
		bool 							enabled	= false;
		uint 							level 	= 0;
	}
	colorAttachment[8] 	colors;
	colorAttachment		depth;
	colorAttachment		stencil;
	colorAttachment		depthstencil; // Combined, if enabled, depth&stencil are ignored
}

public struct bufferCreateInfo
{
	bufferUsage	usage	= bufferUsage.vertex;
	uint 		size	= 0;
	bool 		dynamic = true;;
	void[]		data 	= null;
	
	// Will prob never need these
	// bool		mapRead;
	// bool		mapWrite;
	// bool		mapCoherent;
	// bool		mapPersistant;
	// bool		clientSpace;
}

public struct vaoCreateInfo
{
	public struct attachment
	{
		bool enabled 			= false; 
		vertexType elementType 	= vertexType.float32;
		uint elementCount 		= 0;
		uint offset 			= 0;
		uint bindIndex			= 0;
	}
	
	attachment[16] attachments;
	uint[16] bindPointDivisors;
}

public struct textureSubDataInfo
{
	uint level				= 0;
	uvec3 size				= uvec3(0,0,0);
	uvec3 offset			= uvec3(0,0,0);
	void[] data				= null;
	colorFormat format		= colorFormat.RGBA_u8;
}

public struct bufferSubDataInfo
{
	uint offset = 0;
	void[] data = null;
}


