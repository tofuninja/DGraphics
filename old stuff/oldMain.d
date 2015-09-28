///* GAME MAIN */
//void gameMain(string[] args)
//{
//	import math.conversion;
//	import util.gcTracker;
//	import std.datetime;
//	import graphics.fpsTracker;
//	import std.conv;
//
//	// Init Graphics State
//	initializeGraphicsState(args);
//
//	infoln("D-Graphics");
//	 
//	// Main renderer
//	auto map = new mapGenerator();
//	auto pan = new oglRender(vec2(0,0),vec2(1,1),basePan, map);
//
//	int yl = 50;
//	int xl = 10;
//	int wl = 150;
//	int sep = 30;
//
//	mixin(vSlide("terainSeed","Seed","0","10000"));
//	mixin(vSlide("terainSize","Size","0","10000"));
//	mixin(vSlide("terainOctCount","Oct","0","100"));
//	mixin(vSlide("terainBaseSize","Base Oct","0","100"));
//	mixin(vSlide("terainMtnOctCount","Mtn Oct","0","100"));
//	mixin(vSlide("terainMtnBaseSize","Mtn Base Oct","0","100"));
//	mixin(vSlide("terainBaseScale","Terain Scale","0","2"));
//	mixin(vSlide("terainMtnScale","Mtn Scale","0","2"));
//	mixin(vSlide("grassSize","Grass Size","0","10000"));
//	mixin(vSlide("grassOctCount","Grass Oct","0","100"));
//	mixin(vSlide("grassBaseSize","Grass Base Oct","0","100"));
//	mixin(vSlide("waterSize","Water Size","0","10000"));
//	mixin(vSlide("waterHeight","Water Height","0","2"));
//	mixin(vSlide("riverCount","River Count","0","200"));
//	mixin(vSlide("riverLength","River Length","0","10000"));
//	mixin(vSlide("treeDist","Tree Dist","0","0.01f"));
//	mixin(vSlide("cloudSize","Cloud Size","0","10000"));
//	mixin(vSlide("cloudOctCount","Cloud Oct","0","100"));
//	mixin(vSlide("cloudBaseSize","Cloud Base Oct","0","100"));
//	mixin(vSlide("cloudHeight","Cloud Height","0","5"));
//	mixin(vSlide("snowTop","Snow Height","0","2"));
//
//	void all()
//	{
//		map.gen();
//	}
//
//	void grass()
//	{
//		map.generateGrass();
//	}
//
//	void water()
//	{
//		map.waterFlow();
//	}
//
//	void tree()
//	{
//		map.generatePlants();
//	}
//
//	void cloud()
//	{
//		map.generateClouds();
//	}
//
//	all();
//	yl = 50;
//	xl += wl+10;
//	wl = 100;
//
//
//	auto allBtn = new Button(vec2(xl,yl), vec2(wl,25),"Gen All", &all); yl += sep;
//	auto grassBtn = new Button(vec2(xl,yl), vec2(wl,25),"Gen Grass", &grass); yl += sep;
//	auto waterBtn = new Button(vec2(xl,yl), vec2(wl,25),"Gen Water", &water); yl += sep;
//	auto treeBtn = new Button(vec2(xl,yl), vec2(wl,25),"Gen Trees", &tree); yl += sep;
//	auto cloudBtn = new Button(vec2(xl,yl), vec2(wl,25),"Gen Cloud", &cloud); yl += sep;
//
//	void wire(bool b) { map.renderWire = b; }
//	auto wireCheck = new checkBox(vec2(xl,yl),wl,"Wire"); yl += sep;
//	wireCheck.onCheck = &wire;
//	
//	void rtrees(bool b) { map.render_Trees = b; }
//	auto treeCheck = new checkBox(vec2(xl,yl),wl,"Trees"); yl += sep;
//	treeCheck.value = true;
//	treeCheck.onCheck = &rtrees;
//	
//	void rcloud(bool b) { map.render_Clouds = b; }
//	auto cloudCheck = new checkBox(vec2(xl,yl),wl,"Clouds"); yl += sep;
//	cloudCheck.value = true;
//	cloudCheck.onCheck = &rcloud;
//
//
//	auto fpsLabel = new label(vec2(10,10), vec2(200,25));
//	fpsLabel.setText("FPS:");
//
//
//	checkGlError();
//
//
//
//
//	// Loop until the user closes the window 
//	debug auto tracker = GCTracker(); // Monitor gc activity `
//	auto fps = FPSTracker(); // Track fps
//	debug writeln("Enter Main Loop");
//	while (!glfwWindowShouldClose(window))
//	{
//		import gui.keyboard;
//		// Render here 
//		glClearColor(0.6f,0.8f,1.0f,1);
//		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//
//		infoTime--;
//		if(infoTime < 0) infoBox.setVisable(false);
//
//		if(keyState[GLFW_KEY_TAB]) {
//			infoTime = 1;
//			infoBox.setVisable(true);
//		}
//
//		if(keyState[GLFW_KEY_ESC]) break;
//
//		basePan.featchMouse(window);
//		basePan.sendTick();
//		basePan.composit();
//
//		// Swap front and back buffers
//		glfwSwapBuffers(window);
//		glfwPollEvents();
//		checkGlError();
//		fps.postFrame();
//		if(fps.totalFrames % 100 == 0) fpsLabel.setText("FPS: " ~ fps.fps.to!string);
//	}
//}
//
//
//
//
///* OPENGL RENDERER */
//class oglRender : Panel
//{
//	import graphics.camera;	
//	import graphics.mesh;
//	import graphics.frameBuffer;
//	import graphics.hw.shader;
//	import graphics.hw.buffer;
//	import graphics.hw.renderTarget;
//	import graphics.hw.texture;
//	import resources.glslManager;
//	import std.datetime;
//
//	camera cam;
//
//	int time = 0;
//	float timeSeconds = 0.0f;
//	SysTime startTime;
//
//	mapGenerator map;
//
//
//	public this(vec2 loc, vec2 size, Panel owner, mapGenerator MAP)
//	{
//		import math.conversion;
//		startTime = Clock.currTime();
//		map = MAP;
//
//		map.init();
//
//		// Set up cam
//		cam = camera(toRad(60), size.x/size.y);
//		cam.rot = vec3(toRad(200), toRad(40),0);
//		cam.eye = vec3(0,30,10);
//
//
//		checkGlError();
//
//		super(loc, null, owner);
//	}
//	
//	override public void tick() 
//	{
//		import math.conversion;
//		import gui.keyboard;
//		import std.conv;
//
//		float dt = timeSeconds;
//		timeSeconds = (Clock.currTime() - startTime).total!"msecs" / 1000.0f;
//		dt = timeSeconds - dt;
//		
//		enum camSpeed = 0.5f;
//		enum camMovSpeed = 5.0f;
//		enum camZoomSpeed = 1.0f;
//		if(keyState[GLFW_KEY_UP]) cam.rot.y -= camSpeed*dt;
//		if(keyState[GLFW_KEY_DOWN]) cam.rot.y += camSpeed*dt;
//		if(keyState[GLFW_KEY_LEFT]) cam.rot.x -= camSpeed*dt;
//		if(keyState[GLFW_KEY_RIGHT]) cam.rot.x += camSpeed*dt;
//		auto rotMat = rotationMatrix(cam.rot);
//		if(keyState[GLFW_KEY_W]) cam.eye = cam.eye + (rotMat*vec4(0,0, camMovSpeed,1)).xyz*dt;
//		if(keyState[GLFW_KEY_S]) cam.eye = cam.eye + (rotMat*vec4(0,0,-camMovSpeed,1)).xyz*dt;
//		if(keyState[GLFW_KEY_A]) cam.eye = cam.eye + (rotMat*vec4(-camMovSpeed,0,0,1)).xyz*dt;
//		if(keyState[GLFW_KEY_D]) cam.eye = cam.eye + (rotMat*vec4( camMovSpeed,0,0,1)).xyz*dt;
//		if(keyState[GLFW_KEY_Q]) cam.zoom -= camZoomSpeed*dt;
//		if(keyState[GLFW_KEY_E]) cam.zoom += camZoomSpeed*dt;
//		cam.invalidate();
//
//		map.draw(cam, dt, timeSeconds);
//
//		checkGlError();
//		time ++;
//	}
//}
//
//
//
//string vSlide(string s, string title, string min, string max)
//{
//	string mix = "auto "~s~"Slide = new ValueSlider!(typeof(map."~s~"))(vec2(xl,yl), wl, \""~title~"\","~min~","~max~"); yl += sep;";
//	mix ~= s~"Slide.setValue(map."~s~");";
//	mix ~= "void get"~s~"(typeof(map."~s~") v){map."~s~" = v; }";
//	mix ~= s~"Slide.onChange = &get"~s~";";
//	return mix;
//}
//

