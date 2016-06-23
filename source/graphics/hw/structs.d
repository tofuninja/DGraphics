module graphics.hw.structs;

import graphics.hw;
import math.matrix;
import math.geo.rectangle;
import graphics.color;
import core.time;

//    _____        __         _____ _                   _       
//   |_   _|      / _|       / ____| |                 | |      
//     | |  _ __ | |_ ___   | (___ | |_ _ __ _   _  ___| |_ ___ 
//     | | | '_ \|  _/ _ \   \___ \| __| '__| | | |/ __| __/ __|
//    _| |_| | | | || (_) |  ____) | |_| |  | |_| | (__| |_\__ \
//   |_____|_| |_|_| \___/  |_____/ \__|_|   \__,_|\___|\__|___/
//                                                              
//                                                              
// Used in the creation of the many game resorces, including the game it self

public struct hwInitInfo
{
	string title		= "Game";
	ivec2 size 			= ivec2(500, 500);
	bool fullscreen 	= false;
	bool resizeable		= true;
	bool boarder		= true;
	bool show		 	= true;
}

public struct hwStateInfo
{
	bool initialized = false; 
	uint uniformAlignment;
	bool shouldClose;
	bool[hwKey.count] keyboard;
	bool[hwMouseButton.count] mouseButtons;
	vec2 mousePos;
	hwFboRef mainFbo;
	iRectangle mainViewport;
	Duration doubleClick = dur!"msecs"(500);
	bool visible;
}

/**
 * Keeps track of rendering state
 */
struct hwRenderStateInfo
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
	public hwCmpFunc 		depthFunction 		= hwCmpFunc.less;
	public bool 			blend				= false;
	public hwBlendStateInfo	blendState;
	public hwRenderMode 	mode 				= hwRenderMode.triangles;
	public hwFboRef 			fbo;
	public hwShaderRef 		shader; 
	public hwVaoRef			vao;
	public iRectangle		viewport			= iRectangle(ivec2(0,0),ivec2(1,1));
	public bool[8]			enableClip;
	public bool 			backFaceCulling		= false;
	public hwFrontFaceMode	frontOrientation	= hwFrontFaceMode.counter_clockwise;
}

public struct hwBlendStateInfo
{
	public hwBlendMode			colorBlend			= hwBlendMode.add;
	public hwBlendMode			alphaBlend			= hwBlendMode.add;
	public hwBlendParameter 	srcColor			= hwBlendParameter.one;
	public hwBlendParameter 	dstColor			= hwBlendParameter.zero;
	public hwBlendParameter 	srcAlpha			= hwBlendParameter.one;
	public hwBlendParameter 	dstAlpha			= hwBlendParameter.zero;
}

public struct hwTextureCreateInfo(hwTextureType T = hwTextureType.tex2D) {
	enum hwTextureType		type 			= T;
	hwColorFormat			format 			= hwColorFormat.RGBA_n8;
	uvec3 					size 			= uvec3(0,0,0);
	uint 					levels			= 1;
	bool 					renderBuffer 	= false;
}

public struct hwTextureViewCreateInfo(hwTextureType T) {
	hwTextureRef!(T)			source;
	hwColorFormat			format 	= hwColorFormat.RGBA_n8;
	uint 					index	= 0;
}

public struct hwSamplerCreateInfo
{
	hwFilterMode		minFilter		= hwFilterMode.nearest;
	hwFilterMode		magFilter 		= hwFilterMode.nearest;
	hwMipmapFilterMode	mipFilter 		= hwMipmapFilterMode.none;
	hwWrapMode			wrap_x			= hwWrapMode.edge;
	hwWrapMode			wrap_y			= hwWrapMode.edge;
	hwWrapMode			wrap_z			= hwWrapMode.edge;
	Color				boarderColor	= Color(0,0,0,255);
}

public struct hwShaderCreateInfo
{
	string vertShader = null;
	string fragShader = null;
	string geomShader = null;
	string tescShader = null;
	string teseShader = null;
}

public struct hwFboCreateInfo
{
	public struct colorAttachment
	{
		hwTextureRef!(hwTextureType.tex2D) 	tex;
		bool 								enabled	= false;
		uint 								level 	= 0;
	}
	colorAttachment[8] 	colors;
	colorAttachment		depth;
	colorAttachment		stencil;
	colorAttachment		depthstencil; // Combined, if enabled, depth&stencil are ignored
}

