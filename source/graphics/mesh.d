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
	public Image texture; 

	public this(mesh meshDat)
	{
		meshData = meshDat;
		modelMatrix = identity!4;
		texture = null;
	}

	public this(mesh meshDat, Image tex)
	{
		this(meshDat);
		texture = tex;
	}
}

public class mesh
{
	public vec3[] vectors;
	public Color[] colors;
	public vec3[] vcolors;
	public vec3[] normals;
	public vec2[] texCords;
	public uvec3[] indices;

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
	vecs[0] = vec3(-1, 1, 1);
	vecs[1] = vec3( 1, 1, 1);
	vecs[2] = vec3(-1,-1, 1);
	vecs[3] = vec3( 1,-1, 1);
	vecs[4] = vec3(-1, 1,-1);
	vecs[5] = vec3( 1, 1,-1);
	vecs[6] = vec3(-1,-1,-1);
	vecs[7] = vec3( 1,-1,-1);

	uvec3[] index = new uvec3[6*2];

	index[0] = uvec3(0,2,3);
	index[1] = uvec3(3,1,0);
	index[2] = uvec3(1,3,7);
	index[3] = uvec3(7,5,1);
	index[4] = uvec3(0,1,5);
	index[5] = uvec3(5,4,0);
	index[6] = uvec3(7,4,5);
	index[7] = uvec3(7,6,4);
	index[8] = uvec3(4,6,0);
	index[9] = uvec3(6,2,0);
	index[10] = uvec3(6,7,2);
	index[11] = uvec3(2,7,3);
	mesh m = new mesh(vecs, index);

	vec3[] norms = new vec3[8];
	for(int i = 0; i < 8; i++)
	{
		norms[i] = normalize(vecs[i]);
	}
	m.normals = norms;

	Color[] cols = new Color[8];
	cols[] = Color(255,255,255,255);
	m.colors = cols;

	vec3[] vcols = new vec3[8];
	vcols[] = vec3(1,1,1);
	m.vcolors = vcols;

	enum scale = 1;
	vec2[] uvArr = new vec2[8];
	uvArr[0] = vec2(0,0);
	uvArr[1] = vec2(scale,0);
	uvArr[2] = vec2(0,scale);
	uvArr[3] = vec2(scale,scale);
	uvArr[4] = vec2(scale,scale);
	uvArr[5] = vec2(0,scale);
	uvArr[6] = vec2(scale,0);
	uvArr[7] = vec2(0,0);

	m.texCords = uvArr;

	return m;
}

public mesh sphereMesh()
{
	import std.math;
	enum rowCount = 10;
	enum rowRes = 10;
	enum twoPi = PI*2;

	int pointCount = (rowRes)*(rowCount - 2) + 2;
	int triCount = 2*rowRes*(rowCount - 2);

	vec3[] vecs = new vec3[pointCount];
	uvec3[] index = new uvec3[triCount];

	// Generate points
	int k = 0;
	for(float i = 0; i < rowCount; i++)
	{

		for(float j = 0; j < rowRes; j++)
		{
			vecs[k] = vec3(sin((j/rowRes)*twoPi)*sin((i/(rowCount - 1))*PI), cos((i/(rowCount - 1))*PI), cos((j/rowRes)*twoPi)*sin((i/(rowCount - 1))*PI));
			k++;
			if(i == 0 || i == rowCount - 1) break;
		}
	}

	// Connect points into tris
	k = 0;
	for(int i = 0; i < rowRes; i++)
	{
		index[k] = uvec3(0, i + 1, (i + 1)%rowRes + 1); 
		k++;
	}

	for(int i = 1; i < rowCount - 2; i++)
	{
		for(int j = 0; j < rowRes; j++)
		{
			uint  p0 = (i - 1)*rowRes + 1 + j;
			uint  p1 = (i - 1)*rowRes + 1 + (j + 1)%rowRes;
			uint  p2 = i*rowRes + 1 + j;
			uint  p3 = i*rowRes + 1 + (j + 1)%rowRes;

			index[k] = uvec3(p0,p1,p2);
			index[k + 1] = uvec3(p2,p1,p3);
			k += 2;
		}
	}

	for(int i = 0; i < rowRes; i++)
	{
		index[k] = uvec3(pointCount - 1,pointCount - i - 2, pointCount - (i + 1)%rowRes - 2); 
		k++;
	}

	return new mesh(vecs, index);
}


mesh cylinderMesh()
{
	import std.math;
	enum rowRes = 10;
	enum twoPi = PI*2;
	int pointCount = rowRes*2 + 2;
	int triCount = 4*rowRes;

	vec3[] vecs = new vec3[pointCount];
	uvec3[] index = new uvec3[triCount];
	
	// Generate points
	int k = 1;
	vecs[0] = vec3(0,1,0);
	for(float i = 0; i < 2; i++)
	{
		for(float j = 0; j < rowRes; j++)
		{
			vecs[k] = vec3(sin((j/rowRes)*twoPi), 1 - (i*2), cos((j/rowRes)*twoPi));
			k++;
		}
	}
	vecs[k] = vec3(0,-1,0);

	// Connect points into tris
	k = 0;
	for(int i = 0; i < rowRes; i++)
	{
		index[k] = uvec3(0, i + 1, (i + 1)%rowRes + 1); 
		k++;
	}

	for(int j = 0; j < rowRes; j++)
	{
		int i = 1;
		uint  p0 = (i - 1)*rowRes + 1 + j;
		uint  p1 = (i - 1)*rowRes + 1 + (j + 1)%rowRes;
		uint  p2 = i*rowRes + 1 + j;
		uint  p3 = i*rowRes + 1 + (j + 1)%rowRes;
		
		index[k] = uvec3(p0,p1,p2);
		index[k + 1] = uvec3(p2,p1,p3);
		k += 2;
	}
	
	for(int i = 0; i < rowRes; i++)
	{
		index[k] = uvec3(pointCount - 1,pointCount - i - 2, pointCount - (i + 1)%rowRes - 2); 
		k++;
	}

	return new mesh(vecs, index);
}

