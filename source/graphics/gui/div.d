module graphics.gui.div;


import util.event;
import graphics.gui.parser.ast.astNode;
import graphics.hw.game;
import graphics.simplegraphics;
import graphics.color;
import math.matrix;
import math.geo.rectangle;


class div
{
	protected div divparent;

	// set of generic properties that all divs will have
	public Rectangle bounds;
	public dstring text = "";
	public Color background = RGB(255,255,255);
	public Color foreground = RGB(0,0,0);
	public bool canFocus = false;
	public bool canClick = false;
	public bool canScroll = false;
	public bool hasFocus = false;

	public Event!(div) onInit;
	public Event!(div) onThink;
	public Event!(div,simplegraphics,Rectangle) onDraw;
	public Event!(div) onStylize;
	public Event!(div,vec2,mouseButton,bool) onClick;
	public Event!(div,key,keyModifier,bool) onKey;
	public Event!(div,bool) onEnter;
	public Event!(div,vec2) onHover;
	public Event!(div,bool) onFocus;
	public Event!(div,dchar) onChar;
	public Event!(div,vec2,int) onScroll;
	protected void initProc(){} 
	protected void thinkProc(){}
	protected void stylizeProc(){}
	protected void afterStylizeProc(){}
	protected void drawProc(simplegraphics g, Rectangle renderBounds) {}
	protected void afterDrawProc(simplegraphics g, Rectangle renderBounds) {}
	protected void keyProc(key k, keyModifier mods, bool down){}
	protected void charProc(dchar c) {} 
	protected void clickProc(vec2 loc, mouseButton button, bool down){}
	protected void enterProc(bool enter){}
	protected void hoverProc(vec2 pos){}
	protected void focusProc(bool hasFocus){}
	protected void scrollProc(vec2 loc, int scroll){}
	public void invalidate(){ divparent.invalidate(); }

	enum styleMember[] style = []; 

	public void doThink()
	{
		thinkProc();
		onThink(this);
		foreach(div d; children())
		{
			d.doThink();
		}
	}

	public void doStylize()
	{
		stylizeProc();
		onStylize(this);
		
		foreach(div d; children())
		{
			d.doStylize();
		}

		afterStylizeProc();
	}

	public void doDraw(simplegraphics g, Rectangle renderBounds)
	{
		auto t = g.addScissor(renderBounds);
		drawProc(g, renderBounds);
		g.setScissor(t);

		t = g.addScissor(renderBounds);
		onDraw(this, g, renderBounds);
		g.setScissor(t);


		foreach(div d; children())
		{
			t = g.addScissor(renderBounds);
			d.doDraw(g, Rectangle(renderBounds.loc + d.bounds.loc, d.bounds.size));
			g.setScissor(t);
		}

		t = g.addScissor(renderBounds);
		afterDrawProc(g, renderBounds);
		g.setScissor(t);
	}

	public void doKey(key k, keyModifier mods, bool down)
	{
		keyProc(k, mods, down);
		onKey(this, k, mods, down);
	}

	public void doChar(dchar c)
	{
		charProc(c);
		onChar(this, c);
	}
	
	public div doClick(vec2 loc, mouseButton button, bool down)
	{
		div last = null;
		auto newp = loc-bounds.loc;
		foreach(c; children)
		{
			if(c.bounds.contains(newp)) last = c;
		}

		if(last !is null) last = last.doClick(newp, button, down);

		if(last is null)
		{
			if(canClick)
			{
				clickProc(newp, button, down);
				onClick(this, newp, button, down);
				return this;
			}
			else return null;
		}

		return last;
	}

	public div doScroll(vec2 loc, int scroll)
	{
		div last = null;
		auto newp = loc-bounds.loc;
		foreach(c; children)
		{
			if(c.bounds.contains(newp)) last = c;
		}
		
		if(last !is null) last = last.doScroll(newp, scroll);
		
		if(last is null)
		{
			if(canScroll)
			{
				scrollProc(newp, scroll);
				onScroll(this, newp, scroll);
				return this;
			}
			else return null;
		}
		
		return last;
	}

	public div doHover(vec2 loc)
	{
		div last = null;
		auto newp = loc-bounds.loc;
		foreach(c; children)
		{
			if(c.bounds.contains(newp)) last = c;
		}

		if(last is null)
		{
			hoverProc(newp);
			onHover(this, newp);
			return this;
		}
		
		return last.doHover(newp);
	}

