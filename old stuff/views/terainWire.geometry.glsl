////// DGRAPHICS \\\\\\
#version 330
 
layout(triangles) in;
layout (line_strip, max_vertices=4) out;
 
in vec4 color[3];
in vec2 texUV[3];
in vec3 n[3];
in vec3 worldPos[3];
 

out vec2 texUVf;

 
void main()
{
    gl_Position = gl_in[0].gl_Position;
    texUVf = texUV[0];
    EmitVertex();
	gl_Position = gl_in[1].gl_Position;
    texUVf = texUV[1];
    EmitVertex();
	gl_Position = gl_in[2].gl_Position;
    texUVf = texUV[2];
    EmitVertex();
	gl_Position = gl_in[0].gl_Position;
    texUVf = texUV[0];
    EmitVertex();
}