// Replaced by runShader
/*
public void draw(alias vertShader, alias pixShader)(Image img, model m, camera c, light l)
{
	import graphics.render;
	auto mm = m.modelMatrix;
	auto vp = c.projMatrix*c.viewMatrix;
	
	// No conectivity data, just render as a point cloud 
	if(m.meshData.indices is null)
	{
		drawPoints(img, m, c);
		return;
	}
	
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

		p0 = mm*p0;
		p1 = mm*p1;
		p2 = mm*p2;

		Color c1,c2,c3;

		if(l.mode == 1 && m.meshData.normals !is null)
		{
			import std.algorithm;
			c1 = /*l.col*l.amb +* / l.col*min(1,l.dif*max(0,dot(m.meshData.normals[tri[0]], p0.xyz - l.loc)));
			c2 = /*l.col*l.amb +* / l.col*min(1,l.dif*max(0,dot(m.meshData.normals[tri[1]], p1.xyz - l.loc)));
			c3 = /*l.col*l.amb +* / l.col*min(1,l.dif*max(0,dot(m.meshData.normals[tri[2]], p2.xyz - l.loc)));
		}
		
		p0 = vp*p0;
		p1 = vp*p1;
		p2 = vp*p2;
		
		p0 = p0 / p0.w;
		p1 = p1 / p1.w;
		p2 = p2 / p2.w;
		
		auto size = vec2(img.Width, img.Height);
		size = size/2.0f;

		/*
		void plotTri(vec4 v0, vec4 v1, vec4 v2, Color col)
		{

		}

		plotLine(p0,p1,(m.meshData.colors !is null) ? m.meshData.colors[tri[0]] : Color(255,255,255,255));
		plotLine(p1,p2,(m.meshData.colors !is null)? m.meshData.colors[tri[1]] : Color(255,255,255,255));
		plotLine(p2,p0,(m.meshData.colors !is null) ? m.meshData.colors[tri[2]] : Color(255,255,255,255));
		* /

		import util.debugger;
		import std.stdio;


		if((p0.z > -1 && p0.z < 1) && (p1.z > -1 && p1.z < 1) && (p2.z > -1 && p2.z < 1))
		{
			//img.drawLine(v0.xy*size + size, v1.xy*size + size, col);
			vec3 A = p0.xyz;
			vec3 B = p1.xyz;
			vec3 C = p2.xyz;
			A.xy = A.xy*size + size;
			B.xy = B.xy*size + size;
			C.xy = C.xy*size + size;
			foreach(vec3 point, vec3 p; triangleRaster3D(A, B, C))
			{
				Color col = Color(255,255,255,255);
				if(l.mode == 0)
				{
					if(m.meshData.colors !is null) col = m.meshData.colors[tri[0]]*p.x + m.meshData.colors[tri[1]]*p.y + m.meshData.colors[tri[2]]*p.z;
				}
				else if(l.mode == 1)
				{
					col = Color(cast(byte)(255*(point.z + 2)),0,0);//c1*p.x + c2*p.y + c3*p.z;
				}
				//writeln(point.z);
				//breakPoint();
				img[point] = col;
			}
		}
	}
}
*/

public void drawWireModel(Image img, model m, camera c)
{
	import graphics.render;
	auto mvp = c.projMatrix*c.viewMatrix*m.modelMatrix;

	// No conectivity data, just render as a point cloud 
	if(m.meshData.indices is null)
	{
		drawPoints(img, m, c);
		return;
	}

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
				//img.drawLine(v0.xy*size + size, v1.xy*size + size, col);
				vec3 s = v0.xyz;
				vec3 e = v1.xyz;
				s.xy = s.xy*size + size;
				e.xy = e.xy*size + size;
				foreach(vec3 point, float percent; lineRaster3D(s, e))
				{
					img[point] = col;
				}
			}
		}

		plotLine(p0,p1,(m.meshData.colors !is null) ? m.meshData.colors[tri[0]] : Color(255,255,255,255));
		plotLine(p1,p2,(m.meshData.colors !is null)? m.meshData.colors[tri[1]] : Color(255,255,255,255));
		plotLine(p2,p0,(m.meshData.colors !is null) ? m.meshData.colors[tri[2]] : Color(255,255,255,255));
	}
}

public void drawPoints(Image img, model m, camera c)
{
	auto mvp = c.projMatrix*c.viewMatrix*m.modelMatrix;
	for(int i = 0; i < m.meshData.vectors.length; i++)
	{
		auto v = m.meshData.vectors[i];
		vec4 p0;

		p0.xyz = v;
		p0.w = 1;
		p0 = mvp*p0;
		p0 = p0 / p0.w;

		img[p0.xyz] = (m.meshData.colors !is null) ? m.meshData.colors[i] : Color(255,255,255,255);
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
				//img.drawLine(v0.xy*size + size, v1.xy*size + size, col);
				vec3 s = v0.xyz;
				vec3 e = v1.xyz;
				s.xy = s.xy*size + size;
				e.xy = e.xy*size + size;
				foreach(vec3 point, float percent; lineRaster3D(s, e))
				{
					img[point] = col;
				}
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
	rtn.vcolors = cols;
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