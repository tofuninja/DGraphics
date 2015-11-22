module editor.concmds;
import graphics.gui.console;
import editor.io;
import graphics.mesh;

@command("Exit the editor")
void exit()
{
	import graphics.hw;
	Game.state.keyboard[key.ESCAPE] = true;
}

