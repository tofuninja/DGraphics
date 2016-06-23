module graphics.gui.treeView;
import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import container.clist;

/*

If root treeview's text and icon are both empty, then it will not indent the first set of nodes and will always exand the root
So instead of
> (no text or icon)
	> child_1
		> foo
	> child_2
	> child_3

It will display as
> child_1
	> foo
> child_2
> child_3

*/

class TreeView : div { 
	private enum level_offset = 14;
	private enum line_pad = 3;
	private enum icon_pad = 2;
	private enum dstring arrow_closed	= "\uF0DA";
	private enum dstring arrow_open		= "\uF0D7";

	dchar icon = 0; 
	bool expanded = false;
	bool selected = false;
	bool allowMultiSelect = false;
	private int arrow_width;
	private uint depth;
	private bool arrow_hover = false;
	private TreeView root;
	private int font_line_height;

	this() {
		canClick = true;
		canFocus = true;
	}

	this(dstring text) {
		this.text = text;
		canClick = true;
	}

	this(dstring text, dchar icon) {
		this.text = text;
		this.icon = icon;
		canClick = true;
	}

	override protected void initProc() {
		import std.algorithm : max;
		auto f = getGraphics.getFont;
		arrow_width = cast(int) max(f.measureString(arrow_closed).size.x, f.measureString(arrow_open).size.x);
		font_line_height = f.lineHeight;
		if(auto tv = cast(TreeView)parent) { 
			depth = tv.depth + 1;
			root = tv.root;
		} else {
			depth = 0;
			root = this;
		}
	}

	public override void doStylize() {
		import std.range;

		stylizeProc();
		doEventStylize();
		if(depth == 0 && text == "" && icon == 0) expanded = true;

		auto font = getGraphics().getFont();
		auto b = font.measureString(text);
		b.loc = vec2(0,0);
		b.size.x += textStart;
		b.size.y = textHeight;

		float pen = b.size.y;
		foreach(div d; childrenList[].retro) {
			if(cast(TreeView)d) {
				d.doStylize();
				d.bounds.loc = vec2(0, pen);
			} else {
				auto x = childStart;
				d.bounds.loc = vec2(x, pen);
				d.doStylize();
				d.bounds.loc = vec2(x, pen);
			}
			if(expanded) b.expandToFit(d.bounds);
			pen += d.bounds.size.y;
		}
		
		if(depth == 0) {
			import std.algorithm:max;
			this.bounds.size.y = b.size.y;
			apply_width(max(b.size.x, this.bounds.size.x));
		} else {
			this.bounds.size = b.size;
		}
	}

	private void apply_width(float width) {
		foreach(div d; childrenList[]) {
			if(auto c = cast(TreeView)d) {
				c.apply_width(width);
			}
		}
		this.bounds.size.x = width;
	}

	override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
		//g.drawRectangle(renderBounds, (depth%2 == 0)?RGB(255,200,200):RGB(200,255,200));
		auto font = g.getFont();
		if(selected) {
			auto highlight = renderBounds;
			highlight.size.y = textHeight;
			g.drawRectangle(highlight, style.highlight_contrast);
		}

		g.drawStringAscentLine(text, renderBounds.loc + vec2(textStart, line_pad), style.text_contrast);

		if(icon != 0) {
			dstring icstring = cast(dstring)((&icon)[0..1]);
			g.drawStringAscentLine(icstring, renderBounds.loc + vec2(iconStart, line_pad), style.text_contrast);
		}

