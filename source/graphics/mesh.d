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
	private ivec3[] indices;
	private vec3 lowerBound;
	private vec3 upperBound;
	private vec3 center;

	this(vec3[] vecs, ivec3[] index)
	{
		this(vecs, index, Color(255,255,255,255));
	}

	this(vec3[] vecs, ivec3[] index, Color c)
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

		center = (upperBound - lowerBound)/2.0f;
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

	ivec3[] index = new ivec3[6*2];

	index[0] = ivec3(0,1,2);
	index[1] = ivec3(2,3,0);
	index[2] = ivec3(1,5,2);
	index[3] = ivec3(2,5,6);
	index[4] = ivec3(3,2,7);
	index[5] = ivec3(7,2,6);
	index[6] = ivec3(0,3,4);
	index[7] = ivec3(3,7,4);
	index[8] = ivec3(0,4,1);
	index[9] = ivec3(1,4,5);
	index[10] = ivec3(4,7,5);
	index[11] = ivec3(5,7,6);
	return new mesh(vecs, index);
}

public void drawWireModel(Image img, model m, camera c)
{
	import graphics.render;
	auto mvp = c.viewMatrix*c.projMatrix*m.modelMatrix;

	foreach(ivec3 tri; m.meshData.indices)
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
		size = size/2;

		void plotLine(vec4 v0, vec4 v1, Color col)
		{
			if((v0.z > -1 && v0.z < 1) || (v1.z > -1 && v1.z < 1))
			{
				img.drawLine(v0.xy*size + size, v1.xy*size + size, col);
			}
		}

		plotLine(p0,p1,m.meshData.colors[tri[0]]);
		plotLine(p1,p2,m.meshData.colors[tri[1]]);
		plotLine(p2,p0,m.meshData.colors[tri[2]]);
	}
}

public void setModelMatrix(ref model m,vec3 translation, vec3 rotation, vec3 scale)
{
	m.modelMatrix = translationMatrix(translation)*rotationMatrix(rotation)*scalingMatrix(scale);
}