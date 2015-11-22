module graphics.gui.div;

import util.event;
import graphics.gui.parser.ast.astNode;
import graphics.hw.game;
import graphics.simplegraphics;
import graphics.color;
import math.matrix;
import math.geo.rectangle;
import container.clist;

//	 _____  _       
//	|  __ \(_)      
//	| |  | |___   __
//	| |  | | \ \ / /
//	| |__| | |\ V / 
//	|_____/|_| \_/  
//	                
//	                

// TODO force re draw with out re stylize
// TODO make shadows more noticeable
// TODO maybe have a value for shadow intensity?  

// TODO redo the stylize system to just be list of function pointers, will be much more simple and solve alot of problems... 

class div
{
	protected div divparent;

	// set of generic properties that all divs will have
	public Rectangle bounds;
	public dstring text = "";
	public Color background = RGB(255,255,255);
	public Color foreground = RGB(0,0,0);
	public Color textcolor = RGB(0,0,0);
	public bool canFocus = false;
	public bool canClick = false;
	public bool canScroll = false;
	public bool hasFocus = false;

	public cursorRef cursor;
	public CList!div childrenList;

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
	mixin(getLocal_mixin);

	public this()
	{
		cursor = Game.SimpleCursors.arrow;
	}

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
	}

	public void doAfterStylize()
	{
		afterStylizeProc();
		
		foreach(div d; children())
		{
			d.doAfterStylize();
		}
	}

	public void doDraw(simplegraphics g, Rectangle renderBounds)
	{
		vec2 roundVec2(vec2 v)
		{
			import std.math;
			return vec2(round(v.x), round(v.y));
		}

		renderBounds.loc = roundVec2(renderBounds.loc);
		renderBounds.size = roundVec2(renderBounds.size);

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
		if(enter) Game.cmd(cursor);
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

	//protected div next = null;
	//protected div childrenHead = null;

	

	public final void addDiv(div d)
	{
		//assert(d.next is null, "Child of another div");
		assert(d.divparent is null, "Child of another div");
		//d.next = childrenHead;
		//childrenHead = d;
		childrenList.insertFront(d);
		d.divparent = this;
		d.initProc();
		d.onInit(d);
		d.invalidate();
	}

	public final auto children()
	{
		//import std.range;
		//struct result
		//{
		//	public div front;
		//	public void popFront()	{front = front.next;}
		//	public bool empty()		{return front is null;}
		//}
		//static assert(isInputRange!result);
		//return result(childrenHead);
		return childrenList.Range;
	}

	public simplegraphics getGraphics()
	{
		return divparent.getGraphics();
	}

	protected Rectangle fill()
	{
		return Rectangle(vec2(0,0), divparent.bounds.size);
	}

	public auto get(string name, this T)()
	{
		auto t = cast(T)this;

		static if(__traits(hasMember, T, name) && is(typeof(mixin("t." ~ name)) : div))
		{
			return mixin("t." ~ name);
		}
		else
		{
			foreach(m; __traits(allMembers, T))
			{

				static if(m != "divparent" && m != "parent" && is(typeof(mixin("t." ~ m)) : div) && !is(typeof(mixin("t." ~ m).get!name()) == void))
				{
					return mixin("t." ~ m).get!name();
				}
			}
		}
		assert(0);
	}
}





// DIV Generation code, realy convoluted, beware 
//	 _____  _              _                           _      _           
//	|  __ \(_)            | |                         (_)    (_)          
//	| |  | |___   __   ___| | __ _ ___ ___   _ __ ___  ___  ___ _ __  ___ 
//	| |  | | \ \ / /  / __| |/ _` / __/ __| | '_ ` _ \| \ \/ / | '_ \/ __|
//	| |__| | |\ V /  | (__| | (_| \__ \__ \ | | | | | | |>  <| | | | \__ \
//	|_____/|_| \_/    \___|_|\__,_|___/___/ |_| |_| |_|_/_/\_\_|_| |_|___/
//	                                                                      
//	     

/// Used to indicate that super div needs to know who is extending it(in the form of a template argument)
public enum needsExtends;

/// Generate ui class code from a file in the string import folder
public mixin template loadUIView(string view)
{
	mixin(uiMarkupMixin(import(view)));
}

/// Generate ui class code from the string 
public mixin template loadUIString(string ui)
{
	mixin(uiMarkupMixin(ui));
}

/// Generates a the D code for a new stylize based on the style markup code provided
public string customStyleMixin(string code)
{
	import graphics.gui.parser.grammar;
	astNode n;
	if(!customStyleParse(n, code)) return `static assert(false, "Failed to parse custom style markup");`;
	styleNode node = cast(styleNode)n;
	string r = "";
	r ~= "enum styleMember[] style = super.style ~ "; 
	r ~= style_array_mixin(node) ~ ";";
	r ~= "mixin(new_stylize_mixin);";
	return r;
}

/// Generates the D code for a ui based the ui markup code provided
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

			// declare a style array
			auto s = cast(styleNode)n;
			r ~= "enum styleMember[] " ~ s.name ~ "_style = " ~ style_array_mixin(s) ~ ";";
		}
		else if(n.nodeName == "divNode")
		{
			auto d = cast(divNode)n;
			// declar a class for the div and insert type checking for the parent class
			r ~= `static assert(is(` ~ d.className ~` : div), "Error, class not child of div");`;
			r ~= `@needsExtends class ` ~ d.name ~ `(ExtendType, ParentType = div) : check_need_extend!(` ~ d.className ~ `, ExtendType, `~ d.name ~ `!(ExtendType, ParentType))` ~ divBodyMixin(d, false);
		}
	}

	return r;
}