	public void doEnter(bool enter)
	{
		enterProc(enter);
		onEnter(this, enter);
	}

	public void doFocus(bool hasFocus)
	{
		this.hasFocus = hasFocus;
		focusProc(hasFocus);
		onFocus(this, hasFocus);
	}

	// A linked list to keep track of children
	protected div next = null;
	protected div childrenHead = null;
	public final void addDiv(div d)
	{
		assert(d.next is null, "Child of another div");
		assert(d.divparent is null, "Child of another div");
		d.next = childrenHead;
		childrenHead = d;
		d.divparent = this;
		d.initProc();
		d.onInit(d);
		d.invalidate();
	}

	public final auto children()
	{
		import std.range;
		struct result
		{
			public div front;
			public void popFront()	{front = front.next;}
			public bool empty()		{return front is null;}
		}
		static assert(isInputRange!result);
		return result(childrenHead);
	}

	public simplegraphics getGraphics()
	{
		return divparent.getGraphics();
	}

	protected Rectangle fill()
	{
		return Rectangle(vec2(0,0), divparent.bounds.size);
	}



}






// DIV Generation code, realy convoluted, beware 

/**
 * Generate ui class code from a file in the string import folder
 */
mixin template loadUIView(string view)
{
	mixin(uiMarkupMixin(import(view)));
}

/**
 * Generate ui class code from the string 
 */
mixin template loadUIString(string ui)
{
	mixin(uiMarkupMixin(ui));
}





// Generate the code for a div class body
private string divBodyMixin(divNode node, bool insertExtends = true)
{
	// stick in a test to make sure the parent is a div and declare a reference to the parent
	string r = `{`;
	r ~= `static assert(is(ParentType : div), "Error, parent not child of div");`;
	r ~= `public ParentType parent;`;

	if(!insertExtends) r ~= `static if(is(ExtendType == div)){`;
	r ~= `alias Extend = typeof(this);`;
	if(!insertExtends) r ~= `}else {alias Extend = ExtendType;}`;

	{
		//r ~= "enum childMember[] _children_mixin = super._children_mixin ~ [";
		// Add all sub divs
		foreach(astNode n; node.children)
		{
			if(n.nodeName == "divNode")
			{
				auto d = cast(divNode)n;
				// makes a private class for the div

				//r ~= "childMember( \"" ~ d.name ~ "\", q{";

				r ~= `static assert(is(check_need_extend!(` ~ d.className ~ `,` ~ d.name ~ `_type!(Extend),` ~ d.name ~ `_type!(Extend)) : div), "Error, class not child of div ` ~ d.className ~ `");`;
				r ~= `private class ` ~ d.name ~ `_type(ParentType) : check_need_extend!(` ~ d.className ~ `,` ~ d.name ~ `_type!(Extend),` ~ d.name ~ `_type!(Extend))` ~ divBodyMixin(d);
				// declares the actuall div with the class we just made 
				r ~= d.name ~ `_type!(Extend) ` ~ d.name ~ `;`;

				//r ~= "}), ";
			}
		}

		//r ~= "];";
	}


	{
		// stick in a constructor to set parent and init sub divs
		//r ~= `static if(mixinChildren) {`;

		r ~= `protected override void initProc()`;
		r ~= `{`; 
		r ~= `super.initProc();`;
		r ~= `parent = cast(ParentType)(divparent);`;

		// init all sub divs
		foreach(astNode n; node.children)
		{
			if(n.nodeName == "divNode")
			{
				auto d = cast(divNode)n;
				r ~= d.name ~ ` = new ` ~ d.name ~ `_type!(Extend)();`;
				r ~= `this.addDiv(` ~ d.name ~ `);`;
			}
		}

		/*
		r ~= `string foo()`;
		r ~= `{`;
		r ~= `string r = "";`;
		r ~= `foreach(child; _children_mixin)`;
		r ~= `{`;
		r ~= `r ~= child.name ~ " = new " ~ child.name ~ "_type!(typeof(this))();";`;
		r ~= `r ~= "this.addDiv(" ~ child.name ~ ");";`;
		r ~= `}`;
		r ~= `return r;`;
		r ~= `}`;
		r ~= `mixin(foo());`;
		*/

		r ~= `}`;
		//r ~= `mixin(children_mixer(_children_mixin));`;
		//r ~= `}`;
	}


	{
		import std.string;
		// stylize override
		// call out to the super style and all the defined styles and insert a custom style for this div
		/*
		r ~= `protected override void stylizeProc()`;
		r ~= `{`;
		r ~= `super.stylizeProc();`;
		foreach(string style; node.styles) r ~= style ~ `(this);`;
		r ~= styleBodyMixin(node);

		r ~= `}`;
		*/

		r ~= "enum styleMember[] style = super.style ~ "; 
		foreach(string style; node.styles) r ~= style ~ `_style ~ `;
		r ~= newstyleBodyMixin(node) ~ ";";
		r ~= "mixin(generateNewStylize());";
	}

	r ~= `}`;

	return r;
}

