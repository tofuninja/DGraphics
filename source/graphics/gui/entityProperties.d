module graphics.gui.entityProperties;
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
import graphics.gui.propertyPane;
import graphics.gui.panel;
import graphics.gui.verticalSplit;

import world.entity;
import world.component;

mixin loadUIString!(`
Panel entityprop_div
{
	background = RGB(90,90,90);
	foreground = RGB(130, 130, 130);
	textcolor = RGB(255,0,0);

	VerticalSplit vsplit
	{
		background = parent.background;
		textcolor = parent.textcolor;
		foreground  = parent.foreground;
		bounds = fill;
		percentageSplit = true;
		split = 0.5;

		componentList_div comps
		{
			background = RGB(230,230,230);
			foreground = RGB(130, 130, 130);
			textcolor = RGB(0,0,0);
		}

		PropertyPane props
		{
			background = parent.background;
			textcolor = parent.textcolor;
			foreground = RGB(130, 130, 130);
		}
	}
}
`);


@needsExtends
class EntityProperties(ExtendType) : entityprop_div!(ExtendType, div)
{
	public override void initProc()
	{
		super.initProc();
		auto comps = this.vsplit.comps;
		auto props = this.vsplit.props;
		comps.pane = props;
	}

	public void setEntity(Entity e)
	{
		auto comps = this.vsplit.comps;
		comps.setEntity(e);
	}
}

private class componentList_div : TreeView!Component
{
	PropertyPane pane;
	Entity ent;
	public override void initProc()
	{
		super.initProc();
		tree.data.icon = "\uF05E";
		tree.data.text = "No Entity Selected";
		tree.data.expandOnSelect = false;
	}

	public void setEntity(Entity e)
	{
		tree.clear();
		pane.clearData();
		ent = e;
		if(e is null) {
			tree.data.icon = "\uF05E";
			tree.data.text = "No Entity Selected";
			return;
		}

		tree.data.obj = null;
		tree.data.icon = "\uF1B2";
		tree.data.text = "Entity #" ~ e.id.to!dstring;
		tree.data.expand = true;
		tree.data.expandOnSelect = false;

		foreach(Component c; e.components)
		{
		 	auto dat = tree.Data();
		 	dat.obj = c;
		 	dat.text = {
		 		auto ids = typeid(c).to!dstring();
		 		uint loc = ids.length;
		 		for(;loc > 0; loc--) if(ids[loc-1] == '.') break;
		 		return ids[loc .. $];
		 	}();
			dat.icon = "\uF12E";
			auto n = tree.root.insertBack(dat);
		}

		if(pane !is null) pane.setData(e);
	}

	override protected void selectProc(tree.Node* n)
	{
		if(!n.data.selected) return;
		auto o = n.data.obj;
		if(pane is null) return;
		if(o is null) {
			if(ent !is null) { pane.setData(ent); }
			else pane.clearData();
			return;
		}
		o.editProperties(pane);
	}
}