		if(childrenList.length != 0) {
			auto arrow_color = arrow_hover?style.text_hover:style.text_contrast;
			auto arrow_text = expanded?arrow_open:arrow_closed;
			g.drawStringAscentLine(arrow_text, renderBounds.loc + vec2(arrowStart, line_pad), arrow_color);
		}
	}

	override protected void clickProc(vec2 loc,hwMouseButton button,bool down) {
		auto font = getGraphics.getFont;
		if(down && (button == hwMouseButton.MOUSE_LEFT || button == hwMouseButton.MOUSE_DOUBLE) && loc.y >= 0 && loc.y < textHeight) {
			auto arrow_start = arrowHoverStart;
			if(childrenList.length != 0 && (button == hwMouseButton.MOUSE_DOUBLE || (loc.x >=arrow_start && loc.x < arrow_start + arrow_width + icon_pad*2))) {
				expanded = !expanded;
				invalidate();
			}
			
			if(!(hwState().keyboard[hwKey.LEFT_CONTROL] || hwState().keyboard[hwKey.RIGHT_CONTROL]))
				setSelect(true, true);
			else
				setSelect(!selected, false);
		}
	}

	override protected void hoverProc(vec2 loc) {
		auto font = getGraphics.getFont;
		auto arrow_start = arrowHoverStart;
		auto past = arrow_hover;
		if(loc.y >= 0 && loc.y < textHeight && loc.x >=arrow_start && loc.x < arrow_start + arrow_width + icon_pad*2) { 
			arrow_hover = true;
		} else {
			arrow_hover = false;
		}
		if(arrow_hover != past) invalidate();
	}

	override protected void enterProc(bool enter) {
		if(!enter && arrow_hover) {
			arrow_hover = false;
			invalidate();
		}
	}
	
	override public void doKey(hwKey k,hwKeyModifier mods,bool down) {
		if(depth != 0) root.doKey(k, mods, down);
		else super.doKey(k, mods, down);
	}

	override public void doChar(dchar c) {
		if(depth != 0) root.doChar(c);
		else super.doChar(c);
	}

	void selectProc(bool select) {}

	protected void doSelect(bool value) {
		if(selected == value) return;
		selected = value;
		selectProc(value);
		EventArgs e = {type: EventType.Action, down: value};
		doEvent(e);
	}

	/// Set the select value of this tree entry, if clear is true then all other selected are de-selected
	void setSelect(bool value, bool clear = true) {
		if(clear) clear_all_but(this);
		else check_multi(this);

		doSelect(value);
		invalidate();
	}

	private void check_multi(TreeView noclear) {
		if(depth != 0) root.check_multi(noclear);
		else if(!allowMultiSelect) {
			clear_select(noclear);
		}
	}
	
	/// Clear the selection of the entire tree
	void clearSelect() {
		clear_all_but(null);
	}

	private void clear_all_but(TreeView noclear) {
		if(depth != 0) root.clear_all_but(noclear);
		else {
			clear_select(noclear);
			invalidate();
		}
	}

	private void clear_select(TreeView noclear) {
		foreach(div d; childrenList[]) {
			if(auto c = cast(TreeView)d) {
				c.clear_select(noclear);
			}
		}
		if(noclear !is this) doSelect(false);
	}

	/// Expand this node and all children nodes
	void expandAll() {
		expand_all();
		invalidate();
	}

	private void expand_all() {
		foreach(div d; childrenList[]) {
			if(auto tv = cast(TreeView)d) {
				tv.expand_all();
			}
		}
		expanded = true;
	}

	float expandTo(div node) {
		float y = 0;
		expand_to(node, y);
		invalidate();
		return y;
	}

	private bool expand_to(div node, ref float y) {
		foreach(div d; childrenList[]) {
			if(d is node) {
				y = this.bounds.loc.y + d.bounds.loc.y;
				this.expanded = true;
				return true;
			} else if(auto tv = cast(TreeView)d) {
				float cy;
				if(tv.expand_to(node, cy)) {
					y = this.bounds.loc.y + cy;
					this.expanded = true;
					return true;
				}
			}
		}
		return false;
	}

	TreeView getFirstSelected() {
		if(selected) return this;
		foreach(div d; childrenList[]) {
			if(auto tv = cast(TreeView)d) {
				auto s = tv.getFirstSelected();
				if(s !is null) return s;
			}
		}
		return null;
	}

	TreeView getRoot() {
		return root;
	}
	
	private int offset() {
		if(root.text == "" && root.icon == 0)
			return (depth-1)*level_offset;
		else return depth*level_offset;
	}

	private int textStart() {
		return arrow_width + font_line_height + icon_pad*3 + offset;
	}

	private int textHeight() {
		if(depth == 0 && text == "" && icon == 0) return 0;
		return font_line_height + line_pad*2;
	}

	private int childStart() {
		return arrow_width + font_line_height + icon_pad*3 + offset + level_offset;
	}

	private int iconStart() {
		return arrow_width + icon_pad *2 + offset;
	}

	private int arrowStart() {
		return icon_pad + offset;
	}

	private int arrowHoverStart() {
		return offset;
	}

	private bool disableFirstDepth() {
		if(root.text == "" && root.icon == 0) return true;
		else return false;
	}

	uint getDepth() { 
		return depth;
	}
}







