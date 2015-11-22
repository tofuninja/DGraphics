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
		import world.entity;
		Entity e = new Entity(0);
		e.name = "Test Entity";
		e.addComponent(new testComponent());
		auto props = editor_ui.get!"entityProps";
		props.setEntity(e);
	}

	editor_ui.run();
}

template testTemp()
{
	class testTemp : div
	{

	}
}

