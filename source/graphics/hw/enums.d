﻿module graphics.hw.enums;

//    ______                           
//   |  ____|                          
//   | |__   _ __  _   _ _ __ ___  ___ 
//   |  __| | '_ \| | | | '_ ` _ \/ __|
//   | |____| | | | |_| | | | | | \__ \
//   |______|_| |_|\__,_|_| |_| |_|___/
//                                     
//                                     
// Various enums for use in the Game

enum hwCmpFunc
{
	never,
	always,
	equal,
	notEqual,
	less,
	greater,
	lessEqual,
	greaterEqual,
	
	count
}

enum hwRenderMode
{
	points,
	triangles,
	lines,
	patches,
	triangleStrip,
	lineStrip,
	
	count
}

enum hwTextureType
{
	tex1D,
	tex2D,
	tex3D,
	texCube,
	tex1DArray,
	tex2DArray,
	texCubeArray,
	
	count
}

enum hwColorFormat
{
	// Unsigned int
	R_u8,
	RG_u8,
	RGB_u8,
	RGBA_u8,

	// Normalized 
	R_n8,
	RG_n8,
	RGB_n8,
	RGBA_n8,
	
	R_f32,
	RG_f32,
	RGB_f32,
	RGBA_f32,
	
	Depth_24,
	Depth_32,
	Stencil_8,
	Depth_24_Stencil_8,
	Depth_32_Stencil_8,
	
	count
}

enum hwFilterMode
{
	nearest,
	linear,
	// TODO anistropic? 
	
	count
}

enum hwMipmapFilterMode
{
	none,
	nearest,
	linear,
	
	count
}

enum hwWrapMode
{
	repeat,
	mirrorRepeat,
	edge,
	edgeBlend, // GL_CLAMP_TO_BOARDER
	
	count
}

enum hwVertexType
{
	int8,
	int16,
	int32,
	uint8,
	uint16,
	uint32,
	float16,
	float32,
	
	count
}

enum hwIndexSize
{
	uint8,
	uint16,
	uint32,
	
	count
}

enum hwBufferUsage
{
	vertex,
	uniform,
	index,
	
	count
}

enum hwBlendMode
{
	add,
	subtract,
	rev_subtract,
	min,
	max,

	count
}

enum hwBlendParameter
{
	zero,
	one,
	src_color,
	dst_color,
	src_alpha,
	dst_alpha,
	one_minus_src_color,
	one_minus_dst_color,
	one_minus_src_alpha,
	one_minus_dst_alpha,

	count
}

enum hwFrontFaceMode
{
	clockwise,
	counter_clockwise,

	count
}

enum hwKey
{
	NO_KEY = 0,
	SPACE = 32 ,
	APOSTROPHE = 39,
	COMMA = 44,
	MINUS = 45,
	PERIOD = 46,
	SLASH = 47,
	NUM_0 = 48 ,
	NUM_1 = 49 ,
	NUM_2 = 50 ,
	NUM_3 = 51 ,
	NUM_4 = 52 ,
	NUM_5 = 53 ,
	NUM_6 = 54 ,
	NUM_7 = 55 ,
	NUM_8 = 56 ,
	NUM_9 = 57 ,
	SEMICOLON = 59,
	EQUAL = 61,
	A = 65 ,
	B = 66 ,
	C = 67 ,
	D = 68 ,
	E = 69 ,
	F = 70 ,
	G = 71 ,
	H = 72 ,
	I = 73 ,
	J = 74 ,
	K = 75 ,
	L = 76 ,
	M = 77 ,
	N = 78 ,
	O = 79 ,
	P = 80 ,
	Q = 81 ,
	R = 82 ,
	S = 83 ,
	T = 84 ,
	U = 85 ,
	V = 86 ,
	W = 87 ,
	X = 88 ,
	Y = 89 ,
	Z = 90 ,
	LEFT_BRACKET = 91,
	BACKSLASH = 92,
	RIGHT_BRACKET = 93,
	GRAVE_ACCENT = 96,
	WORLD_1 = 161,
	WORLD_2 = 162,
	ESCAPE = 256 ,
	ENTER = 257 ,
	TAB = 258 ,
	BACKSPACE = 259 ,
	INSERT = 260 ,
	DELETE = 261 ,
	RIGHT = 262 ,
	LEFT = 263 ,
	DOWN = 264 ,
	UP = 265 ,
	PAGE_UP = 266 ,
	PAGE_DOWN = 267 ,
	HOME = 268 ,
	END = 269 ,
	CAPS_LOCK = 280 ,
	SCROLL_LOCK = 281 ,
	NUM_LOCK = 282 ,
	PRINT_SCREEN = 283 ,
	PAUSE = 284 ,
	F1 = 290 ,
	F2 = 291 ,
	F3 = 292 ,
	F4 = 293 ,
	F5 = 294 ,
	F6 = 295 ,
	F7 = 296 ,
	F8 = 297 ,
	F9 = 298 ,
	F10 = 299 ,
	F11 = 300 ,
	F12 = 301 ,
	F13 = 302 ,
	F14 = 303 ,
	F15 = 304 ,
	F16 = 305 ,
	F17 = 306 ,
	F18 = 307 ,
	F19 = 308 ,
	F20 = 309 ,
	F21 = 310 ,
	F22 = 311 ,
	F23 = 312 ,
	F24 = 313 ,
	F25 = 314 ,
	KP_0 = 320 ,
	KP_1 = 321 ,
	KP_2 = 322 ,
	KP_3 = 323 ,
	KP_4 = 324 ,
	KP_5 = 325 ,
	KP_6 = 326 ,
	KP_7 = 327 ,
	KP_8 = 328 ,
	KP_9 = 329 ,
	KP_DECIMAL = 330 ,
	KP_DIVIDE = 331 ,
	KP_MULTIPLY = 332 ,
	KP_SUBTRACT = 333 ,
	KP_ADD = 334 ,
	KP_ENTER = 335 ,
	KP_EQUAL = 336 ,
	LEFT_SHIFT = 340 ,
	LEFT_CONTROL = 341 ,
	LEFT_ALT = 342 ,
	LEFT_SUPER = 343 ,
	RIGHT_SHIFT = 344 ,
	RIGHT_CONTROL = 345 ,
	RIGHT_ALT = 346 ,
	RIGHT_SUPER = 347 ,
	MENU = 348 ,
	
	count
}

enum hwMouseButton
{
	MOUSE_1 = 0,
	MOUSE_2 = 1,
	MOUSE_3 = 2,
	MOUSE_4 = 3,
	MOUSE_5 = 4,
	MOUSE_6 = 5,
	MOUSE_7 = 6,
	MOUSE_8 = 7,
	MOUSE_9 = 8,

	count,

	MOUSE_LAST = MOUSE_8,
	MOUSE_LEFT = MOUSE_1,
	MOUSE_RIGHT = MOUSE_2,
	MOUSE_MIDDLE = MOUSE_3,
	MOUSE_DOUBLE = MOUSE_9
}

enum hwKeyModifier
{
	shift = 1,
	ctrl = 2,
	alt = 4,
	superMod = 8,

	count
}

enum hwCursorMode
{
	normal,
	hidden,
	captured,

	count
}

enum hwSimpleCursor{
	arrow,
	arrow_and_hourglass,
	arrow_and_question,
	hourglass,
	i_bar,
	cross_hair,
	hand,
	size_h,
	size_v,
	size_all,
	size_forward_arrow,
	size_back_arrow,
	no_cursor,
	
	
	slash_circle,
	

	count
}

//enum hwWindowSizeState{
//    minimized,
//    maximized,
//    
//}