public struct hwBufferCreateInfo
{
	hwBufferUsage	usage	= hwBufferUsage.vertex;
	uint 			size	= 0;
	bool 			dynamic = true;;
	void[]			data 	= null;
	
	// Will prob never need these
	// bool		mapRead;
	// bool		mapWrite;
	// bool		mapCoherent;
	// bool		mapPersistant;
	// bool		clientSpace;
}

public struct hwVaoCreateInfo
{
	public struct attachment
	{
		bool enabled 				= false; 
		hwVertexType elementType 	= hwVertexType.float32;
		uint elementCount 			= 0;
		uint offset 				= 0;
		uint bindIndex				= 0;
	}
	
	attachment[16] attachments;
	uint[16] bindPointDivisors;
}

public struct hwCursorCreateInfo
{
	Color[] pixels;
	uvec2 size;
	ivec2 hotspot;
}

public struct hwTextureSubDataInfo
{
	uint level				= 0;
	uvec3 size				= uvec3(0,0,0);
	uvec3 offset			= uvec3(0,0,0);
	void[] data				= null;
	hwColorFormat format	= hwColorFormat.RGBA_n8;
}

public struct hwBufferSubDataInfo
{
	uint offset = 0;
	void[] data = null;
}


//	  _____                         _____                                          _     
//	 / ____|                       / ____|                                        | |    
//	| |  __  __ _ _ __ ___   ___  | |     ___  _ __ ___  _ __ ___   __ _ _ __   __| |___ 
//	| | |_ |/ _` | '_ ` _ \ / _ \ | |    / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
//	| |__| | (_| | | | | | |  __/ | |___| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
//	 \_____|\__,_|_| |_| |_|\___|  \_____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/
//	                                                                                     
//	                                                                                     

struct hwDrawCommand
{
	uint vertexCount		= 0;
	uint vertexOffset		= 0;
	uint instanceCount		= 1;
	uint instanceOffset		= 0;
}

struct hwDrawIndexedCommand
{
	uint vertexCount		= 0;
	uint vertexOffset		= 0;
	uint instanceCount		= 1;
	uint instanceOffset		= 0;
	uint indexOffset		= 0;
}

struct hwUboCommand
{
	hwBufferRef ubo;
	uint location 	= 0;
	uint offset 	= 0;
	uint size		= 0;
}

struct hwVboCommand
{
	hwBufferRef vbo;
	uint location 	= 0;
	uint offset 	= 0;
	uint stride 	= 0;
}

struct hwIboCommand
{
	hwBufferRef ibo;
	uint offset			= 0;
	hwIndexSize size 	= hwIndexSize.uint32;
}

struct hwTexCommand(hwTextureType T = hwTextureType.tex2D) {
	hwTextureRef!T texture;
	int location = 0;
}


struct hwSamplerCommand
{
	hwSamplerRef sampler;
	int location = 0;
}

struct hwBlitCommand
{
	import math.geo.rectangle;
	import math.matrix : ivec2;
	
	hwFboRef fbo;
	iRectangle source		= iRectangle(ivec2(0,0), ivec2(0,0));
	iRectangle destination 	= iRectangle(ivec2(0,0), ivec2(0,0));
	bool blitColor 			= true;
	bool blitDepth 			= false;
	bool blitStencil 		= false;
	hwFilterMode filter 	= hwFilterMode.nearest;
}

struct hwClearCommand
{
	import graphics.color;
	
	Color colorClear 	= Color(0,0,0,255);
	float depthClear 	= 1.0f;
	ubyte stencilClear 	= 0;
}

struct hwMousePosCommand
{
	vec2 loc;
}

struct hwVisibilityCommand
{
	bool visible; 
}

struct hwDoubleClickCommand{
	Duration doubleClickTime;
}

/// Callback interface
interface hwICallback{
	void onKey(hwKey, hwKeyModifier, bool);
	void onChar(dchar);
	void onMouseMove(vec2);
	void onMouseClick(vec2, hwMouseButton, bool);
	void onWindowResize(vec2);
	void onScroll(vec2, int);
}
