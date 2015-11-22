module graphics.gui.fileExplorer;
import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

import std.path;
import std.file;
import std.conv;

import graphics.gui.treeView;

class FileExplorer : TreeView!string
{
	public void setFolder(string path)
	{
		assert(isDir(path));
 
		tree.clear();
		tree.data.obj = path;
		tree.data.icon = "\uF115";
		tree.data.text = baseName(path).to!dstring;
		tree.data.expand = true;

		void addSubFolders(N)(N node, string path)
		{
			foreach(DirEntry e; dirEntries(path, SpanMode.shallow))
			{
			 	auto dat = tree.Data();
			 	dat.obj = e.name;
				dat.text = baseName(e.name).to!dstring;
				if(e.isDir)
				{
					dat.icon = "\uF114";
					dat.expand = false;
				}
				else
				{
					dat.icon = "\uF016";
				}

				auto n = node.insertBack(dat);
				if(e.isDir) addSubFolders(n, e.name);
			}
		}
		addSubFolders(tree.root, path);
	}

	override protected void expandProc(tree.Node* n)
	{
		n.data.icon = n.data.expand? "\uF115": "\uF114";
	}

	override protected void nodeDoubleClickProc(tree.Node* n)
	{
		import editor.io;
		writeln(n.data.obj);
	}
}
