module graphics.hw.renderlist;

import graphics.hw.game;

//    _____                _             _      _     _        
//   |  __ \              | |           | |    (_)   | |     
//   | |__) |___ _ __   __| | ___ _ __  | |     _ ___| |_   
//   |  _  // _ \ '_ \ / _` |/ _ \ '__| | |    | / __| __|
//   | | \ \  __/ | | | (_| |  __/ |    | |____| \__ \ |_  
//   |_|  \_\___|_| |_|\__,_|\___|_|    |______|_|___/\__|
//                                                                                          
//                                                                                          
// Abstracts all rendering and state commands through a central point

// TODO add nestable command lists?
// TODO add texture invalidate and sub data commands?

struct drawCommand
{
	uint vertexCount		= 0;
	uint vertexOffset		= 0;
	uint instanceCount		= 1;
	uint instanceOffset		= 0;
}

struct drawIndexedCommand
{
	uint vertexCount		= 0;
	uint vertexOffset		= 0;
	uint instanceCount		= 1;
	uint instanceOffset		= 0;
	uint indexOffset		= 0;
}

struct uboCommand
{
	bufferRef ubo;
	uint location 	= 0;
	uint offset 	= 0;
	uint size		= 0;
}

struct vboCommand
{
	bufferRef vbo;
	uint location 	= 0;
	uint offset 	= 0;
	uint stride 	= 0;
}

struct iboCommand
{
	bufferRef ibo;
	uint offset		= 0;
	indexSize size 	= indexSize.uint32;
}

struct texCommand(textureType T = textureType.tex2D)
{
	textureRef!T texture;
	int location = 0;
}

struct samplerCommand
{
	samplerRef sampler;
	int location = 0;
}

struct blitCommand
{
	import math.geo.rectangle;
	import math.matrix : ivec2;
	
	fboRef fbo;
	iRectangle source		= iRectangle(ivec2(0,0), ivec2(0,0));
	iRectangle destination 	= iRectangle(ivec2(0,0), ivec2(0,0));
	bool blitColor 			= true;
	bool blitDepth 			= false;
	bool blitStencil 		= false;
	filterMode filter 		= filterMode.nearest;
}

struct clearCommand
{
	import graphics.color;
	
	Color colorClear 	= Color(0,0,0,255);
	float depthClear 	= 1.0f;
	ubyte stencilClear 	= 0;
}


