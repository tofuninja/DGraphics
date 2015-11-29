module graphics.gui.propertyPane;

import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

import graphics.gui.scrollbox;
import graphics.gui.verticalArrangement;
import graphics.gui.label;
import std.experimental.allocator.mallocator;
import std.traits;

public enum NoPropertyPane;

// TODO handle arrays
// TODO handle Clist

class PropertyPane : Scrollbox
{
	public Event!(div) onValueChange;
	public void setData(T)(ref T t)
	{
		alias prop = getPropPane!T; 
		T* pointer = &t;
		auto d = new prop(pointer, this);

		this.childrenList.clear();
		this.childrenList.insert(horz);
		this.childrenList.insert(vert);
		d.bounds.loc = vec2(3,3);
		addDiv(d);
		this.scroll = vec2(0,0);
	}

	public void clearData()
	{
		this.childrenList.clear();
		this.childrenList.insert(horz);
		this.childrenList.insert(vert);
		this.scroll = vec2(0,0);
	}

	public void doValueChange()
	{
		onValueChange(this);
	}
}

private template getPropPane(T)
{
	static if(
		is(T.PropertyPane) && 
		is(T.PropertyPane : div) && 
		__traits(compiles, function(){
			T* t = null;
			PropertyPane owner = new PropertyPane();
			auto p = new T.PropertyPane(t, owner); // Ensure that the property pane type has a constructor that takes a pointer
		}))
		alias getPropPane = T.PropertyPane;
	else static if(is(TypePropertyPane!T))
		alias getPropPane = TypePropertyPane!T;
	else 
		alias getPropPane = DefaultPropertyPane!T;
}

class DefaultPropertyPane(T) : VerticalArrangement
{
	private enum margin_size = 20;
	private PropertyPane owner;
	public dstring display_name = Unqual!(T).stringof;

	private T* data;

	this(T* pointer, PropertyPane owner)
	{
		data = pointer;
		this.owner = owner;
	}

	protected override void initProc()
	{
		if(data == null)
		{
			div d = new customLabel();
			d.text = "null-pointer";
			addDiv(d);
			return;
		}

		uint added = 0;
		static if(__traits(compiles, __traits(allMembers, T))) 
		{
			
			foreach(m; __traits(allMembers, T))
			{
				static if(
					__traits(compiles, typeof(mixin("T." ~ m))) &&						// Member has a type
					!isCallable!(mixin("T." ~ m)) && 									// Member not a function
					isAssignable!(typeof(mixin("T." ~ m))) && 							// Member is assignable 
					!hasUDA!(mixin("T." ~ m), NoPropertyPane) &&						// The member wants to be set from the property pane
					__traits(compiles, function(T tt, typeof(mixin("T." ~ m)) mm){
							mixin("tt." ~ m ~ "= mm;");									// Member is "really" assignable... 
							mixin("auto temp1 = &(tt." ~ m ~ ");"); 					// can take the address of it
						})
					)
				{
					alias MemT = typeof(mixin("T." ~ m));
					alias prop = getPropPane!MemT; 
					MemT* pointer = &mixin("(*data)." ~ m);
					auto d = new prop(pointer, owner);

					// Add a name label
					auto l = new customLabel();
					static if(hasMember!(prop, "display_name"))
					{
						l.text = m ~ ": " ~ d.display_name;
					}
					else l.text = m ~ ":";
					addDiv(l);

					// Add the property pane
					d.bounds.loc.x = margin_size;
					addDiv(d);
					added ++;
				}
			}
		}
		if(added == 0) {
			div d = new customLabel();
			d.text = "n/a";
			addDiv(d);
		}
	}

	override protected void stylizeProc() {
		super.stylizeProc();
		this.textcolor = this.divparent.textcolor;
		this.background = this.divparent.background;
		this.foreground = this.divparent.foreground;
		padding = 3;
	}
}

private class customLabel : Label { 
	override protected void stylizeProc() {
		super.stylizeProc();
		this.textcolor = this.divparent.textcolor;
	}
}

//	  _____ _        _               _____                           _         _____                 
//	 / ____| |      (_)             |  __ \                         | |       |  __ \                
//	| (___ | |_ _ __ _ _ __   __ _  | |__) | __ ___  _ __   ___ _ __| |_ _   _| |__) |_ _ _ __   ___ 
//	 \___ \| __| '__| | '_ \ / _` | |  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | |  ___/ _` | '_ \ / _ \
//	 ____) | |_| |  | | | | | (_| | | |   | | | (_) | |_) |  __/ |  | |_| |_| | |  | (_| | | | |  __/
//	|_____/ \__|_|  |_|_| |_|\__, | |_|   |_|  \___/| .__/ \___|_|   \__|\__, |_|   \__,_|_| |_|\___|
//	                          __/ |                 | |                   __/ |                      
//	                         |___/                  |_|                  |___/                       
import graphics.gui.textbox;
class TypePropertyPane(T) : Textbox if(isSomeString!T)
{
	private PropertyPane owner;
	T* data;
	this(T* pointer, PropertyPane owner)
	{
		import std.conv;
		this.owner = owner;
		data = pointer;
		if(pointer != null) value = to!dstring(*pointer);
	}