// Generate the code for a style body
/*
private string styleBodyMixin(astNode node)
{
	string r = `{`;
	foreach(astNode n; node.children)
	{
		if(n.nodeName == "assignStmtNode")
		{
			// insert all assignments 
			auto asn = cast(assignStmtNode)n;
			r ~= asn.left.expressionMixin() ~ ` = ` ~ asn.right.expressionMixin() ~ `;`;
		}
	}
	r ~= `}`;

	return r;
}
*/

// Generate the code for a style body
private string newstyleBodyMixin(astNode node)
{
	string r = `[`;
	foreach(astNode n; node.children)
	{
		if(n.nodeName == "assignStmtNode")
		{
			// insert all assignments 
			auto asn = cast(assignStmtNode)n;
			r ~= "styleMember(`" ~ asn.name ~ "`, `" ~ asn.left.expressionMixin() ~ " = " ~ asn.right.expressionMixin() ~ "`), ";
		}
	}
	r ~= `]`;
	return r;
}

// Generates the code for a ui markup
public string uiMarkupMixin(string code)
{
	import graphics.gui.parser.grammar;
	import std.string;
	string r = "";
	astNode node;
	if(!uiFileParse(node, code)) return `static assert(false, "Failed to parse ui markup");`;

	foreach(astNode n; node.children)
	{
		if(n.nodeName == "styleNode")
		{

			// declare a style function 

			auto s = cast(styleNode)n;
			/*
			r ~= `void ` ~ s.name ~ `(T)(T t)`;
			r ~= `{`;
			foreach(string style; s.styles) r ~= style ~ `(t);`;
			r ~= styleBodyMixin(s).replace("this", "t");
			r ~= `}`;
			*/

			r ~= "enum styleMember[] " ~ s.name ~ "_style = " ~ newstyleBodyMixin(s) ~ ";";
		}
		else if(n.nodeName == "divNode")
		{
			auto d = cast(divNode)n;
			// declar a class for the div and insert type checking for the parent class
			r ~= `static assert(is(` ~ d.className ~` : div), "Error, class not child of div");`;
			r ~= `@needsExtends class ` ~ d.name ~ `(ExtendType, ParentType = div) : check_need_extend!(` ~ d.className ~ `, ExtendType, `~ d.name ~ `!(ExtendType, ParentType))` ~ divBodyMixin(d, false);
		}
	}

	return r;//.replace(";", ";\n").replace("{", "{\n").replace("}", "}\n");
}

string generateNewStylize()
{
	return `
	override void stylizeProc()
	{
		alias t = this;
		string foo()
		{
			string r = "";
			foreach(sty; style)
			{
				r ~= sty.style ~ ";";
			}
			return r;
		}

		mixin(foo());
	}`;
}

public auto stylized(T)(T t)
{
	struct Result
	{
		T v;
		public auto ref opDispatch(string s)()
	    {
	        return v.getStylizedProperty!s();
	    }
	}

	return Result(t);
}

auto ref getStylizedProperty(string s, T)(T t)
{
	import std.stdio;
	static if(!__traits(hasMember, t, s) && __traits(hasMember, t, "parent"))
	{
		return t.parent.getStylizedProperty!s();
	}
	else{

		static if(__traits(hasMember, t, "style"))
		{
			string foo()
			{
				string r = "";
				foreach(sty; t.style)
				{
					if(sty.name == s) r ~= sty.style ~ ";";
				}
				return r;
			}

			mixin(foo());
		}

		return mixin("t." ~ s);
	}
}

struct styleMember
{
	string name;
	string style;
}

template check_need_extend(alias T, E, AE)
{
	static if(is(E == div))
	{
		alias extends = AE;
	}
	else
	{
		alias extends = E;
	}
	import util.hasUDA;
	
	
	static if(hasUDA!(T, needsExtends))
		alias me = T!(extends);
	else
		alias me = T;

	alias check_need_extend = me;
}

enum needsExtends;