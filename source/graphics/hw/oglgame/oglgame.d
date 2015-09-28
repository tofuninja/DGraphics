//     ____   _____ _      _____                      
//    / __ \ / ____| |    / ____|                     
//   | |  | | |  __| |   | |  __  __ _ _ __ ___   ___ 
//   | |  | | | |_ | |   | | |_ |/ _` | '_ ` _ \ / _ \
//   | |__| | |__| | |___| |__| | (_| | | | | | |  __/
//    \____/ \_____|______\_____|\__,_|_| |_| |_|\___|
//                                                    
//                                                    
// OpenGL implementation of Game
//
// TODO test to see if running multiple threads of this actually works!
// TODO make a better resorce manager, needs to be abstract enough to handle haveing the resorces loaded from many different sources including compuile time loading
// TODO Move all texture and buffer management into this, need to keep all opengl self contained in this one class! 
// TODO Move all api calls into here! This is a must do, it is the only way to keep every thing sane and will allow api switches to be simple later on
// TODO clean up or remove the shit in shader.d
// TODO remove the shit in renderTarget.d
// TODO cleanup or remove the shit in buffer.d

module graphics.hw.oglgame.oglgame;

public import graphics.hw.oglgame.texture;
public import graphics.hw.oglgame.shader;
public import graphics.hw.oglgame.buffer;
public import graphics.hw.oglgame.vao;
public import graphics.hw.oglgame.fbo;
public import graphics.hw.oglgame.sampler;
public import graphics.hw.oglgame.rendercommands;
public import graphics.hw.oglgame.state;
