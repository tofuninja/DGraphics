module main;

import graphics.hw;
import math.matrix;
import math.geo.rectangle;
import editor.ui;
import graphics.color;
import tofuEngine;
import graphics.gui.engineView;

/* 	MAIN  */
void main(string[] args) { 
	version(tofu_TestGUI) {
		import graphics.gui.testGUI;
		testGUI();
	} else {
		tofu_EngineStartInfo info;
		info.title = "Game";
		alias ratio = (x) => (x*1000)/1920;
		info.width = 1800;
		info.height = ratio(info.width);
		tofu_StartEngine(info);
		tofu_RunEngineLoop();
	}
}