/// Generate the code for a div class body
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
		// Add all sub divs
		foreach(astNode n; node.children)
		{
			if(n.nodeName == "divNode")
			{
				auto d = cast(divNode)n;
				// makes a private class for the div
				r ~= `static assert(is(check_need_extend!(` ~ d.className ~ `,` ~ d.name ~ `_type!(Extend),` ~ d.name ~ `_type!(Extend)) : div), "Error, class not child of div ` ~ d.className ~ `");`;
				r ~= `private class ` ~ d.name ~ `_type(ParentType) : check_need_extend!(` ~ d.className ~ `,` ~ d.name ~ `_type!(Extend),` ~ d.name ~ `_type!(Extend))` ~ divBodyMixin(d);
				// declares the actuall div with the class we just made 
				r ~= d.name ~ `_type!(Extend) ` ~ d.name ~ `;`;
			}
		}
	}


	{
		// stick in a constructor to set parent and init sub divs
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
		r ~= `}`;
	}

	r ~= "enum styleMember[] style = "; 
	foreach(string style; node.styles) r ~= style ~ `_style ~ `;
	r ~= style_array_mixin(node) ~ ";";
	r ~= "mixin(new_stylize_mixin);";


	r ~= `}`;

	return r;
}

/// Checks if a type has the attribute @needsExtends
public template check_need_extend(alias T, E, AE)
{
	static if(is(E == div))
	{
		alias extends = AE;
	}
	else
	{
		alias extends = E;
	}

	import std.traits : hasUDA;
	static if(hasUDA!(T, needsExtends))
		alias me = T!(extends);
	else
		alias me = T;

	alias check_need_extend = me;
}










//	  _____ _         _ _           _                 _      
//	 / ____| |       | (_)         | |               (_)     
//	| (___ | |_ _   _| |_ _______  | |     ___   __ _ _  ___ 
//	 \___ \| __| | | | | |_  / _ \ | |    / _ \ / _` | |/ __|
//	 ____) | |_| |_| | | |/ /  __/ | |___| (_) | (_| | | (__ 
//	|_____/ \__|\__, |_|_/___\___| |______\___/ \__, |_|\___|
//	             __/ |                           __/ |       
//	            |___/                           |___/        

/// Represents an entry into a style
public struct styleMember
{
	string name;
	string style;
}

/// A tunel to acces the stylized properties of a div
private auto stylized_imp(bool fromMe, bool insert_debug_prints, T)(T v)
{
	import std.stdio;
	struct Result
	{
		T t;
		public auto ref opDispatch(string s)()
	    {
	    	return get!s();
	    }

	    private auto ref get(string s)()
	    {
	    	static if(insert_debug_prints) write("get ", s, " -- ");

			static if(!__traits(hasMember, t, s) && fromMe)
			{
				static if(insert_debug_prints) writeln("Get Local");
				return stylized_imp!(true, insert_debug_prints)(t.getLocal!s());
			}
			else
			{
				auto style_t = stylized_imp!(true, insert_debug_prints)(t);
				string foo()
				{
					string r = "";
					foreach(sty; t.style)
					{
						if(sty.name == s) r ~= sty.style ~ ";";
					} 
					return r;
				}

				static if(hasStylizedProp!(s, baseType!T)()) 
				{
					baseType!T sup = t;
					mixin("t." ~ s) = mixin("stylized_imp!(fromMe, insert_debug_prints)(sup)." ~ s); 
				}

				enum sty = foo();
				mixin(sty);
				static if(insert_debug_prints) writeln("Style:");
				static if(insert_debug_prints) writeln(sty);
				static if(insert_debug_prints) writeln("-----");

				return stylized_imp!(false, insert_debug_prints)(mixin("t." ~ s));
			}
	    }
	}

	static if(__traits(hasMember, v, "style"))
	    return Result(v);    	
	else
		return v;
}

public auto stylized(bool fromMe = true, T)(T v)
{
	return stylized_imp!(fromMe, false, T)(v);
}

public auto stylized_debug(bool fromMe = true, T)(T v)
{
	import std.stdio;
	writeln("T Name : ", T.stringof);
	writeln("T Style : ", T.style);
	return stylized_imp!(fromMe, true, T)(v);
}

/// Alias to the base type of a type
private template baseType(T)
{
	import std.traits;
	static if(BaseClassesTuple!(T).length > 0)
		alias baseType = BaseClassesTuple!T[0];
	else 
		alias baseType = Object;
}

/// Returns true if the type has a style for s or if the base type has a style for s
private bool hasStylizedProp(string s, T)()
{
	static if(!__traits(hasMember, T, "style")) return false;
	else
	{
		bool foo()
		{
			foreach(sty; T.style)
			{
				if(sty.name == s) return true;
			} 
			return false;
		}

		static if(foo()) return true;
		return hasStylizedProp!(s, baseType!T)();
	}
}

/// Generate the code for a style body
private string style_array_mixin(astNode node)
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

/// A tunel to get locals in another scope
private enum getLocal_mixin = 
q{
	// TODO allow for args to be passed
	auto ref getLocal(string s)()
	{
		return mixin(s);
	}
};

/// A stylize proc override that simply applies all the styles for the current div
public enum new_stylize_mixin = getLocal_mixin ~ 
q{
	override void stylizeProc()
	{
		import std.stdio;
		super.stylizeProc();
		alias t = this;
		auto style_t = stylized(t);
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
	}
};