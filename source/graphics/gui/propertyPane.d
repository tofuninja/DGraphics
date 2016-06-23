module graphics.gui.propertyPane;

import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

import graphics.gui.scrollbox;
import graphics.gui.verticalArrangement;
import graphics.gui.label;
import std.experimental.allocator.mallocator;
import std.traits;

public enum NoPropertyPane;
public enum PropertyPaneButton; 

// Automatic generation of simple ui's 
//class PropertyPane : Scrollbox {
//    private div prop_div = null;
//    public void setData(T)(ref T t) {
//        clearData();
//
//        alias prop = getPropPane!T; 
//        T* pointer = &t;
//        auto d = new prop(pointer, &doValueChange);
//
//        d.bounds.loc = vec2(3,3);
//        addDiv(d);
//        prop_div = d;
//    }
//
//    public void clearData() {
//        if(prop_div !is null)
//            children.remove(prop_div);
//        this.scroll = vec2(0,0);
//        prop_div = null;
//    }
//
//    public void doValueChange() {
//        EventArgs e = { type:EventType.ValueChange };
//        doEvent(e);
//    }
//}





// Automatic generation of simple ui's 
class PropertyPane : Scrollbox {
	private div prop_div = null;

	public void setData(T)(ref T t) {
		clearData();

		alias prop = getPropPane!T; 
		T* pointer = &t;
		auto d = new prop(pointer, &doValueChange);

		d.bounds.loc = vec2(3,3);
		addDiv(d);
		prop_div = d;
	}

	public void clearData() {
		if(prop_div !is null)
			children.remove(prop_div);
		this.scroll = vec2(0,0);
		prop_div = null;
	}

	public void doValueChange() {
		EventArgs e = { type:EventType.ValueChange };
		doEvent(e);
	}
}

private template getPropPane(T) {
	static if(
		is(T.PropertyPane) && 
		is(T.PropertyPane : div) && 
		__traits(compiles, () {
			T* t = null;
			void dummy() {}
			void delegate() d = &dummy;
			auto p = new T.PropertyPane(t, d); // Ensure that the property pane type has a constructor that takes a pointer
		}))
		alias getPropPane = T.PropertyPane;
	else static if(is(TypePropertyPane!T))
		alias getPropPane = TypePropertyPane!T;
	else 
		alias getPropPane = DefaultPropertyPane!T;
}

class DefaultPropertyPane(T) : VerticalArrangement
{	import std.conv;
	private enum margin_size = 20;
	private void delegate() change;
	public dstring display_name = Unqual!(T).stringof.to!dstring;

	private T* data;

	this(T* pointer, void delegate() change_func) {
		data = pointer;
		change = change_func;
	}

	private void myChange() {
		static if(__traits(compiles, () {
			data.onChange();
			})) {
			if(data != null) data.onChange();
		}
		change();
	}

	protected override void initProc() {
		super.initProc();

		if(data == null) {
			div d = new Label();
			d.text = "null-pointer";
			addDiv(d);
			return;
		}

		uint added = 0;
		static if(__traits(compiles, __traits(allMembers, T))) {

			foreach(m; __traits(allMembers, T)) {
				static if(
					__traits(compiles, typeof(mixin("T." ~ m))) &&						// Member has a type
					!isCallable!(mixin("T." ~ m)) && 									// Member not a function
					isAssignable!(typeof(mixin("T." ~ m))) && 							// Member is assignable 
					!hasUDA!(mixin("T." ~ m), NoPropertyPane) &&						// The member wants to be set from the property pane
					__traits(compiles, (T tt, typeof(mixin("T." ~ m)) mm) {
							mixin("tt." ~ m ~ "= mm;");									// Member is "really" assignable... 
							mixin("auto temp1 = &(tt." ~ m ~ ");"); 					// can take the address of it
						})
					) {
					alias MemT = typeof(mixin("T." ~ m));
					alias prop = getPropPane!MemT; 
					MemT* pointer = &mixin("(*data)." ~ m);
					auto d = new prop(pointer, &myChange);

					// Add a name label
					auto l = new Label();
					l.text = m ~ ":";

					static if(__traits(compiles, () {
						d.labelInit(l, m);
					})) {
						d.labelInit(l, m);
					}

					addDiv(l);

					// Add the property pane
					d.bounds.loc.x = margin_size;
					addDiv(d);
					added ++;
				} else static if( // Property Pane Buttons 
					//true
					__traits(compiles, typeof(mixin("T." ~ m))) &&		// Member has a type
					isCallable!(mixin("T." ~ m)) && 					// Member is a function
					hasUDA!(mixin("T." ~ m), PropertyPaneButton) &&		// Has the UDA
					__traits(compiles, (T tt) {					// Can really call it and make a delegate for it
						mixin("tt." ~ m ~ "();");
						void delegate() foo = mixin("&tt." ~ m);
						})
					) {
					void delegate() pointer = &mixin("(*data)." ~ m);
					auto d = new prop_btn(pointer, m, &myChange);                                                

					// Add the property pane
					//d.bounds.loc.x = margin_size;
					addDiv(d);
					added ++;
				}
			}
		}
		if(added == 0) {
			div d = new Label();
			d.text = "n/a";
			addDiv(d);
		}

	}