	override protected void stylizeProc() {
		super.stylizeProc();
		this.textcolor = this.divparent.textcolor;
		this.background = this.divparent.background;
		this.foreground = this.divparent.foreground;
		this.bounds.size.x = 200;
		this.text = Unqual!(T).stringof;
	}

	override public void invalidate()
	{
		import std.conv;
		if(data != null) {
			*data = to!T(this.value);
			owner.doValueChange();
		}
		super.invalidate();
	}
}

//	 _   _                           _        _____                           _         _____                 
//	| \ | |                         (_)      |  __ \                         | |       |  __ \                
//	|  \| |_   _ _ __ ___   ___ _ __ _  ___  | |__) | __ ___  _ __   ___ _ __| |_ _   _| |__) |_ _ _ __   ___ 
//	| . ` | | | | '_ ` _ \ / _ \ '__| |/ __| |  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | |  ___/ _` | '_ \ / _ \
//	| |\  | |_| | | | | | |  __/ |  | | (__  | |   | | | (_) | |_) |  __/ |  | |_| |_| | |  | (_| | | | |  __/
//	|_| \_|\__,_|_| |_| |_|\___|_|  |_|\___| |_|   |_|  \___/| .__/ \___|_|   \__|\__, |_|   \__,_|_| |_|\___|
//	                                                         | |                   __/ |                      
//	                                                         |_|                  |___/                       
class TypePropertyPane(T) : Textbox if(isNumeric!T)
{
	private PropertyPane owner;
	T* data;
	this(T* pointer, PropertyPane owner)
	{
		import std.conv;
		this.owner = owner;
		data = pointer;
		if(pointer != null) value = to!dstring(*pointer);
	}

	override public void invalidate()
	{
		import std.conv;
		if(data != null) {
			try{
				*data = to!T(this.value);
			}
			catch(Exception e)
			{
				*data = T.init;
			}
			owner.doValueChange();
		}
		super.invalidate();
	}

	override protected void stylizeProc() {
		super.stylizeProc();
		this.textcolor = this.divparent.textcolor;
		this.background = this.divparent.background;
		this.foreground = this.divparent.foreground;
		this.bounds.size.x = 75;
		this.text = Unqual!(T).stringof;
	}

	override protected void charProc(dchar c) {
		auto temp = value;
		auto tempInsert = insertLoc;
		super.charProc(c);
		if(dfa) return;
		value = temp;
		insertLoc = tempInsert;
	}

	override protected void keyProc(key k, keyModifier mods, bool down)
	{
		auto temp = value;
		auto tempInsert = insertLoc;
		super.keyProc(k, mods, down);
		if(dfa) return;
		value = temp;
		insertLoc = tempInsert;
	}
	
	// Verifies the input is a valid number
	private bool dfa()
	{
		uint input_loc = 0;
		dchar x = 0;
		dchar next()
		{
			if(input_loc < value.length) return value[input_loc];
			else return 0;
		}

		bool pop(){
			x = next();
			input_loc ++;
			if(x == 0) return true;
			return false;
		}

		bool integer()
		{
			while(true)
			{
				if(x >= '0' && x <= '9') { if(pop) return true; }
				else break; 
			}
			return false;
		}

		bool blank()
		{
			while(true)
			{
				if(x == ' ' || x == '\t') { if(pop) return true; }
				else break; 
			}
			return false;
		}

		if(pop) return true;
		if(blank) return true;
		static if(isSigned!T) if(x == '-' && pop) return true;
		if(blank) return true;
		static if(isFloatingPoint!T)
		{
			if(x == 'n')
			{
				if(pop) return true;
				if(x == 'a')
				{
					if(pop) return true;
					if(x == 'n' && pop) return true;
				}
				return false;
			}

			if(x == 'i')
			{
				if(pop) return true;
				if(x == 'n')
				{
					if(pop) return true;
					if(x == 'f' && pop) return true;
				}
				return false;
			}
		}

		if(!(x >= '0' && x <= '9')) return false;
		if(integer) return true;

		static if(!isIntegral!T)
		{
			if(x == '.')
			{
				if(pop) return true;
				if(!(x >= '0' && x <= '9')) return false;
				if(integer) return true;
			}

			if(blank) return true;

			if(x == 'e' || x == 'E')
			{
				if(pop) return true;
				if(blank) return true;
				if(!(x >= '0' && x <= '9')) return false;
				if(integer) return true;
			}
		}

		return false;
	}
}


