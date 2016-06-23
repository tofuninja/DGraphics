module graphics.render.line3Batch;
import math.matrix;
import math.geo.rectangle;
import graphics.hw;
import graphics.color;
import graphics.render.batcher;
import graphics.render.sceneuniforms;


private hwBufferRef tri;
private hwVaoRef vao;
private hwShaderRef shade;
private bool inited = false;

import std.stdio;

private void init() {
	if(inited) return;
	assert(hwState().initialized); 
	
	// Create vertex buffer
	{
		auto info 		= hwBufferCreateInfo();
		info.size 		= (vector.sizeof)*size;
		info.dynamic 	= true;
		info.data 		= null;
		tri 			= hwCreate(info);
	}

	// Create VAO
	{
		hwVaoCreateInfo info;
		info.hwRegisterAttachments!(vector)(0,0);
		//info.bindPointDivisors[0] = 1;
		vao = hwCreate(info);
	}
	
	// Create Shader
	{
		string vert = ` 
			#version 440

			layout(std140, binding = 0) uniform sceneUniforms
			{
				mat4 projection;
				vec4 size;
			};
			
			layout(location = 0) in vec3 vert_start;
			layout(location = 1) in vec3 vert_end;
			layout(location = 2) in vec3 vert_color;

			out vec4 geo_start;
			out vec4 geo_end;

			out vec3 geo_world_start;
			out vec3 geo_world_end;

			out vec3 geo_color;

			void main() {
				geo_world_start = vert_start;
				geo_world_end   = vert_end;

				geo_start = projection*vec4(vert_start, 1);
				geo_end   = projection*vec4(vert_end  , 1);
				geo_color = vert_color;
				gl_Position = vec4(0,0,0,0); // dont care what this is set to
			}`;

		string geo = `
			#version 330
			layout(points) in;
			layout (line_strip, max_vertices=2) out;
			 
			in vec4 geo_start[1];
			in vec4 geo_end[1];

			in vec3 geo_world_start[1];
			in vec3 geo_world_end[1];

			in vec3 geo_color[1];
			out vec3 frag_color;
			out vec3 frag_world_pos;

			void main() {
				gl_Position = geo_start[0];
				frag_color = geo_color[0];
				frag_world_pos = geo_world_start[0];
				EmitVertex();

				gl_Position = geo_end[0];
				frag_color = geo_color[0];
				frag_world_pos = geo_world_end[0];
				EmitVertex();
			}`;
		
		string frag = `
			#version 420	
			in vec3 frag_color;
			in vec3 frag_world_pos;
			layout(location = 0) out vec3 outColor;
			layout(location = 1) out vec3 outNormal;
			layout(location = 2) out vec3 outWorldPos;
			layout(location = 3) out uvec4 outId;
			void main() {
				outColor = frag_color;
				outNormal = vec3(0,0,0);
				outWorldPos = frag_world_pos;
				outId = uvec4(0,0,0,1);
			}
			`;
		hwShaderCreateInfo info;
		info.vertShader = vert;
		info.geomShader = geo;
		info.fragShader = frag;
		shade = hwCreate(info);
	}
	
	inited = true;
}

enum size = 512;
private struct vector
{
	@hwAttachmentLocation(0) vec3 start;
	@hwAttachmentLocation(1) vec3 end;
	@hwAttachmentLocation(2) vec3 color;
}

private struct lines
{
	bool never_remove = false;
	uint count_unused = 0;
	uint count = 0;
	vector[size] data;
	bool shouldRemove() {
		return count_unused > 10 && !never_remove;
	}

	void run() {
		if(count == 0) {
			count_unused++;
			return;
		}

		hwBufferSubDataInfo sub;
		sub.data = data[0..count];
		sub.offset = 0;
		tri.subData(sub);

		hwDrawCommand draw;
		draw.vertexCount = count;
		hwCmd(draw);

		count = 0;
	}

	void add(vector v) {
		data[count] = v;
		count++;
	}
}

struct Line3Batcher
{
	import container.clist;
	private CList!lines lineList;

	void drawLine(vec3 start, vec3 end, vec3 color) {
		if(lineList.length == 0) {
			lines l;
			l.never_remove = true;
			lineList.insert(l);
		}

		if(lineList.peekFront.count >= size) {
			if(lineList.peekBack.count < size) lineList.rotateForward();
			else lineList.insertFront(lines());
		}

		lineList.peekFront.add(vector(start, end, color));
	}

	void run(iRectangle viewport, hwFboRef fbo) {
		init();
		hwRenderStateInfo state;
		state.mode = hwRenderMode.points; 
		state.vao = vao;
		state.shader = shade;
		state.viewport = viewport;
		state.fbo = fbo;
		state.depthTest = true;
		state.depthFunction = hwCmpFunc.less;
		//state.backFaceCulling = true;
		//state.frontOrientation = hwFrontFaceMode.clockwise;
		hwCmd(state);
		
		hwVboCommand bind0;
		bind0.location = 0;
		bind0.vbo = tri;
		bind0.stride = vector.sizeof;
		hwCmd(bind0);

		//uniforms.bind(0);

		foreach(ref l; lineList) {
			l.run();
		}

		lineList.removePred!(a => a.shouldRemove())();
	}
}

