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

@command("Test mesh loading")
void loadMeshes(string file)
{
	Mesh[] a = loadMeshAsset(file);
	foreach(m; a)
	{
		writeln(m.name);
		writeln("Vector Count: ", m.vectorCount);
		writeln("Index Count: ", m.indexCount);
	}
}