//	__      __       _               _____                 _____                 
//	\ \    / /      | |             |  __ \               |  __ \                
//	 \ \  / /__  ___| |_ ___  _ __  | |__) | __ ___  _ __ | |__) |_ _ _ __   ___ 
//	  \ \/ / _ \/ __| __/ _ \| '__| |  ___/ '__/ _ \| '_ \|  ___/ _` | '_ \ / _ \
//	   \  /  __/ (__| || (_) | |    | |   | | | (_) | |_) | |  | (_| | | | |  __/
//	    \/ \___|\___|\__\___/|_|    |_|   |_|  \___/| .__/|_|   \__,_|_| |_|\___|
//	                                                | |                          
//	                                                |_|                          

private struct vecPass(T, int L)
{
	static if( L > 0 ) T x;
	static if( L > 1 ) T y;
	static if( L > 2 ) T z;
	static if( L > 3 ) T w;
}

class TypePropertyPane(T) : DefaultPropertyPane!(vecPass!(T.elementType, T.rows))
	if(isMatrix!T && T.isVector && T.rows >= 1 && T.rows <= 4)
{
	private PropertyPane owner;
	alias vp = vecPass!(T.elementType, T.rows);
	alias L = T.rows;
	vp v;
	T* data;

	this(T* pointer,  PropertyPane owner)
	{
		import std.conv;
		this.owner = owner;
		display_name = "vec" ~ L.to!dstring;
		data = pointer;
		if(pointer == null) super(null);
		else super(&v);
	}

	override public void invalidate()
	{
		super.invalidate();
		if(data != null)
		{
			static if( L > 0 ) data.x = v.x;
			static if( L > 1 ) data.y = v.y;
			static if( L > 2 ) data.z = v.z;
			static if( L > 3 ) data.w = v.w;

			owner.doValueChange();
		}
	}
}


//	 _____      _       _              _____                           _         _____                 
//	|  __ \    (_)     | |            |  __ \                         | |       |  __ \                
//	| |__) |__  _ _ __ | |_ ___ _ __  | |__) | __ ___  _ __   ___ _ __| |_ _   _| |__) |_ _ _ __   ___ 
//	|  ___/ _ \| | '_ \| __/ _ \ '__| |  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | |  ___/ _` | '_ \ / _ \
//	| |  | (_) | | | | | ||  __/ |    | |   | | | (_) | |_) |  __/ |  | |_| |_| | |  | (_| | | | |  __/
//	|_|   \___/|_|_| |_|\__\___|_|    |_|   |_|  \___/| .__/ \___|_|   \__|\__, |_|   \__,_|_| |_|\___|
//	                                                  | |                   __/ |                      
//	                                                  |_|                  |___/                       

class TypePropertyPane(T) : getPropPane!(PointerTarget!T)
	if(isPointer!T)
{
	private PropertyPane owner;
	alias Target = PointerTarget!T;
	this(T* pointer, PropertyPane owner)
	{
		this.owner = owner;
		if(pointer == null) super(null, owner);
		else super(*pointer, owner);
	}
}


//	 _____                           _           ____            
//	|  __ \                         | |         |  _ \           
//	| |__) | __ ___  _ __   ___ _ __| |_ _   _  | |_) | _____  __
//	|  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | | |  _ < / _ \ \/ /
//	| |   | | | (_) | |_) |  __/ |  | |_| |_| | | |_) | (_) >  < 
//	|_|   |_|  \___/| .__/ \___|_|   \__|\__, | |____/ \___/_/\_\
//	                | |                   __/ |                  
//	                |_|                  |___/                   
import graphics.gui.base;
import std.concurrency;

mixin loadUIString!(`
Base propbox_base
{
	PropertyPane prop
	{
		background = RGB(90,90,90);
		foreground = RGB(130, 130, 130);
		textcolor = RGB(255,255,255);
		bounds = fill;
	}
}
`);

/// Opens a window with the message in it, blocks until the message box is closed
public void propertybox(ARGS...)(ref ARGS args)
{
	import std.traits;

	string mix(int count)
	{
		import std.conv;
		string r = "";
		for(int i = 0; i < count; i++)
		{
			string s = i.to!string;
			r ~= "ARGS[" ~ s ~ "]* arg" ~ s ~ ";";
		}
		return r;
	}

	string mix2(int count)
	{
		import std.conv;
		string r = "";
		for(int i = 0; i < count; i++)
		{
			string s = i.to!string;
			r ~= "value.arg" ~ s ~ " = &args[" ~ s ~ "];";
		}
		return r;
	}

	struct T
	{
		mixin(mix(ARGS.length));
	}

	T value;
	mixin(mix2(ARGS.length));

	auto childTid = spawn(&prop_thread!T, cast(shared)&value, thisTid);
	auto wasSuccessful = receiveOnly!(bool);
    assert(wasSuccessful);
}

private void prop_thread(T)(shared T* value, Tid ownerTid)
{
	// Make window
	{
		gameInitInfo info;
		info.fullscreen = false;
		info.size = ivec2(200,300);
		info.title = "Properties";
		Game.init(info);
	}
	T* noshare = cast(T*) value;
	auto box = startUI!propbox_base();
	box.prop.setData(*noshare);
	box.invalidate();
	box.run();
	send(ownerTid, true);
}