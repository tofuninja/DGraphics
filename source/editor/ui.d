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
	editor_ui.splitView.console.consoleCommandGenerator!(editor.concmds)();

	Game.printLibVersions!writeln();
	writeln("\nType \"help\" for a list of commands");
	debug auto tracker = GCTracker(); // Monitor gc activity 
	editor_ui.run();
}