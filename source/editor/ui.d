module editor.ui;

import editor.io;
import editor.concmds;
import math.matrix;
import graphics.gui;
import util.memory.gcTracker;
import tofuEngine;

Engine editor_engine;
EngineProperties editor_props;
EditorView editor_view;

public void startEditor() {
	//auto eng = new Engine(1000, 800, "Editor");
	//eng.ui.fillFirst = true;
	////eng.ui.style = Themes.Gray;
	//editor_engine = eng;
	//
	//auto vs = new VerticalSplit();
	//vs.flipSplit = true;
	//vs.percentageSplit = true;
	//vs.split = 0.25f;
	//vs.border = false;
	//vs.back = false;
	//eng.ui.addDiv(vs);
	//
	//auto hs = new HorizontalSplit();
	//hs.flipSplit = true;
	//hs.split = 200;
	//hs.back = false;
	//hs.border = false;
	//vs.addDiv(hs);
	//
	//auto con = new Console();
	//consoleCommandGenerator!(editor.concmds)(con);
	//con.border = false;
	//vs.addDiv(con);
	//editor_con = con;
	//
	//editor_view = new EditorView();
	//hs.addDiv(editor_view);
	//
	//auto ep = new EngineProperties();
	//hs.addDiv(ep);
	//editor_props = ep;
	//
	//{
	//    import graphics.hw:hwGetVersionString;
	//    import graphics.image:getImageLoaderVersionString;
	//    import graphics.font:getFontLoaderVersionString;
	//    import graphics.mesh:getMeshLoaderVersionString;
	//    import tofuEngine.components.physics_components:getPhysicsEngineVersionString;
	//    write(hwGetVersionString());
	//    write(getImageLoaderVersionString());
	//    write(getFontLoaderVersionString());
	//    write(getMeshLoaderVersionString());
	//    write(getPhysicsEngineVersionString());
	//}
	//writeln("\nType \"help\" for a list of commands");
	//writeln("WASD to move camera");
	//writeln("Click+Mouse to rotate camera");
	//
	//eng.run();
}

