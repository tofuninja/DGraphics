module graphics.hw;

public import graphics.hw.enums;
public import graphics.hw.structs;
public import graphics.hw.util;

import Backend 			= graphics.hw.oglgame;
alias hwTextureRef 		= Backend.textureRef;
alias hwSamplerRef		= Backend.samplerRef;
alias hwShaderRef 		= Backend.shaderRef;
alias hwFboRef 			= Backend.fboRef;
alias hwBufferRef 		= Backend.bufferRef;
alias hwVaoRef 			= Backend.vaoRef;
alias hwCursorRef		= Backend.cursorRef;

// TODO add a seperate type for compute?

/// Init the graphics and hw resources
/// Creates a single window 
void hwInit(hwInitInfo info) {
	pragma(inline, true);
	Backend.init(info);
}

// 	 _              _____                _
// 	| |            / ____|              | |
// 	| |____      _| |     _ __ ___  __ _| |_ ___
// 	| '_ \ \ /\ / / |    | '__/ _ \/ _` | __/ _ \
// 	| | | \ V  V /| |____| | |  __/ (_| | ||  __/
// 	|_| |_|\_/\_/  \_____|_|  \___|\__,_|\__\___|


/// Create a texture
auto hwCreate(hwTextureType type)(hwTextureCreateInfo!type info) {
	pragma(inline, true);
	return Backend.createTexture(info);
}

/// Create a texture View
auto hwCreate(hwTextureType type)(hwTextureViewCreateInfo!type info) {
	pragma(inline, true);
	return Backend.createTexture(info);
}

/// Create an optinal texture sampler 
hwSamplerRef hwCreate(hwSamplerCreateInfo info) {
	pragma(inline, true);
	return Backend.createSampler(info);
}

/// Create a shader
hwShaderRef hwCreate(hwShaderCreateInfo info) {
	pragma(inline, true);
	return Backend.createShader(info);
}

/// Create a fbo
hwFboRef hwCreate(hwFboCreateInfo info) {
	pragma(inline, true);
	return Backend.createFbo(info);
}

/// Create a buffer
hwBufferRef hwCreate(hwBufferCreateInfo info) {
	pragma(inline, true);
	return Backend.createBuffer(info);
}

/// Create a vao
hwVaoRef hwCreate(hwVaoCreateInfo info) {
	pragma(inline, true);
	return Backend.createVao(info);
}

/// Create a cursor 
hwCursorRef hwCreate(hwCursorCreateInfo info) {
	pragma(inline, true);
	return Backend.createCursor(info);
}

// 	 _             _____            _
// 	| |           |  __ \          | |
// 	| |____      _| |  | | ___  ___| |_ _ __ ___  _   _
// 	| '_ \ \ /\ / / |  | |/ _ \/ __| __| '__/ _ \| | | |
// 	| | | \ V  V /| |__| |  __/\__ \ |_| | | (_) | |_| |
// 	|_| |_|\_/\_/ |_____/ \___||___/\__|_|  \___/ \__, |
// 	                                               __/ |
// 	                                              |___/

/// Destroy a texture
void hwDestroy(hwTextureType type)(hwTextureRef!type obj) {
	pragma(inline, true);
	Backend.destroyTexture(obj);
}

/// Destroy a sampler
void hwDestroy(hwSamplerRef obj) {
	pragma(inline, true);
	Backend.destroySampler(obj);
}

/// Destroy a shader
void hwDestroy(hwShaderRef obj) {
	pragma(inline, true);
	Backend.destroyShader(obj);
}

/// Destroy a fbo
void hwDestroy(hwFboRef obj) {
	pragma(inline, true);
	Backend.destroyFbo(obj);
}

/// Destroy a buffer
void hwDestroy(hwBufferRef obj) {
	pragma(inline, true);
	Backend.destroyBuffer(obj);
}

/// Destroy a vao
void hwDestroy(hwVaoRef obj) {
	pragma(inline, true);
	Backend.destroyVao(obj);
}

/// Destroy a cursor
void hwDestroy(hwCursorRef obj) {
	pragma(inline, true);
	Backend.destroyCursor(obj);
}

// 	 _              _____               _
// 	| |            / ____|             | |
// 	| |____      _| |     _ __ ___   __| |
// 	| '_ \ \ /\ / / |    | '_ ` _ \ / _` |
// 	| | | \ V  V /| |____| | | | | | (_| |
// 	|_| |_|\_/\_/  \_____|_| |_| |_|\__,_|

/// Make a draw command
void hwCmd(hwDrawCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Make an indexed draw command
void hwCmd(hwDrawIndexedCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Bind a ubo buffer to a ubo bind point
void hwCmd(hwUboCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Bind a vbo buffer to a vbo bind point
void hwCmd(hwVboCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Bind and ibo buffer for use in indexed draws 
void hwCmd(hwIboCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Bind a texture or texture view to a texture bind point
void hwCmd(hwTextureType type)(hwTexCommand!type cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Bind a sampler to a texture bind point for use in a texture sampeling
/// If no sampler is bound than a defult one is used 
void hwCmd(hwSamplerCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Blit contents from one fbo to another 
void hwCmd(hwBlitCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Clear the contents of a fbo
void hwCmd(hwClearCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Move the mouse to a specific position 
void hwCmd(hwMousePosCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Set the visibility of the window 
void hwCmd(hwVisibilityCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Set the render state
/// Will dif the state so only the needed changes are made
void hwCmd(hwRenderStateInfo cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Set the cursor mode
void hwCmd(hwCursorMode cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Set the current cursor
void hwCmd(hwCursorRef cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Set the double click timeout 
void hwCmd(hwDoubleClickCommand cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Set the callback interface, only one can be set at a time
void hwCmd(hwICallback cmd) {
	pragma(inline, true);
	Backend.cmd(cmd);
}

/// Get the current render state set by the render state command
hwRenderStateInfo hwRenderState() {
	pragma(inline, true);
	return Backend.currentRenderState();
}

/// Get the current hw state 
hwStateInfo hwState() {
	pragma(inline, true);
	return Backend.currentState();
}

/// Do a swap buffer, essentially finishes a frame
void hwSwapBuffers() {
	pragma(inline, true);
	Backend.swapBuffers();
}

/// Do input polling
void hwPollEvents() {
	pragma(inline, true);
	Backend.pollEvents();
}

/// Retrive a simple cursor provided by the OS
hwCursorRef hwGetSimpleCursor(hwSimpleCursor cursor) {
	pragma(inline, true);
	return Backend.getSimpleCursor(cursor);
}

/// Get the contents of the system clipboard 
string hwGetClipboard() {
	pragma(inline, true);
	return Backend.getClipboard();
}

/// Set the contents of the system clipboard 
void hwSetClipboard(string text) {
	pragma(inline, true);
	Backend.setClipboard(text);
}

/// Get hw version string
string hwGetVersionString() {
	pragma(inline, true);
	return Backend.getVersionString();
}