	override protected void stylizeProc() {
		static if(__traits(compiles, () {
			data.onStylize();
		})) {
			if(data != null) data.onStylize();
		}

		static if(__traits(compiles, () {
			data.onStylize(this);
		})) {
			if(data != null) data.onStylize(this);
		}

		super.stylizeProc();
		padding = 3;
	}

	void labelInit(Label l, dstring mem) {
		l.text = mem ~ ":" ~ display_name;
	}
}

//private class customLabel : Label { 
//	override protected void stylizeProc() {
//		super.stylizeProc();
//		this.textcolor = this.parent.textcolor;
//	}
//}

//	  _____ _        _               _____                           _         _____                 
//	 / ____| |      (_)             |  __ \                         | |       |  __ \                
//	| (___ | |_ _ __ _ _ __   __ _  | |__) | __ ___  _ __   ___ _ __| |_ _   _| |__) |_ _ _ __   ___ 
//	 \___ \| __| '__| | '_ \ / _` | |  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | |  ___/ _` | '_ \ / _ \
//	 ____) | |_| |  | | | | | (_| | | |   | | | (_) | |_) |  __/ |  | |_| |_| | |  | (_| | | | |  __/
//	|_____/ \__|_|  |_|_| |_|\__, | |_|   |_|  \___/| .__/ \___|_|   \__|\__, |_|   \__,_|_| |_|\___|
//	                          __/ |                 | |                   __/ |                      
//	                         |___/                  |_|                  |___/                       
import graphics.gui.textbox;
class TypePropertyPane(T) : Textbox if(isSomeString!T) {
	private void delegate() change;
	T* data;
	this(T* pointer, void delegate() on_change) {
		change = on_change;
		data = pointer;
	}

	override protected void stylizeProc() {
		import std.conv; 
		import std.algorithm;

		super.stylizeProc();
		//this.textcolor = this.parent.textcolor;
		//this.background = this.parent.background;
		//this.foreground = this.parent.foreground;
		//this.hintColor = this.parent.foreground;
		this.bounds.size.x = 200;
		this.text = Unqual!(T).stringof;
		if(data != null && !equal(*data,this.value)) this.value = to!dstring(*data);
	}

	override protected void onChange() {
		import std.conv; 
		import std.algorithm;
		if(data != null && !equal(*data,this.value)) {
			*data = to!T(this.value);
			change();
		}
	}
}





//	          _        _             
//	         | |      (_)            
//	 _ __ ___| |_ _ __ _ _ __   __ _ 
//	| '__/ __| __| '__| | '_ \ / _` |
//	| |  \__ \ |_| |  | | | | | (_| |
//	|_|  |___/\__|_|  |_|_| |_|\__, |
//	                            __/ |
//	                           |___/ 

import container.rstring;
class TypePropertyPane(T) : Textbox if(is(T == rstring)) {
	private void delegate() change;
	T* data;
	this(T* pointer, void delegate() on_change) {

		change = on_change;
		data = pointer;

	}

	override protected void stylizeProc() {
		import std.conv; 
		import std.algorithm;

		super.stylizeProc();
		this.bounds.size.x = 200;
		if(data != null && !equal((*data)[],this.value)) value = data.to!dstring;
	}

