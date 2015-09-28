//module generation.map;
//
//import std.random;
//import std.stdio;
//
//import math.noise.perlin;
//import math.noise.poissondisk;
//import math.matrix;
//import math.interpolate;
//import math.geo.AABox;
//import math.geo.frustum;
//import graphics.image;
//import graphics.camera;
//import graphics.mesh;
//import graphics.color;
//import graphics.frameBuffer;
//import graphics.hw.shader;
//import graphics.hw.buffer;
//import graphics.hw.renderTarget;
//import graphics.hw.texture;
//import graphics.hw.state;
//import resources.glslManager;
//
//
//class mapGenerator
//{
//private:
//	alias shade = terain_shader;
//	float[] terain;
//	float[] water;
//	float[] noise;
//	float[] grass;
//	float[] clouds;
//	int treeCount = 0;
//	interpolate2d terainInterp;
//	model plane;
//	model wat;
//	model tree;
//	model cloudPlane;
//	model wireMod;
//	bool inited = false;
//	VertexBuffer!vec3 treepos;
//	VertexBuffer!vec3 treescale;
//	frustum camFrus;
//
//	int chunkCount = 0;
//
//
//public: //settings
//	int terainSeed = 0;
//
//	int terainSize = 1000;
//	int terainOctCount = 10;
//	int terainBaseSize = 5;
//	int terainMtnOctCount = 5;
//	int terainMtnBaseSize = 10;
//	float terainBaseScale = 1.0f;
//	float terainMtnScale = 0.1f;
//
//	int grassSize = 200;
//	int grassOctCount = 4;
//	int grassBaseSize = 5;
//
//	int waterSize = 5000;
//	float waterHeight = 0.47f;
//	int riverCount = 40;
//	int riverLength = 10000;
//
//	float treeDist = 0.001f;
//	int noiseSize = 200;
//
//	int cloudSize = 200;
//	int cloudOctCount = 4;
//	int cloudBaseSize = 5;
//	float cloudHeight = 1.0f;
//
//	float snowTop = 0.6f;
//
//	bool renderWire = false;
//	bool render_Trees = true;
//	bool render_Clouds = true;
//
//	public void gen()
//	{
//		infoln("\n\n**** Generating Map ****");
//		generateTerain(terainSeed, terainSize);
//		generateGrass();
//		waterFlow();
//		generateNoise();
//		generatePlants();
//		generateClouds();
//		infoln("\nCompleate\n");
//	}
//
//
//	public void generateTerain(int seed, int size)
//	{
//		infoln("Generating Terain");
//		infoln("\tBase Terain");
//		auto pn = perlinNoise(seed,terainOctCount,terainBaseSize,0.5);
//		terain = pn.flatten(size);
//		terain[] = terainBaseScale*(terain[]+1.0f)/2.0f ;
//
//		infoln("\tMountains");
//		auto mtns = perlinNoise(seed+1,terainMtnOctCount,terainMtnBaseSize,0.5f);
//		auto mtnsF = mtns.flattenRidged(size);
//		mtnsF[] = terainMtnScale*(mtnsF[]+1.0f)/2.0f ;
//		terain[] += mtnsF[];
//
//		infoln("\tEdge CutOff");
//		enum iSize = 6;
//		float[iSize*iSize] island;
//		island[] = 1.0f;
//		for(int i = 0; i < iSize; i++) island[(0)*iSize + (i)] = 0.0f;
//		for(int i = 0; i < iSize; i++) island[(iSize-1)*iSize + (i)] = 0.0f;
//		for(int i = 0; i < iSize; i++) island[(i)*iSize + (0)] = 0.0f;
//		for(int i = 0; i < iSize; i++) island[(i)*iSize + (iSize-1)] = 0.0f;
//		auto islandInterp = interpolate2d(iSize,island);
//		auto islandF = islandInterp.flatten(size);
//		terain[] *= islandF[];
//
//		terainInterp = interpolate2d(size, terain);
//
//		if(TextureBindPoints[1].boundTex !is null)
//		{
//			auto t = TextureBindPoints[1].boundTex;
//			TextureBindPoints[1].unbind();
//			t.destroy();
//		}
//		Texture perlinTex = new Texture(terainSize, terainSize, terain.ptr, TextureType.RED_FLOAT, false);
//		TextureBindPoints[1].bind(perlinTex);
//	}
//
//	public void generateGrass()
//	{
//		infoln("Generating Grass");
//		auto pnGrass = perlinNoise(terainSeed+3,grassOctCount,grassBaseSize,0.5);
//		grass = pnGrass.flatten(grassSize);
//		grass[] = (grass[]+1.0f)/2.0f ;
//
//		if(TextureBindPoints[5].boundTex !is null)
//		{
//			auto t = TextureBindPoints[5].boundTex;
//			TextureBindPoints[5].unbind();
//			t.destroy();
//		}
//		Texture grassTex = new Texture(grassSize, grassSize, grass.ptr, TextureType.RED_FLOAT, false);
//		TextureBindPoints[5].bind(grassTex);
//	}
//
//	public void waterFlow()
//	{
//		infoln("Generating Water");
//		water = new float[waterSize*waterSize];
//		water[] = 0;
//
//		auto rnd = rndGen();
//		rnd.seed(terainSeed);
//
//		ivec2 nearestNotWater(ivec2 loc)
//		{
//			for(int size = 0; size < 100; size++)
//			{
//				float lh = 10000;
//				ivec2 r;
//				for(int i = -size; i <= size; i++) 
//				{
//					auto nl = loc + ivec2(i, -size);
//					float fx = nl.x/(cast(float)waterSize);
//					float fy = nl.y/(cast(float)waterSize);
//					float h = terainInterp.get(fx, fy);
//					if(water[(nl.x)*waterSize + (nl.y)] != 1 && h < lh) 
//					{
//						lh = h;
//						r = nl;
//					}
//				}
//
//				for(int i = -size; i <= size; i++) 
//				{
//					auto nl = loc + ivec2(i, size);
//					float fx = nl.x/(cast(float)waterSize);
//					float fy = nl.y/(cast(float)waterSize);
//					float h = terainInterp.get(fx, fy);
//					if(water[(nl.x)*waterSize + (nl.y)] != 1 && h < lh) 
//					{
//						lh = h;
//						r = nl;
//					}
//				}
//
//				for(int i = -size; i <= size; i++) 
//				{
//					auto nl = loc + ivec2(-size, i);
//					float fx = nl.x/(cast(float)waterSize);
//					float fy = nl.y/(cast(float)waterSize);
//					float h = terainInterp.get(fx, fy);
//					if(water[(nl.x)*waterSize + (nl.y)] != 1 && h < lh) 
//					{
//						lh = h;
//						r = nl;
//					}
//				}
//
//				for(int i = -size; i <= size; i++) 
//				{
//					auto nl = loc + ivec2(size, i);
//					float fx = nl.x/(cast(float)waterSize);
//					float fy = nl.y/(cast(float)waterSize);
//					float h = terainInterp.get(fx, fy);
//					if(water[(nl.x)*waterSize + (nl.y)] != 1 && h < lh) 
//					{
//						lh = h;
//						r = nl;
//					}
//				}
//
//				if(lh < 10000)
//				{
//					return r;
//				}
//			}
//			return loc;
//		}
//
//		void applyRain(float x, float y)
//		{
//			import std.math;
//			auto l = ivec2(cast(int)(x*waterSize), cast(int)(y*waterSize));
//			for(int ijkl = 0; ijkl < riverLength; ijkl++)
//			{
//				if(l.x < 0 || l.y < 0 || l.x >= waterSize || l.y >= waterSize) break;
//				water[l.x*waterSize + l.y] = 1;
//				auto nl = nearestNotWater(l);
//				if(nl == l) break;
//				float fx = nl.x/(cast(float)waterSize);
//				float fy = nl.y/(cast(float)waterSize);
//				float h = terainInterp.get(fx, fy);
//				if(h < waterHeight) break;
//				l = nl;
//			}
//		}
//
//		infoln("\tRivers&Lakes");
//		int tryCount = 0;
//		for(int i = 0; i < riverCount; i++)
//		{
//			if(tryCount > 500) break;
//			auto fx = cast(float)((cast(double)rnd.front)/uint.max);
//			rnd.popFront();
//			auto fy = cast(float)((cast(double)rnd.front)/uint.max);
//			rnd.popFront();
//			float h = terainInterp.get(fx, fy);
//			if(h<0.5)
//			{
//				tryCount++;
//				i--;
//				continue;
//			}
//			applyRain(fx,fy);
//			applyRain(fx,fy);
//			applyRain(fx,fy);
//			tryCount = 0;
//		}
//		/*
//		infoln("\tOceans");
//		for(int i = 0; i < waterSize; i++)
//		{
//			for(int j = 0; j < waterSize; j++)
//			{
//				float fx = i/(cast(float)waterSize);
//				float fy = j/(cast(float)waterSize);
//				auto h = terainInterp.get(fx, fy);
//				if(h < waterHeight) water[i*waterSize + j] = 1;
//			}
//		}*/
//
//		if(TextureBindPoints[3].boundTex !is null)
//		{
//			auto t = TextureBindPoints[3].boundTex;
//			TextureBindPoints[3].unbind();
//			t.destroy();
//		}
//
//		Texture waterTex = new Texture(waterSize, waterSize, water.ptr, TextureType.RED_FLOAT, false);
//		TextureBindPoints[3].bind(waterTex);
//
//
//	}
//
//
//
//	public void generateNoise()
//	{
//		infoln("Generating White Noise");
//		auto rnd = rndGen();
//		rnd.seed(terainSeed);
//		
//		noise = new float[noiseSize*noiseSize];
//		for(int j = 0; j < noiseSize*noiseSize; j++)
//		{
//			noise[j] = cast(float)((cast(double)rnd.front)/uint.max);
//			rnd.popFront();
//		}
//
//		if(TextureBindPoints[4].boundTex !is null)
//		{
//			auto t = TextureBindPoints[4].boundTex;
//			TextureBindPoints[4].unbind();
//			t.destroy();
//		}
//		Texture noiseTex = new Texture(noiseSize, noiseSize, noise.ptr, TextureType.RED_FLOAT, false);
//		TextureBindPoints[4].bind(noiseTex);
//	}
//
//	public void generatePlants()
//	{
//		import std.container;
//		import std.array;
//
//
//		infoln("Generating Plants");
//
//		infoln("\tTrees");
//		auto treeList = SList!treeDat();
//		vec2[] pdat = pDisk(terainSeed, 1, treeDist);
//		auto treeDist = perlinNoise(terainSeed+3,grassOctCount,grassBaseSize,0.5);
//		auto rnd = rndGen();
//		rnd.seed(terainSeed);
//
//		/*
//		enum pimgSize = 3000;
//		Image pimg = new Image(pimgSize,pimgSize);
//
//		for(int i = 0; i < pimgSize; i++)
//		{
//			for(int j = 0; j < pimgSize; j++)
//			{
//				float h = 1;
//				ubyte p = cast(ubyte)(h*255);
//				auto c = Color(p,p,p);
//				pimg[i,j] = c;
//			}
//		}
//		*/
//		
//
//
//
//
//		auto waterInterp = interpolate2d(waterSize, water);
//
//		for(int i = 0; i < pdat.length; i++)
//		{
//			vec2 p = pdat[i];
//			float r = cast(float)((cast(double)rnd.front)/uint.max)*2.0f - 1.0f;
//			rnd.popFront();
//
//			float h = treeDist.get(p.x, p.y);
//			float th = terainInterp.get(p.x, p.y);
//			float incline = terainInterp.getFlow(p.x, p.y).length();
//			if(r*0.7f > -h && waterInterp.get(p.x,p.y) < 0.1f && th > waterHeight && !(incline > 0.001f))
//			{
//				treeDat t = treeDat(vec3(p.y, th, p.x));
//				treeList.insert(t);
//
//				//vec2 p = pdat[i];
//				/*
//				int x = cast(int)(p.x*pimgSize);
//				int y = cast(int)(p.y*pimgSize);
//				auto c = Color(0,0,0);
//				pimg[x,y] = c;
//				*/
//			}
//		}
//
//		//pimg.saveImage("treesDist.png");
//
//		auto trees = array(treeList[]);
//		vec3[] pos = new vec3[trees.length];
//		vec3[] scale = new vec3[trees.length];
//		for(int i = 0; i < pos.length; i++)
//		{
//			float r = cast(float)((cast(double)rnd.front)/uint.max)+ 1.0f;
//			rnd.popFront();
//
//			auto t = trees[i];
//			auto p = t.loc*vec3(60,20,60) - vec3(30,0,30);
//			auto size = vec3(0.05f,0.1f,0.05f)*r;
//			p.y += size.y;
//
//			pos[i] = p;//modelMatrix(p, vec3(0,0,0), size);
//			scale[i] = size;
//		}
//
//
//		treepos.setData(pos);
//		treescale.setData(scale);
//
//		treeCount = trees.length;
//		infoln("\t(count = ", treeCount, ")");
//	}
//
//	public void generateClouds()
//	{
//		infoln("Generating Clouds");
//		auto cloadPN = perlinNoise(terainSeed+7,cloudOctCount,cloudBaseSize,0.5);
//		clouds = cloadPN.flatten(cloudSize);
//		clouds[] = (clouds[]+1.0f)/2.0f ;
//
//		if(TextureBindPoints[6].boundTex !is null)
//		{
//			auto t = TextureBindPoints[6].boundTex;
//			TextureBindPoints[6].unbind();
//			t.destroy();
//		}
//		Texture cloudTex = new Texture(cloudSize, cloudSize, clouds.ptr, TextureType.RED_FLOAT, false);
//		TextureBindPoints[6].bind(cloudTex);
//	}
//
//
//	public void init()
//	{
//		// Create a box mesh and a shader input for it.
//		auto b_mesh = tesPlane(100);
//		auto cone_mesh = coneMesh(6);
//		
//		//auto b_mesh = loadMesh("geo/box.bin");
//
//		ShaderInput box = new ShaderInput(shade.program);
//		ShaderInput wireF = new ShaderInput(terain_wire_shader.program);
//		ShaderInput water = new ShaderInput(water_fade.program);
//		ShaderInput treeInput = new ShaderInput(tree_shader.program);
//		ShaderInput cloudInput = new ShaderInput(cloud_plane_shader.program);
//
//		treepos = new VertexBuffer!vec3("translate");
//		treescale = new VertexBuffer!vec3("scale");
//
//		box.attachMesh(b_mesh);
//		wireF.attachMesh(b_mesh);
//		water.attachMesh(b_mesh);
//		treeInput.attachMesh(cone_mesh);
//		treeInput.attachBufferDiv(treepos,  1);
//		treeInput.attachBufferDiv(treescale,  1);
//		cloudInput.attachMesh(b_mesh);
//
//		plane = model(box);
//		wireMod = model(wireF);
//		wat = model(water);
//		tree = model(treeInput);
//		cloudPlane = model(cloudInput);
//		
//		plane.setModelMatrix(vec3(0,0,0),vec3(0,0,0), vec3(30,20,30));
//		wat.setModelMatrix(vec3(0,7,0),vec3(0,0,0), vec3(30,30,30));
//		tree.setModelMatrix(vec3(0,40,0),vec3(0,0,0), vec3(30,30,30));
//		
//		// Add models to model list 
//		
//		shade.program.setUniform("text", TextureBindPoints[1]);
//		shade.program.setUniform("watertext", TextureBindPoints[3]);
//		shade.program.setUniform("noisetext", TextureBindPoints[4]);
//		shade.program.setUniform("grass", TextureBindPoints[5]);
//		shade.program.setUniform("cloud", TextureBindPoints[6]);
//
//		terain_wire_shader.program.setUniform("text", TextureBindPoints[1]);
//
//		tree_shader.program.setUniform("noisetext", TextureBindPoints[4]);
//		tree_shader.program.setUniform("grass", TextureBindPoints[5]); 
//		tree_shader.program.setUniform("cloud", TextureBindPoints[6]);
//
//		cloud_plane_shader.program.setUniform("cloud", TextureBindPoints[6]);
//
//
//		Texture waterTex = new Texture(loadImage("water.jpg"), TextureType.RGBA);
//		TextureBindPoints[2].bind(waterTex);
//		simple_texture.program.setUniform("text", TextureBindPoints[2]);
//
//
//		inited = true;
//	}
//
//	public void draw(camera cam, float dt, float t)
//	{
//		if(inited == false) return;
//
//		camFrus = frustum(cam.projMatrix*cam.viewMatrix);
//		chunkCount = 0;
//
//		shade.program.setUniform("time", t);
//		shade.program.setUniform("snowTop", snowTop);
//		shade.program.setUniform("waterHeight", waterHeight);
//		terain_wire_shader.program.setUniform("waterHeight", waterHeight);
//		tree_shader.program.setUniform("time", t);
//		tree_shader.program.setUniform("snowTop", snowTop);
//		cloud_plane_shader.program.setUniform("time", t);
//
//		renderTerain(0,0,1,1,20, cam);
//		if(render_Trees) renderTrees(cam);
//
//		wat.setModelMatrix(vec3(0,waterHeight*19,0),vec3(0,0,0), vec3(300,1,300));
//		wat.shaderInput.program.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*wat.modelMatrix));
//		wat.shaderInput.program.setUniform("mMat", wat.modelMatrix);
//		wat.shaderInput.draw();
//
//		if(render_Clouds) renderClouds(cam);
//	}
//
//	private void renderTerain(float x, float y, float w, float h, float th, camera cam, int recurs = 0)
//	{
//		import std.algorithm;
//		float splitDist = w*120;
//
//		float pointDist(float px, float py)
//		{
//			auto fx = x + px*w;
//			auto fy = y + py*h;
//
//			float centerZ = terainInterp.get(fx, fy)*th;
//			auto center = vec3(x*60 - (1-w)*30 + w*30*(px*2.0f - 1.0f), centerZ, y*60 - (1-h)*30 + h*30*(py*2.0f - 1.0f));
//
//			return (cam.eye - center).length();
//		}
//
//		auto dist = pointDist(0.5f,0.5f);
//		dist = min(dist, pointDist(0,0));
//		dist = min(dist, pointDist(1,0));
//		dist = min(dist, pointDist(0,1));
//		dist = min(dist, pointDist(1,1));
//
//		if(dist < splitDist && recurs < 5)
//		{
//			recurs++;
//			auto hw = w/2.0f;
//			auto hh = h/2.0f;
//			auto cx = x + hw;
//			auto cy = y + hh;
//			renderTerain(  x,  y, hw, hh, th, cam, recurs);
//			renderTerain( cx,  y, hw, hh, th, cam, recurs);
//			renderTerain(  x, cy, hw, hh, th, cam, recurs);
//			renderTerain( cx, cy, hw, hh, th, cam, recurs);
//			return;
//		}
//
//		auto box = AABox(vec3(x*60 - (1-w)*30, 0, y*60 - (1-h)*30), vec3(w*30,th,h*30));
//		if(camFrus.intersect(box) > 0) return;
//		if(renderWire)
//		{
//			terain_wire_shader.program.setUniform("texTrans", vec3(x,y,w));
//			
//			wireMod.setModelMatrix(vec3(x*60 - (1-w)*30, 0, y*60 - (1-h)*30),vec3(0,0,0), vec3(w*30,th,h*30));
//			terain_wire_shader.program.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*wireMod.modelMatrix));
//			terain_wire_shader.program.setUniform("mMat", wireMod.modelMatrix);
//			wireMod.shaderInput.draw();
//		}
//		else
//		{
//			shade.program.setUniform("texTrans", vec3(x,y,w));
//
//			plane.setModelMatrix(vec3(x*60 - (1-w)*30, 0, y*60 - (1-h)*30),vec3(0,0,0), vec3(w*30,th,h*30));
//			shade.program.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*plane.modelMatrix));
//			shade.program.setUniform("mMat", plane.modelMatrix);
//			plane.shaderInput.draw();
//		}
//		chunkCount++;
//	}
//
//
//	private void renderTrees(camera cam)
//	{
//		tree.shaderInput.program.setUniform("vp", (cam.projMatrix*cam.viewMatrix));
//		tree.shaderInput.drawInstanced(treeCount);
//	}
//
//	private void renderClouds(camera cam)
//	{
//		import derelict.opengl3.gl3;
//		glDepthMask(GL_FALSE);
//		for(int i = -5 ; i <= 5; i++)
//		{
//			cloud_plane_shader.program.setUniform("cloudLayer", 1.0f- (i / 5.0f));
//			cloudPlane.setModelMatrix(vec3(0,cloudHeight*20 + 0.3f*i,0),vec3(0,0,0), vec3(30,1,30));
//			cloudPlane.shaderInput.program.setUniform("mvp", (cam.projMatrix*cam.viewMatrix*cloudPlane.modelMatrix));
//			cloudPlane.shaderInput.program.setUniform("mMat", cloudPlane.modelMatrix);
//			cloudPlane.shaderInput.draw();
//		}
//		glDepthMask(GL_TRUE);
//	}
//
//}
//
//struct treeDat
//{
//	vec3 loc;
//
//}