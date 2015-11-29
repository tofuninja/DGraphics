module editor.ui;

import editor.io;
import editor.concmds;
import math.matrix;
import math.geo.rectangle;
import graphics.hw;
import graphics.color;
import graphics.mesh;
import graphics.gui;
import util.memory.gcTracker;

mixin loadUIView!"editor.uiv";


typeof(startUI!editor_base()) editor_ui;

public void startEditor()
{

	editor_ui = startUI!editor_base();
	editor_ui.get!"console".consoleCommandGenerator!(editor.concmds)();
	
	{
		auto tree = editor_ui.get!"fileBox";
		tree.setFolder("./assets/");
	}
	
	Game.printLibVersions!writeln();
	writeln("\nType \"help\" for a list of commands");
	
	{
		struct test{
			int foo;
			float bar;
			char[] arr;
		}

		test t;
		t.foo = 12;
		t.bar = 3.1415926f;
		t.arr = ['a','b'];

		import util.serial;
		auto arr = Serialize(t);
		writeln(arr);
		writeln(arr.length);
		test t2;
		Deserialize(t2, arr);
		writeln(t2);
	}

	editor_ui.run();
}

template testTemp()
{
	class testTemp : div
	{

	}
}

