module resources.glslManager;

// For now, just stacicly include the glsl code into the program
// Maybe this could be changed later to load at run time but I dont really see a benifit


// All text imports are located in the views folder
public enum simpleShaderVert = import("simpleShader.vertex.glsl");
public enum simpleShaderFrag = import("simpleShader.fragment.glsl");