	override protected void onChange() {
		import std.algorithm;
		if(data != null && !equal((*data)[],this.value)) {
			*data = this.value;
			change();
		}
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
class TypePropertyPane(T) : Textbox if(isNumeric!T) {
	private void delegate() change;
	T* data;
	T pastv;
	this(T* pointer, void delegate() on_change) {
		import std.conv;
		change = on_change;
		data = pointer;
		if(pointer != null) {
			value = to!dstring(*pointer);
			pastv = *data;
		}
	}

	override protected void onChange() {
		import std.conv;
		if(data != null) {
			auto p = *data;
			try{
				*data = to!T(this.value);
				pastv = *data;
			}
			catch(Exception e) {
				//*data = T.init;
			}

			if(*data != p) change();
		}
	}

	override protected void stylizeProc() {
		import std.conv;
		super.stylizeProc();
		this.bounds.size.x = 75;
		this.text = Unqual!(T).stringof;
		if(hasFocus) return;
		if(data != null && pastv != *data) {
			value = to!dstring(*data);
			pastv = *data;
		}
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

private struct vecPass(V) {
	@NoPropertyPane
	alias L = V.SIZE;
	@NoPropertyPane
	alias T = V.ELEMENT_TYPE;

	@NoPropertyPane
	V* me;

	static if( L > 0 ) T X;
	static if( L > 1 ) T Y;
	static if( L > 2 ) T Z;
	static if( L > 3 ) T W;

	this(V* m) {
		me = m;
	}

	void onStylize() {
		static if( L > 0 ) X = me.x;
		static if( L > 1 ) Y = me.y;
		static if( L > 2 ) Z = me.z;
		static if( L > 3 ) W = me.w;
	}

	void onChange() {
		static if( L > 0 ) me.x = X;
		static if( L > 1 ) me.y = Y;
		static if( L > 2 ) me.z = Z;
		static if( L > 3 ) me.w = W;
	}
}
class TypePropertyPane(T) : DefaultPropertyPane!(vecPass!(T))
	if(isVector!T) {
	vecPass!T v;

	this(T* pointer, void delegate() on_change) {
		import std.conv;
		display_name = "vec" ~ (T.SIZE).to!dstring;
		if(pointer == null) super(null, on_change);
		else {
			v = vecPass!T(pointer);
			super(&v, on_change);
		}
	}
}



//	  ____              _                  _             
//	 / __ \            | |                (_)            
//	| |  | |_   _  __ _| |_ ___ _ __ _ __  _  ___  _ __  
//	| |  | | | | |/ _` | __/ _ \ '__| '_ \| |/ _ \| '_ \ 
//	| |__| | |_| | (_| | ||  __/ |  | | | | | (_) | | | |
//	 \___\_\\__,_|\__,_|\__\___|_|  |_| |_|_|\___/|_| |_|
//	                                                     
//	                                                     
// Display in degrees, not rads

private struct quatPass(Q) {
	import math.conversion;
	@NoPropertyPane
	alias T = Q.ELEMENT_TYPE;

	@NoPropertyPane
	Q* me;

	//T Yaw;
	//T Pitch;
	//T Roll;
	ClamepedValue Yaw   = ClamepedValue(0,-180,180);
	ClamepedValue Pitch = ClamepedValue(0,-180,180);
	ClamepedValue Roll  = ClamepedValue(0,-180,180);

	this(Q* m) {
		me = m;
		auto ypr = (*me).getYPR();

		Yaw   = ClamepedValue(toDeg(ypr.x),-180,180);
		Pitch = ClamepedValue(toDeg(ypr.y),-180,180);
		Roll  = ClamepedValue(toDeg(ypr.z),-180,180);
	}

	void onStylize() {
		//Yaw   = 0;
		//Pitch = 0;
		//Roll  = 0;
	}

	void onChange() {
		*me = Q(toRad(cast(float)(Yaw.value)), toRad(cast(float)(Pitch.value)), toRad(cast(float)(Roll.value)));
	}
}

class TypePropertyPane(T) : DefaultPropertyPane!(quatPass!(T))
	if(isInstanceOf!(QuaternionT, T)) {
	quatPass!T v;

	this(T* pointer, void delegate() on_change) {
		display_name = "Quaternion";
		if(pointer == null) super(null, on_change);
		else {
			v = quatPass!T(pointer);
			super(&v, on_change);
		}
	}
}

//	  _____      _            
//	 / ____|    | |           
//	| |     ___ | | ___  _ __ 
//	| |    / _ \| |/ _ \| '__|
//	| |___| (_) | | (_) | |   
//	 \_____\___/|_|\___/|_|   
//	                          
//	                          

private struct colorPass
{
	@NoPropertyPane
	Color* me;
	@NoPropertyPane
	Label lab;

	//ubyte Red;
	//ubyte Green;
	//ubyte Blue;
	//ubyte Alpha;
	ClamepedValue Red   = ClamepedValue(0,0,255);
	ClamepedValue Green = ClamepedValue(0,0,255);
	ClamepedValue Blue  = ClamepedValue(0,0,255);
	ClamepedValue Alpha = ClamepedValue(0,0,255);

	this(Color* m) {
		me = m;
	}

	void onStylize() {
		Red   = me.R;
		Green = me.G;
		Blue  = me.B;
		Alpha = me.A;
		labStyle();
	}

	void onChange() {
		me.R = cast(ubyte)(Red.value);
		me.G = cast(ubyte)(Green.value);
		me.B = cast(ubyte)(Blue.value);
		me.A = cast(ubyte)(Alpha.value);
		labStyle();
	}

	private void labStyle() {
		import graphics.gui.themes;
		Style def = Themes.Default;
		Color c = *me; // ha, starmie go!
		c.A = 255;
		def.background = c;
		float brightness = perceivedBrightness(c); 
		if(brightness < 0.4f) {
			def.text = RGB(255,255,255);
		}
		lab.setStyle(def);
	}
}


class TypePropertyPane(T) : DefaultPropertyPane!(colorPass)
	if(is(T == Color)) {
	colorPass v;

	this(Color* pointer, void delegate() on_change) {
		display_name = "Color";
		if(pointer == null) super(null, on_change);
		else {
			v = colorPass(pointer);
			super(&v, on_change);
		}
	}

	override void labelInit(Label l, dstring mem) {
		l.text = mem ~ ":" ~ display_name;
		v.lab = l;
		l.border = true;
		l.back = true;
		l.pad = 2;
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
	if(isPointer!T) {
	private void delegate() change;
	alias Target = PointerTarget!T;
	this(T* pointer, void delegate() on_change) {
		change = on_change;
		if(pointer == null) super(null, change);
		else super(*pointer, change);
	}
}


//	 ____              _ 
//	|  _ \            | |
//	| |_) | ___   ___ | |
//	|  _ < / _ \ / _ \| |
//	| |_) | (_) | (_) | |
//	|____/ \___/ \___/|_|
//	                     
//	                     
import graphics.gui.checkbox;
class TypePropertyPane(T) : Checkbox if(is(T == bool)) {
	private void delegate() change;
	T* data;
	this(T* pointer, void delegate() on_change) {
		import std.conv;
		change = on_change;
		data = pointer;
	}

	override protected void stylizeProc() {
		super.stylizeProc;
		if(data != null) value = *data;
	}

	override protected void onChange() {
		import std.conv;
		if(data != null) {
			auto p = *data;
			*data = value;
			if(*data != p) change();
		}
	}
}



//	 _____                           _           _____                   ____        _   _              
//	|  __ \                         | |         |  __ \                 |  _ \      | | | |             
//	| |__) | __ ___  _ __   ___ _ __| |_ _   _  | |__) |_ _ _ __   ___  | |_) |_   _| |_| |_ ___  _ __  
//	|  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | | |  ___/ _` | '_ \ / _ \ |  _ <| | | | __| __/ _ \| '_ \ 
//	| |   | | | (_) | |_) |  __/ |  | |_| |_| | | |  | (_| | | | |  __/ | |_) | |_| | |_| || (_) | | | |
//	|_|   |_|  \___/| .__/ \___|_|   \__|\__, | |_|   \__,_|_| |_|\___| |____/ \__,_|\__|\__\___/|_| |_|
//	                | |                   __/ |                                                         
//	                |_|                  |___/                                                          

import graphics.gui.button;
class prop_btn : Button
{
	private void delegate() data;
	private void delegate() change;
	private dstring button_text;

	this(void delegate() call, dstring name, void delegate() onChange) {
		data = call;
		button_text = name;
		change = onChange;
	}

	override protected void stylizeProc() {
		super.stylizeProc();
		this.bounds.size.x = 100;
		this.bounds.size.y = 18;
		this.text = button_text;
	}

	override protected void pressProc() {
		if(data !is null) data();
		if(change !is null) change();
	}
}



//	 _      _     _      _____      _           _     _____                           _         
//	| |    (_)   | |    / ____|    | |         | |   |  __ \                         | |        
//	| |     _ ___| |_  | (___   ___| | ___  ___| |_  | |__) | __ ___  _ __   ___ _ __| |_ _   _ 
//	| |    | / __| __|  \___ \ / _ \ |/ _ \/ __| __| |  ___/ '__/ _ \| '_ \ / _ \ '__| __| | | |
//	| |____| \__ \ |_   ____) |  __/ |  __/ (__| |_  | |   | | | (_) | |_) |  __/ |  | |_| |_| |
//	|______|_|___/\__| |_____/ \___|_|\___|\___|\__| |_|   |_|  \___/| .__/ \___|_|   \__|\__, |
//	                                                                 | |                   __/ |
//	                                                                 |_|                  |___/ 

/**
* Used to add list selects to property panes
* list should be filled with the options
* The property pane will modify select depending on which option is selected in the property pane
*/
struct ListSelect
{
	dstring[] list; 
	uint select;
	uint paneHeight = 100;

	this(dstring[] options) {
		list = options;
	}
}


import graphics.gui.treeView;
private class listSelectTree : TreeView{
	uint item;
	this(uint i, dstring text) { item = i; super(text); }
	override protected void stylizeProc() {
		super.stylizeProc;
		icon = selected?'\uf111':'\uf10c'; 
	}

}

class TypePropertyPane(T) : Scrollbox if(is(T == ListSelect)) {
	private void delegate() change;
	private TreeView tree;

	T* data;
	uint h = 100;
	this(T* pointer, void delegate() on_change) {
		import std.conv;
		tree = new TreeView();
		addDiv(tree);
		change = on_change;
		data = pointer;
		if(pointer != null) {
			h = pointer.paneHeight;
			foreach(i,s;data.list) {
				auto ls = new listSelectTree(cast(uint)i,s);
				tree.addDiv(ls);
				ls.eventHandeler = &event_handeler;
			}
		}
	}

	override protected void stylizeProc() {
		this.border = true;
		this.bounds.size.x = 400;
		this.bounds.size.y = h;
		this.fillFirst = true;
		super.stylizeProc();
	}

	private void event_handeler(EventArgs e) {
		if(e.type == EventType.Action && e.down) {
			if(auto ls = cast(listSelectTree)e.origin) {
				uint p = data.select;
				data.select = ls.item;
				if(p != data.select) change();
			}
		}
	}
}

// 	  _____ _                                _  __      __   _            
// 	 / ____| |                              | | \ \    / /  | |           
// 	| |    | | __ _ _ __ ___  _ __   ___  __| |  \ \  / /_ _| |_   _  ___ 
// 	| |    | |/ _` | '_ ` _ \| '_ \ / _ \/ _` |   \ \/ / _` | | | | |/ _ \
// 	| |____| | (_| | | | | | | |_) |  __/ (_| |    \  / (_| | | |_| |  __/
// 	 \_____|_|\__,_|_| |_| |_| .__/ \___|\__,_|     \/ \__,_|_|\__,_|\___|
// 	                         | |                                          
// 	                         |_|                                          


/**
* Used to represent clamped values in the property pane
* min and max or @SerialSkip so they dont bloat any serilized output
*/
struct ClamepedValue{
	import util.serial2 : SerialSkip;
	@SerialSkip
	float min = 0;
	@SerialSkip
	float max = 100;
	float value;
	this(float v, float min, float max) {
		this.value = v;
		this.min = min;
		this.max = max;
	}

	this(float v) {
		this.value = v;
	}

	void opAssign(float v) {
		value = v;
	}
}

import graphics.gui.valueSlider;
class TypePropertyPane(T) : ValueSlider if(is(T == ClamepedValue)) {
	private void delegate() change;
	ClamepedValue* data;
	this(ClamepedValue* pointer, void delegate() on_change) {
		import std.conv;
		change = on_change;
		data = pointer;
	}

	override protected void stylizeProc() {
		if(data != null && !clicked) {
			value = data.value;
			min = data.min;
			max = data.max;
		}
		{
			import std.algorithm : minV = min, maxV = max;
			float dif = max-min;
			this.bounds.size.x = maxV(100, minV(400, dif));
		}
		super.stylizeProc;
	}

	override protected void onChange() {
		import std.conv;
		if(data != null) {
			auto p = data.value;
			data.value = value;
			if(data.value != p) change();
		}
	}
}



//	  _____ _    _ _____ _____  
//	 / ____| |  | |_   _|  __ \ 
//	| |  __| |  | | | | | |  | |
//	| | |_ | |  | | | | | |  | |
//	| |__| | |__| |_| |_| |__| |
//	 \_____|\____/|_____|_____/ 
//	                            
//	                            
import graphics.gui.panel;
import tofuEngine : GUID;
class TypePropertyPane(T) : Panel if(is(T == GUID)) {
	private void delegate() change;
	GUID* data;
	private Textbox tb;

	this(GUID* pointer, void delegate() on_change) {
		back = false;
		border = false;

		tb = new Textbox();
		tb.bounds.size.x = 200;
		tb.allowEdit = false;
		addDiv(tb);

		tb.eventHandeler = &eventH;

		change = on_change;
		data = pointer;
	}

	override protected void stylizeProc() {
		this.bounds.size.x = 230;
		this.bounds.size.y = tb.bounds.size.y;
		//btn.bounds.size.y = tb.bounds.size.y;

		if(data != null) {
			auto p = *data in base.engine.resources.resources;
			if(p != null)
				tb.value = p.guid_string;
			else if(*data == GUID(null))
				tb.value = "NULL-GUID";
			else
				tb.value = "UNKNOWN-GUID";
		}

		super.stylizeProc();
	}

	private void eventH(EventArgs e) {
		if(e.type == EventType.ValueChange) {
			if(data != null) {
				*data = GUID(e.svalue);
			}
		} else if(e.type == EventType.Click && e.down) {
			import util.fileDialogue;
			import std.path;
			import std.range;

			if(data == null) return;
			auto eng = base.engine;

			string fileName;
			if(fileLoadDialogue(fileName)) {
				*data = eng.resources.getGUID(fileName);
				invalidate();
				change();
			}
		}
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
import graphics.gui.window;
/// Opens a window with the message in it, blocks until the message box is closed
public void propbox(ARGS...)(ref ARGS args) {
	namedpropbox("Properties", ivec2(200,300), args);
}

public void namedpropbox(ARGS...)(dstring name, ivec2 size, ref ARGS args) {
	import std.traits;
	static assert(ARGS.length > 0, "No properties to edit");

	static if(ARGS.length == 1) {
		alias T = ARGS[0];
		alias value = args[0];
	} else { // More than 1 arg, make a struct to represent the args
		string mix(int count) {
			import std.conv;
			string r = "";
			for(int i = 0; i < count; i++) {
				string s = i.to!string;
				r ~= "ARGS[" ~ s ~ "]* arg" ~ s ~ ";";
			}
			return r;
		}

		string mix2(int count) {
			import std.conv;
			string r = "";
			for(int i = 0; i < count; i++) {
				string s = i.to!string;
				r ~= "value.arg" ~ s ~ " = &args[" ~ s ~ "];";
			}
			return r;
		}

		struct T {
			mixin(mix(ARGS.length));
		}

		T value;
		mixin(mix2(ARGS.length));
	}

	auto w = new Window();
	w.fillFirst = true;
	w.bounds.size = cast(vec2)size;
	w.text = name;
	auto box = new PropertyPane();
	box.setData(value);
	box.border = false;
	w.addDiv(box);
	w.waitOnClose();
}