//
//
//import graphics.gui.scrollbox;
//
//import container.tree;
//private enum x_dif = 10;
//private enum arrow_space = 2;
//private enum y_pad = 4;
//private enum icon_pad = 2;
//
//struct TreeViewNode(T)
//{
//    public this(dstring t) { text = t; }
//    dstring text = "";
//    dstring icon = "";
//    bool expand = true;
//    bool selected = false;
//    bool expandOnSelect = true;
//
//    static if(!is(T == void))
//        T obj;
//
//    private vec2 loc = vec2(0,0);
//    private vec2 icon_loc = vec2(0,0);
//}
//
//public class TreeView(T) : Scrollbox
//{
//    //public Event!(div, Tree!((TreeViewNode!T)).Node*) onSelect;
//    protected void selectProc(Tree!((TreeViewNode!T)).Node*) {}
//
//    //public Event!(div, Tree!((TreeViewNode!T)).Node*) onNodeDoubleClick;
//    protected void nodeDoubleClickProc(Tree!((TreeViewNode!T)).Node*) {}
//
//    //public Event!(div, Tree!((TreeViewNode!T)).Node*) onExpand;
//    protected void expandProc(Tree!((TreeViewNode!T)).Node*) {}
//
//    public Tree!((TreeViewNode!T)) tree;
//    public alias Node = TreeViewNode!T;
//    private tree_div!T tv; 
//
//    public override void setStyle(Style s)
//    {
//        s.lower = s.contrast;
//        super.setStyle(s);
//    }
//
//    public this()
//    {
//        tree = Tree!(TreeViewNode!T)(TreeViewNode!T());
//    }
//
//    override protected void initProc() {
//        super.initProc();
//        tv = new tree_div!T(this);
//        addDiv(tv);
//    }
//
//    override public div doClick(vec2 loc, hwMouseButton button, bool down)
//    {
//        div last = null;
//        auto newp = loc-bounds.loc;
//        foreach(c; childrenList[])
//        {
//            if(c.bounds.contains(newp)) last = c;
//        }
//
//        if(last !is null) last = last.doClick(newp, button, down);
//
//        if(canClick)
//        {
//            clickProc(newp, button, down);
//            //onClick(this, newp, button, down);
//            return this;
//        }
//        else return null;
//    }
//
//    void scrollTo(tree.Node* node)
//    {
//        float itemY = tv.scrollTo(node);
//        if(itemY == -999) return;
//        scroll.y = itemY/tv.bounds.size.y;
//        invalidate();
//    }
//}
//
//private class tree_div(T) : div
//{
//    private TreeView!T tree_view;
//    private enum dstring arrow1 = "\uF054";
//    private enum dstring arrow2 = "\uF078";
//    private float arrowOffset = 0;
//    private float line_y = 0;
//    private float ascent = 0;
//
//    this(TreeView!T t)
//    {
//        tree_view = t;
//    }
//
//    override protected void initProc() {
//        import std.algorithm;
//        super.initProc;
//        auto font = getGraphics().getFont();
//        arrowOffset = max(font.measureString(arrow1).size.x, font.measureString(arrow2).size.x) + arrow_space;
//        line_y = font.lineHeight + 2*y_pad;
//        ascent = font.ascent;
//        canClick = true;
//    }
//
//    private void calc_bounds(float min_width)
//    {
//        import std.conv;
//        import std.algorithm;
//
//        auto font = getGraphics().getFont();
//        auto icon = getGraphics().getFont();
//        fRectangle tree_bounds = fRectangle(1,1,0,0); 
//        float cur_y = 1;
//
//        void func(Tree!((TreeViewNode!T)).Node* node, int depth = 0)
//        {
//            import std.stdio;
//
//            if(!(node == tree_view.tree.root && node.data.text == "")) {
//
//                auto b_icon = icon.measureString(node.data.icon);
//                b_icon.loc.y = ascent + y_pad;
//                b_icon.loc = b_icon.loc + vec2(depth*x_dif+arrowOffset, cur_y);
//                node.data.icon_loc = b_icon.loc;
//                tree_bounds.expandToFit(b_icon);
//
//                auto b = font.measureString(node.data.text);
//                b.loc.y = ascent + y_pad;
//                b.loc = b.loc + vec2(b_icon.loc.x + b_icon.size.x + icon_pad, cur_y);
//                node.data.loc = b.loc;
//                tree_bounds.expandToFit(b);
//
//                cur_y += line_y;
//            }
//            else depth--;
//
//
//            if(node.data.expand == false) return;
//            foreach(c; node.Children) func(c, depth+1);
//        }
//
//        func(tree_view.tree.root);
//        bounds.size = tree_bounds.size;
//        bounds.size.x = max(bounds.size.x, min_width);
//
//    }
//
//    override public void stylizeProc() {
//        calc_bounds(tree_view.bounds.size.x);
//    }
//
//    override protected void drawProc(simplegraphics g, Rectangle renderBounds) {
//
//        float cur_y = 1;
//
//        void func(Tree!((TreeViewNode!T)).Node* node, int depth = 0, int child = 0)
//        {
//            if(!(node == tree_view.tree.root && node.data.text == "")) {
//                if(node.data.selected == true)
//                {
//                    auto highlight = renderBounds;
//                    highlight.loc.y += cur_y;
//                    highlight.size.y = line_y;
//                    g.drawRectangle(highlight, style.highlight_contrast);
//                }
//
//                cur_y += line_y;
//
//                g.drawString(node.data.text, renderBounds.loc + node.data.loc, style.text_contrast);
//                g.drawString(node.data.icon, renderBounds.loc + node.data.icon_loc, style.text_contrast);
//
//                if(node.childrenCount() > 0)
//                {
//                    if(node.data.expand) 
//                        g.drawString(arrow2, renderBounds.loc + node.data.icon_loc - vec2(arrowOffset, 0), style.text_contrast);
//                    else 
//                        g.drawString(arrow1, renderBounds.loc + node.data.icon_loc - vec2(arrowOffset, 0), style.text_contrast);
//                }
//            }
//            else depth--;
//
//            if(node.data.expand == false) return;
//            int count = 0;
//            foreach(c; node.Children) {
//                func(c, depth+1, count);
//                count++;
//            }
//        }
//        func(tree_view.tree.root);
//    }
//
//    override protected void clickProc(vec2 loc, hwMouseButton btn, bool down)
//    {
//        if(!down) return;
//        if(btn != hwMouseButton.MOUSE_LEFT && btn != hwMouseButton.MOUSE_DOUBLE) return;
//        bool ctrl = hwState().keyboard[hwKey.LEFT_CONTROL] || hwState().keyboard[hwKey.RIGHT_CONTROL];
//
//        float cur_y;
//        void func(Tree!((TreeViewNode!T)).Node* node, int depth = 0)
//        {
//            if(!(node == tree_view.tree.root && node.data.text == "")) {
//                bool temp = node.data.selected;
//                if(loc.y > cur_y && loc.y < cur_y + line_y)
//                {
//
//                    node.data.selected = (ctrl)? !node.data.selected : true;
//                    if(node.childrenCount > 0 && !ctrl && node.data.expandOnSelect) { 
//                        node.data.expand = !node.data.expand;
//                        tree_view.expandProc(node);
//                        //tree_view.onExpand(tree_view, node);
//                    }
//
//                    if(btn == hwMouseButton.MOUSE_DOUBLE) {
//                        tree_view.nodeDoubleClickProc(node);
//                        //tree_view.onNodeDoubleClick(tree_view, node);
//                    }
//                }
//                else if(!ctrl)
//                {
//                    node.data.selected = false;
//                }
//
//                if(temp != node.data.selected) {
//                    tree_view.selectProc(node);
//                    //tree_view.onSelect(tree_view, node);
//                }
//
//                cur_y += line_y;
//            }
//            else depth--;
//
//            if(node.data.expand == false) return;
//            foreach(c; node.Children) func(c, depth+1);
//        }
//
//        void deselectfunc(Tree!((TreeViewNode!T)).Node* node, int depth = 0)
//        {
//            if(!(node == tree_view.tree.root && node.data.text == "")) {
//                bool temp = node.data.selected;
//                if(!(loc.y > cur_y && loc.y < cur_y + line_y)) {
//                    node.data.selected = false;
//                    if(temp) {
//                        tree_view.selectProc(node);
//                    }
//                }
//                cur_y += line_y;
//            } else depth--;
//
//            if(node.data.expand == false) return;
//            foreach(c; node.Children) deselectfunc(c, depth+1);
//        }
//
//        cur_y = 1;
//        if(!ctrl) deselectfunc(tree_view.tree.root);
//        cur_y = 1;
//        func(tree_view.tree.root);
//        invalidate();
//    }
//
//    float scrollTo(Tree!((TreeViewNode!T)).Node* n)
//    {
//        float cur_y = 1;
//        float node_y = -999;
//        void func(Tree!((TreeViewNode!T)).Node* node)
//        {
//            import std.stdio;
//
//            if(!(node == tree_view.tree.root && node.data.text == "")) {
//                if(node == n) node_y = cur_y;
//                cur_y += line_y;
//            }
//
//            if(node.data.expand == false) return;
//            foreach(c; node.Children) func(c);
//        }
//
//        func(tree_view.tree.root);
//        return node_y;
//    }
//}
//
//
//
//
//
//
