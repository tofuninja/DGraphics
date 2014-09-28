module graphics.mesh;
import math.matrix;
import graphics.Color;
import graphics.camera;
import graphics.Image;



public struct model
{
	// Rotation, translation and scaling are all handeled by the model matrix
	public mat4 modelMatrix;
	public mesh meshData;

	public this(mesh meshDat)
	{
		meshData = meshDat;
		modelMatrix = identity!4;
	}
}

public class mesh
{
	private vec3[] vectors;
	private Color[] colors;
	private vec3[] normals;
	private vec2[] texCords;
	private uvec3[] indices;

	private vec3 lowerBound;
	private vec3 upperBound;
	private vec3 center;

	private this()
	{
		// do nothing
	}

	this(vec3[] vecs, uvec3[] index)
	{
		this(vecs, index, Color(255,255,255,255));
	}

	this(vec3[] vecs, uvec3[] index, Color c)
	{
		vectors = vecs;
		indices = index;
		colors = new Color[vecs.length];
		colors[] = c;
		calcBounds();
	}

	private void calcBounds()
	{
		import std.algorithm;
		lowerBound = vectors[0];
		upperBound = vectors[0];
		foreach(vec3 v; vectors)
		{
			lowerBound.x = min(lowerBound.x, v.x);
			lowerBound.y = min(lowerBound.y, v.y);
			lowerBound.z = min(lowerBound.z, v.z);
			upperBound.x = max(upperBound.x, v.x);
			upperBound.y = max(upperBound.y, v.y);
			upperBound.z = max(upperBound.z, v.z);
		}

		center = (upperBound + lowerBound)/2.0f;
	}
}

/**
 * Cunstruct an axis aligned box
 */
public mesh boxMesh()
{
	vec3[] vecs = new vec3[8];
	vecs[0] = vec3(-1,-1,-1);
	vecs[1] = vec3( 1,-1,-1);
	vecs[2] = vec3( 1, 1,-1);
	vecs[3] = vec3(-1, 1,-1);
	vecs[4] = vec3(-1,-1, 1);
	vecs[5] = vec3( 1,-1, 1);
	vecs[6] = vec3( 1, 1, 1);
	vecs[7] = vec3(-1, 1, 1);

	uvec3[] index = new uvec3[6*2];

	index[0] = uvec3(0,1,2);
	index[1] = uvec3(2,3,0);
	index[2] = uvec3(1,5,2);
	index[3] = uvec3(2,5,6);
	index[4] = uvec3(3,2,7);
	index[5] = uvec3(7,2,6);
	index[6] = uvec3(0,3,4);
	index[7] = uvec3(3,7,4);
	index[8] = uvec3(0,4,1);
	index[9] = uvec3(1,4,5);
	index[10] = uvec3(4,7,5);
	index[11] = uvec3(5,7,6);
	return new mesh(vecs, index);
}

public void drawWireModel(Image img, model m, camera c)
{
	import graphics.render;
	auto mvp = c.projMatrix*c.viewMatrix*m.modelMatrix;

	foreach(uvec3 tri; m.meshData.indices)
	{
		vec4 p0;
		vec4 p1;
		vec4 p2;

		p0.xyz = m.meshData.vectors[tri[0]];
		p1.xyz = m.meshData.vectors[tri[1]];
		p2.xyz = m.meshData.vectors[tri[2]];

		p0.w = 1;
		p1.w = 1;
		p2.w = 1;

		p0 = mvp*p0;
		p1 = mvp*p1;
		p2 = mvp*p2;

		p0 = p0 / p0.w;
		p1 = p1 / p1.w;
		p2 = p2 / p2.w;

		auto size = vec2(img.Width, img.Height);
		size = size/2.0f;

		void plotLine(vec4 v0, vec4 v1, Color col)
		{
			if((v0.z > -1 && v0.z < 1) && (v1.z > -1 && v1.z < 1))
			{
				img.drawLine(v0.xy*size + size, v1.xy*size + size, col);
			}
		}

		plotLine(p0,p1,(m.meshData.colors !is null) ? m.meshData.colors[tri[0]] : Color(255,255,255,255));
		plotLine(p1,p2,(m.meshData.colors !is null)? m.meshData.colors[tri[1]] : Color(255,255,255,255));
		plotLine(p2,p0,(m.meshData.colors !is null) ? m.meshData.colors[tri[2]] : Color(255,255,255,255));
	}
}

