module graphics.gui.treeView;
import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

import graphics.gui.scrollbox;

import container.tree;
private enum x_dif = 10;
private enum arrow_space = 2;
private enum y_pad = 4;
private enum icon_pad = 2;

struct TreeViewNode(T)
{
	public this(dstring t) { text = t; }
	dstring text = "";
	dstring icon = "";
	bool expand = true;
	bool selected = false;
	bool expandOnSelect = true;

	T obj;
	
	private vec2 loc = vec2(0,0);
	private vec2 icon_loc = vec2(0,0);
}

public class TreeView(T) : Scrollbox
{
	public Event!(div, Tree!((TreeViewNode!T)).Node*) onSelect;
	protected void selectProc(Tree!((TreeViewNode!T)).Node*){}

	public Event!(div, Tree!((TreeViewNode!T)).Node*) onNodeDoubleClick;
	protected void nodeDoubleClickProc(Tree!((TreeViewNode!T)).Node*){}

	public Event!(div, Tree!((TreeViewNode!T)).Node*) onExpand;
	protected void expandProc(Tree!((TreeViewNode!T)).Node*){}

	public Tree!((TreeViewNode!T)) tree;
	private tree_div!T tv; 
	
	public this()
	{
		tree = Tree!(TreeViewNode!T)(TreeViewNode!T());
	}

	override protected void initProc() {
		super.initProc();
		tv = new tree_div!T(this);
		addDiv(tv);
	}
}

private class tree_div(T) : div
{
	private TreeView!T tree_view;
	private enum dstring arrow1 = "\uF054";
	private enum dstring arrow2 = "\uF078";
	private float arrowOffset = 0;
	private float line_y = 0;
	private float ascent = 0;

	this(TreeView!T t)
	{
		tree_view = t;
	}
	
	override protected void initProc() {
		import std.algorithm;
		super.initProc;
		auto font = getGraphics().getIconFont();
		arrowOffset = max(font.measureString(arrow1).size.x, font.measureString(arrow2).size.x) + arrow_space;
		line_y = font.lineHeight + 2*y_pad;
		ascent = font.ascent;
		canClick = true;
	}

	private void calc_bounds(float min_width)
	{
		import std.conv;
		import std.algorithm;
		
		auto font = getGraphics().getFont();
		auto icon = getGraphics().getIconFont();
		fRectangle tree_bounds = fRectangle(1,1,0,0); 
		float cur_y = 1;

		void func(Tree!((TreeViewNode!T)).Node* node, int depth = 0)
		{
			import std.stdio;

			auto b_icon = icon.measureString(node.data.icon);
			b_icon.loc.y = ascent + y_pad;
			b_icon.loc = b_icon.loc + vec2(depth*x_dif+arrowOffset, cur_y);
			node.data.icon_loc = b_icon.loc;
			tree_bounds.expandToFit(b_icon);

			auto b = font.measureString(node.data.text);
			b.loc.y = ascent + y_pad;
			b.loc = b.loc + vec2(b_icon.loc.x + b_icon.size.x + icon_pad, cur_y);
			node.data.loc = b.loc;
			tree_bounds.expandToFit(b);

			cur_y += line_y;

			if(node.data.expand == false) return;
			foreach(c; node.Children) func(c, depth+1);
		}

		func(tree_view.tree.root);
		bounds.size = tree_bounds.size;
		bounds.size.x = max(bounds.size.x, min_width);
		
	}

	override public void stylizeProc()
	{
		calc_bounds(divparent.bounds.size.x);
		textcolor = divparent.textcolor;
		foreground = divparent.foreground;
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		float cur_y = 1;

		void func(Tree!((TreeViewNode!T)).Node* node, int depth = 0, int child = 0)
		{
			if(node.data.selected == true)
			{
				auto highlight = renderBounds;
				highlight.loc.y += cur_y;
				highlight.size.y = line_y;
				g.drawRectangle(highlight, foreground);
			}

			cur_y += line_y;

			g.drawString(node.data.text, renderBounds.loc + node.data.loc, textcolor);
			g.drawIconString(node.data.icon, renderBounds.loc + node.data.icon_loc, textcolor);

			if(node.childrenCount() > 0)
			{
				if(node.data.expand) 
					g.drawIconString(arrow2, renderBounds.loc + node.data.icon_loc - vec2(arrowOffset, 0), textcolor);
				else 
					g.drawIconString(arrow1, renderBounds.loc + node.data.icon_loc - vec2(arrowOffset, 0), textcolor);
			}

			if(node.data.expand == false) return;
			int count = 0;
			foreach(c; node.Children) {
				func(c, depth+1, count);
				count++;
			}
		}
		func(tree_view.tree.root);
	}

	override protected void clickProc(vec2 loc, mouseButton btn, bool down)
	{
		if(!down) return;
		if(btn != mouseButton.MOUSE_LEFT && btn != mouseButton.MOUSE_DOUBLE) return;

		
		float cur_y = 1;
		void func(Tree!((TreeViewNode!T)).Node* node, int depth = 0)
		{
			bool ctrl = Game.state.keyboard[key.LEFT_CONTROL] || Game.state.keyboard[key.RIGHT_CONTROL];
			bool temp = node.data.selected;
			if(loc.y > cur_y && loc.y < cur_y + line_y)
			{

				node.data.selected = (ctrl)? !node.data.selected : true;
				if(node.childrenCount > 0 && !ctrl && node.data.expandOnSelect){ 
					node.data.expand = !node.data.expand;
					tree_view.expandProc(node);
					tree_view.onExpand(tree_view, node);
				}

				if(btn == mouseButton.MOUSE_DOUBLE) {
					tree_view.nodeDoubleClickProc(node);
					tree_view.onNodeDoubleClick(tree_view, node);
				}
			}
			else if(!ctrl)
			{
				node.data.selected = false;
			}

			if(temp != node.data.selected) {
				tree_view.selectProc(node);
				tree_view.onSelect(tree_view, node);
			}

			cur_y += line_y;

			if(node.data.expand == false) return;
			foreach(c; node.Children) func(c, depth+1);
		}

		func(tree_view.tree.root);
		invalidate();
		
	}
}

