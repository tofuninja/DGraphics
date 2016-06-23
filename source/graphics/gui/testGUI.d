module graphics.gui.testGUI;

void testGUI() {
	import tofuEngine;
	import graphics.gui;
	import math.matrix;
	import math.geo.rectangle;


	tofu_EngineStartInfo info;
	info.width = 1000;
	info.height = 800;
	info.title = "Test Gui";
	tofu_StartEngine(info);

	tofu_UI.back = true;
	Button b = new Button();
	b.bounds = Rectangle(100,100,200,50);
	b.text = "button";
	b.eventHandeler = (EventArgs args) {
		import graphics.hw;
		if(args.origin == b && args.type == EventType.Action) {
			msgbox("test");
		} else if(args.origin == b && args.type == EventType.Click && args.down && args.mouse == hwMouseButton.MOUSE_RIGHT) { 
			args.origin.openContextMenu(["Item1", "Item2", "", "Boo", ">sub", "sub1", ">another", "1", "", "2", "<", "sub2", ">another 2", "hello", "world", "<", "<", "second last", "last"]);
		} else if(args.origin == b && args.type == EventType.Menu) { 
			import std.stdio;
			writeln(args.ivalue, " : ", args.svalue);
		}
	};
	tofu_UI.addDiv(b);

	VerticalSplit s = new VerticalSplit();
	s.split = 0.5f;
	s.percentageSplit = true;
	s.bounds = Rectangle(100,200,200,200);
	tofu_UI.addDiv(s);

	Label l = new Label();
	l.text = "test label";
	l.bounds.loc = vec2(400,100);
	tofu_UI.addDiv(l);

	auto p = new Scrollbox();
	p.bounds = Rectangle(400,200,100,100);
	
	auto tb = new Textbox();
	tb.text = "enter text";
	tb.bounds = Rectangle(20,20,100,0);
	p.addDiv(tb);
	tofu_UI.addDiv(p);


	auto va = new VerticalArrangement();
	va.bounds = Rectangle(400,500,0,0);
	tofu_UI.addDiv(va);
	for(int i = 0;i < 8; i++) {
		import std.conv;
		Label lab = new Label();
		lab.text = "label " ~ i.to!dstring;
		va.addDiv(lab);
	}

	auto con = new Console();
	con.bounds = Rectangle(600, 100, 200, 100);
	consoleCommandGenerator!commands(con);
	tofu_UI.addDiv(con);

	auto cb = new Checkbox();
	cb.bounds.loc = vec2(600,400);
	tofu_UI.addDiv(cb);

	auto vslide = new ValueSlider();
	vslide.bounds = Rectangle(600,440,200,0);
	vslide.min = -5;
	vslide.max = 5;
	tofu_UI.addDiv(vslide);

	auto l_under = new Label();
	l_under.text = "Under - - - - - - - - Under";
	l_under.back = true;
	l_under.border = true;
	l_under.bounds.loc = vec2(125,575);
	tofu_UI.addDiv(l_under);
	
	auto l_over = new Label();
	l_over.text = "Over - - - Over";
	l_over.back = true;
	l_over.border = true;
	l_over.bounds.loc = vec2(145,578);
	tofu_UI.addDiv(l_over);

	auto testWindow = new Window();
	testWindow.fillFirst = true;
	testWindow.bounds = Rectangle(300,550,300,200);
	testWindow.text = "This is a test Window...";
	tofu_UI.addDiv(testWindow);

	auto tvsb = new Scrollbox();
	tvsb.fillFirst = true;
	tvsb.border = false;
	tvsb.back = false;
	{
		auto tv = new TreeView();
		tv.text = "root";
		tv.icon = '\uf03e';
		auto n1 = new TreeView("node1........");
		auto n2 = new TreeView("node2");
		n1.addDiv(n2);
		tv.addDiv(n1);
		tv.addDiv(new TreeView("Long node name 1234567890"));

		{
			auto tree_btn = new Button();
			tree_btn.bounds = Rectangle(0,0,150,30);
			tree_btn.text = "expand to node2";
			tree_btn.eventHandeler = (EventArgs args) {
				import std.stdio;
				if(args.type == EventType.Action) {
					auto y = tv.expandTo(n2);
					writeln(y);
				} 
			};
			tv.addDiv(tree_btn);
		}
		tv.addDiv(new TreeView("node3"));
		tvsb.addDiv(tv);
	}
	testWindow.addDiv(tvsb);

	auto testWindow2 = new Window();
	testWindow2.bounds = Rectangle(650,550,300,200);
	testWindow2.text = "Window2";
	tofu_UI.addDiv(testWindow2);

	Button b2 = new Button();
	b2.bounds = Rectangle(10,10,200,50);
	b2.text = "Props";
	b2.eventHandeler = (EventArgs args) {
		if(args.origin == b2 && args.type == EventType.Click && args.down) { 
			import graphics.gui;
			import graphics.color;
			import std.stdio;
			struct test {
				int a;
				int b;
				string s;
				Color c = RGB(255,0,0);
				vec2 testvec;
				ListSelect pick_a_letter = ListSelect(["a", "b", "c"]);
				bool bo;
				ClamepedValue clamp = ClamepedValue(0,-5,5);
			}

			test t;
			t.a = 5;
			propbox(t);
			writeln(t);
		}
	};
	testWindow2.addDiv(b2);

	tofu_RunEngineLoop();
}


class commands {
	import graphics.gui;
	@command("test command")
	static void test() {
		import std.stdio;
		writeln("test");
	}
}