void drawFrustrum(Image img, mat4 m, camera c)
{
	import graphics.render;
	vec3[8] vecs;
	vecs[0] = vec3(-1,-1,-1);
	vecs[1] = vec3( 1,-1,-1);
	vecs[2] = vec3( 1, 1,-1);
	vecs[3] = vec3(-1, 1,-1);
	vecs[4] = vec3(-1,-1, 1);
	vecs[5] = vec3( 1,-1, 1);
	vecs[6] = vec3( 1, 1, 1);
	vecs[7] = vec3(-1, 1, 1);
	
	uvec2[12] index;
	index[0] = uvec2(0,1);
	index[1] = uvec2(1,2);
	index[2] = uvec2(2,3);
	index[3] = uvec2(3,0);
	index[4] = uvec2(4,5);
	index[5] = uvec2(5,6);
	index[6] = uvec2(6,7);
	index[7] = uvec2(7,4);
	index[8] = uvec2(0,4);
	index[9] = uvec2(1,5);
	index[10] = uvec2(2,6);
	index[11] = uvec2(3,7);

	auto mvp = c.projMatrix*c.viewMatrix*(m.invert);
	
	foreach(uvec2 line; index)
	{
		vec4 p0;
		vec4 p1;
		p0.xyz = vecs[line[0]];
		p1.xyz = vecs[line[1]];
		
		p0.w = 1;
		p1.w = 1;
		
		p0 = mvp*p0;
		p1 = mvp*p1;
		
		p0 = p0 / p0.w;
		p1 = p1 / p1.w;
		
		auto size = vec2(img.Width, img.Height);
		size = size/2.0f;
		
		void plotLine(vec4 v0, vec4 v1, Color col)
		{
			if((v0.z > -1 && v0.z < 1) && (v1.z > -1 && v1.z < 1))
			{
				img.drawLine(v0.xy*size + size, v1.xy*size + size, col);
			}
		}
		
		plotLine(p0,p1, Color(255,255,255,255));
	}
}

public void setModelMatrix(ref model m,vec3 translation, vec3 rotation, vec3 scale)
{
	m.modelMatrix = translationMatrix(translation)*rotationMatrix(rotation)*scalingMatrix(scale);
}

mesh loadMesh(string file)
{
	import std.exception;
	import std.stdio;
	import math.conversion;


	char hasVerts;
	char hasCols;
	char hasNorms;
	char hasTexts;

	int vertsN;
	int trisN;
	vec3[] verts;
	vec3[] cols;
	vec3[] norms;
	vec2[] texCords;
	uvec3[] tris;

	auto f = File(file);

	// Grab vertex count
	f.rawRead(vertsN.toSlice); 

	// Read Header
	f.rawRead(hasVerts.toSlice);
	f.rawRead(hasCols.toSlice);
	f.rawRead(hasNorms.toSlice);
	f.rawRead(hasTexts.toSlice);

	enforce(hasVerts == 'y', "INTERNAL ERROR: there should always be vertex xyz data");

	// Reserve space
	verts = new vec3[vertsN];
	if(hasCols == 'y')cols = new vec3[vertsN];
	if(hasNorms == 'y') norms = new vec3[vertsN];
	if(hasTexts == 'y') texCords = new vec2[vertsN];

	// Read Data
	f.rawRead(verts);
	if(cols) f.rawRead(cols);
	if(norms) f.rawRead(norms);
	if(texCords) f.rawRead(texCords);

	// Read indicies 
	f.rawRead(trisN.toSlice);
	tris = new uvec3[trisN];
	f.rawRead(tris);

	// Convert Colors
	Color[] colsConverted;
	if(cols)
	{
		colsConverted = new Color[vertsN];

		for(int i = 0; i < vertsN; i++)
		{
			vec4 c;
			c.xyz = cols[i];
			c.w = 1;
			colsConverted[i] = (c*255).to!Color;
		}
	}

	// Set up rtn
	mesh rtn = new mesh();
	rtn.vectors = verts;
	rtn.colors = colsConverted;
	rtn.normals = norms;
	rtn.texCords = texCords;
	rtn.indices = tris;
	rtn.calcBounds();

	static if(false)
	{
		writeln("VertCount:",vertsN);
		writeln("HasVerts:",hasVerts);
		writeln("HasCols:",hasCols);
		writeln("HasNorms:",hasNorms);
		writeln("HasTextCords:",hasTexts);

		writeln("Center:",rtn.center);
		writeln("LowerBound:",rtn.lowerBound);
		writeln("UpperBound:",rtn.upperBound);
	}
	return rtn;
}

void normilize(mesh m)
{
	auto size = (m.upperBound - m.lowerBound)/2;
	for(int i = 0; i < m.vectors.length; i++)
	{
		m.vectors[i] = (m.vectors[i] - m.center)/size;
	}
	m.center = vec3(0,0,0);
	m.lowerBound = vec3(-1,-1,-1);
	m.lowerBound = vec3(1,1,1);
}