module graphics.hw.game;

//     _____          __  __ ______ 
//    / ____|   /\   |  \/  |  ____|
//   | |  __   /  \  | \  / | |__   
//   | | |_ | / /\ \ | |\/| |  __|  
//   | |__| |/ ____ \| |  | | |____ 
//    \_____/_/    \_\_|  |_|______|
//                                  
//                                  
// Abstracts the rendering through one central point
// The module that is imported as Game must impliment the Game

public import graphics.hw.enums;
public import graphics.hw.structs;
public import graphics.hw.renderlist;
public import graphics.hw.util;
public import Game 		= graphics.hw.oglgame.oglgame;
alias textureRef 		= Game.textureRef;
alias texture1DRef 		= Game.textureRef!(textureType.tex1D);
alias texture2DRef 		= Game.textureRef!(textureType.tex2D);
alias texture3DRef 		= Game.textureRef!(textureType.tex3D);
alias samplerRef		= Game.samplerRef;
alias shaderRef 		= Game.shaderRef;
alias fboRef 			= Game.fboRef;
alias bufferRef 		= Game.bufferRef;
alias vaoRef 			= Game.vaoRef;
alias cursorRef			= Game.cursorRef;


// TODO add a seperate type for compute?
// TODO add enforcement that Game really has everything? 




