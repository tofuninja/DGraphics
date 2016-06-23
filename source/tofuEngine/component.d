module tofuEngine.component;

import std.range;
import std.traits;
import std.meta;
import graphics.gui;

import util.serial2;
import math.matrix;
import tofuEngine.engine;
import tofuEngine.entity;

//	  _____                                       _     __  __                                              _    
//	 / ____|                                     | |   |  \/  |                                            | |   
//	| |     ___  _ __ ___  _ __   ___   ___ _ __ | |_  | \  / | __ _ _ __   __ _  __ _ _ __ ___   ___ _ __ | |_  
//	| |    / _ \| '_ ` _ \| '_ \ / _ \ / _ \ '_ \| __| | |\/| |/ _` | '_ \ / _` |/ _` | '_ ` _ \ / _ \ '_ \| __| 
//	| |___| (_) | | | | | | |_) | (_) |  __/ | | | |_  | |  | | (_| | | | | (_| | (_| | | | | | |  __/ | | | |_  
//	 \_____\___/|_| |_| |_| .__/ \___/ \___|_| |_|\__| |_|  |_|\__,_|_| |_|\__,_|\__, |_| |_| |_|\___|_| |_|\__| 
//	                      | |                                                     __/ |                          
//	                      |_|                                                    |___/                           


abstract class ComEntry
{
	GlobalComponent global; 
	dstring name;
	dstring fullName;
	GUID hash;

	Component	makeComponentFunc();
	Component	dupFunc(Component c);
	void		serialFunc(Serializer s, Component c);
	void		deserialFunc(Deserializer d, Component c);
	void		propFunc(PropertyPane p, Component c);
	void		messageFunc(TypeInfo id, void* content, Component c);

	final bool isGlobal() { return global !is null; }
}                          

final class ComEntryImpl(T) : ComEntry if(is(T == class) && is(T:Component)) {
	override Component makeComponentFunc() {
		static if(is(T:GlobalComponent)) {
			throw new Exception("Cannot make a global component!");
		} else {
			import std.experimental.allocator : make;
			import std.experimental.allocator.mallocator;

			auto c = Mallocator.instance.make!T();
			c.m_entry = this;
			return c;
		}
	}

	override Component dupFunc(Component c) {
		static if(is(T:GlobalComponent)) {
			throw new Exception("Cannot dup a global component!");
		} else {
			T o = cast(T) c;
			T n = cast(T) makeComponentFunc();
			shallow_copy(o,n);
			n.m_entry = this;
			n.m_owner = null;
			return n;
		}
	}

	override void serialFunc(Serializer s, Component c) {
		T t = cast(T) c;
		s.serialize(t);
	}

	override void deserialFunc(Deserializer d, Component c) {
		T t = cast(T) c;
		d.deserialize(t);
	}

	override void propFunc(PropertyPane p, Component c) {
		T t = cast(T) c;
		p.setData(t);
	}

	override void messageFunc(TypeInfo id, void* content, Component c) {
		T t = cast(T) c;
		foreach(M; messageTypes!T) {
			if(id == typeid(M)) {
				auto p = cast(M*)(content);
				t.message(*p);
				return;
			}
		}

		static if(__traits(compiles, (T x, TypeInfo i, void* cont) { x.defaultMessage(i,cont); })) {
			t.defaultMessage(id, content);
		}
	}
}     

abstract class Component
{
	@NoPropertyPane @SerialSkip package {
		ComEntry m_entry;
		Entity m_owner;
	}
	
	@property Entity owner()	{ return m_owner; }
	@property ComEntry entry()	{ return m_entry; }
	//@property Engine engine()	{ return m_owner.engine; }
	//@property Level level() { return this.engine.level; }
	
	final auto getGlobalComponent(T)() {
		return comMan.getGlobal!T();
	}

	final void serialize(Serializer s) {
		m_entry.serialFunc(s, this);
	}

	final void deserialize(Deserializer d) {
		m_entry.deserialFunc(d, this);
	}

	final void editProperties(PropertyPane p) {
		m_entry.propFunc(p, this);
	}

	final Component dup() {
		return m_entry.dupFunc(this);
	}

	final void messageHandeler(TypeInfo id, void* content) {
		m_entry.messageFunc(id, content, this);
	}

	void initCom() {}
	void destCom() {}

	void broadcast(T)(ref T message) {
		messageHandeler(typeid(T), cast(void*)(&message));
	}
}

abstract class GlobalComponent : Component {
	//@NoPropertyPane @SerialSkip package Engine eng;
	@property override Entity owner() { return null; }
	//@property override Engine engine() { return eng; }
}

void removeFromOwner(Component c) {
	Entity e = c.owner;
	e.removeComponent(c);
}

//
//abstract class Component
//{
//    ComEntry entry; 
//    protected bool hasMessageHandelers = false;
//
//    void serialize(Serializer s, MessageContext args);
//    void deserialize(Deserializer d, MessageContext args);
//    void editProperties(PropertyPane);         // Used to edit the properties in the editor
//    Component duplicate() {return null;}	       // Used to make a copy of the component 
//
//    void init(MessageContext args) {}      // Called when the component is created
//    void dest(MessageContext args) {}      // Called when the component is destroyed
//
//
//    // Will use ref T to allow message handelers to write responses back into the message 
//    void message(T)(ref T message, MessageContext args)
//    {
//        if(hasMessageHandelers == false) return;
//        messageHandeler(typeid(T), cast(void*)(&message), args);
//    }
//
//    void messageHandeler(TypeInfo id, void* content, MessageContext args) {}
//
//    auto ref getValue(T)()
//    {
//        if(auto c = cast(com_imp!T)this)
//        {
//            return c.com;
//        }
//        assert(false, "Not a component of that type");
//    }
//}


/// Used to register a component type T 
mixin template registerComponent(T) {
	static this() {
		import tofuEngine.component : reg_com;
		reg_com!T();
	}
}

/// Called by the registerComponent mixin to actually register a component type
void reg_com(T)() {
	if(comMan is null) comMan = new ComponentManager();
	comMan.register!(T)();
}

/// The global component manager, keeps track of all the component types
package ComponentManager comMan;

/// Keeps track of all the component types
public class ComponentManager
{
	ComEntry[GUID] registered_components;
	uint globalCount = 0;

	this() {
		// empty
	}

	void register(T)() if(is(T == class) && is(T:Component)) {
		import std.stdio;
		import std.conv;
		import std.exception:enforce;
		import std.traits : fullyQualifiedName;

		auto entry = new ComEntryImpl!T(); 

		static if(is(T:GlobalComponent)) {
			entry.global = new T(); // make the global version
			entry.global.m_entry = entry;
			globalCount ++;
		}


		enum dstring dname = fullyQualifiedName!(T);
		enum dstring shortname = {
			auto ids = dname;
			uint loc = cast(uint)(ids.length);
			for(;loc > 0; loc--) if(ids[loc-1] == '.') break;
			return ids[loc .. $];
		}();

		entry.fullName = dname;
		entry.name = shortname;

		entry.hash = GUID(entry.fullName);
		enforce(entry.hash !in registered_components, "Wow really? Hash collision, welp guess you should index by the full name then");
		registered_components[entry.hash] = entry;
	}

	ComEntry getComEntry(GUID hash) {
		auto p = hash in registered_components;
		if(p) return *p;
		else return null;
	}

	ComEntry getComEntry(T)() {
		import std.traits : fullyQualifiedName;
		enum dstring dname = fullyQualifiedName!(T);
		auto guid = GUID(dname);
		return getComEntry(guid);
	}

	auto getGlobal(T)() if(is(T:GlobalComponent)) {
		auto entry = getComEntry!T();
		assert(entry.global !is null);
		return cast(T)(entry.global);
	}
}


template messageTypes(T) {
	static if(hasMember!(T, "message")) {
		static if(__traits(compiles, isCallable!(T.message))) {
			static if(isCallable!(T.message)) {
				alias messageTypes = staticMap!(mapPred, Filter!(filterPred, __traits(getOverloads, T, "message")));
			} else alias messageTypes = AliasSeq!();
		} else alias messageTypes = AliasSeq!();
	} else alias messageTypes = AliasSeq!();
}

private template filterPred(alias f) {
	static if(arity!f == 1)
		enum filterPred = true;
	else 
		enum filterPred = false;
}

private template mapPred(alias f) {
	alias mapPred = Parameters!(f)[0];
}

// Component Select Box
// Select a component, block until its selected
// return null on cancel 
ComEntry* componentSelectBox() {
	import math.geo.rectangle;

	// Tree node
	class comTree : TreeView { 
		ComEntry* ent; 
		this(dstring text, ComEntry* e) { ent = e; super(text); }
		override protected void stylizeProc() {
			if(ent == null) {
				if(getDepth == 0) icon = 0;
				else if(expanded) icon = '\uF07C';
				else icon = '\uF07B';
			} else {
				icon = '\uF12E';
			}
			super.stylizeProc;
		}
	}

	// Event Handeler 
	struct eventH{
		bool ok = false;
		ComEntry* selected; 
		Window win;
		void event(EventArgs e) {
			if(e.type != EventType.Action) return;
			if(e.origin.text == "Cancel") {
				ok = false;
				selected = null;
				win.close();
			} else if(e.origin.text == "Ok" && selected != null) {
				ok = true;
				win.close();
			} else if(auto c = cast(comTree)e.origin) {
				if(e.down) selected = c.ent;
			}
		}
	}

	// Set up gui
	auto window = new Window();
	eventH handeler;
	{
		window.fillFirst = true;
		window.bounds.size = vec2(300,500);
		window.text = "Select Component";
		handeler.win = window;
                                                                                                                      
		auto split = new VerticalSplit();
		split.border = false;
		split.flipSplit = true;
		split.split = 40;
		split.allowSlide = false;

		auto scroll = new Scrollbox();
		scroll.fillFirst = true;

		auto top = new comTree("", null);
		top.expanded = true;

		void add(dstring name, TreeView n, ComEntry* com) {
			import std.algorithm : equal;
			int dot = -1;
			for(int i = 0; i < name.length; i++) {
				if(name[i] == '.') {
					dot = i;
					break;
				}
			}

			auto cur = (dot == -1)? name : name[0..dot];
			TreeView target = null;
			foreach(c; n.children) {
				if(equal(c.text, cur)) {
					target = cast(TreeView)c;
					break;
				}
			}

			if(target is null) {
				auto ent	= (dot == -1)? com : null;
				target = new comTree(cur, ent);
				target.eventHandeler = &handeler.event;
				n.addDiv(target);
			}

			if(dot != -1) {
				add(name[dot + 1 .. $], target, com);
			}
		}

		foreach(ref ent; comMan.registered_components) {
			if(ent.global is null) // Not a global com
				add(ent.fullName, top, &ent);
		}
		
		scroll.addDiv(top);

		auto bot = new Panel();
		bot.border = false;
		split.addDiv(scroll);
		split.addDiv(bot);

		auto ok_b = new Button();
		ok_b.bounds = Rectangle(5,5,80,25);
		ok_b.text = "Ok";
		ok_b.eventHandeler = &handeler.event;
		bot.addDiv(ok_b);

		auto cancel_b = new Button();
		cancel_b.bounds = Rectangle(90,5,80,25);
		cancel_b.text = "Cancel";
		cancel_b.eventHandeler = &handeler.event;
		bot.addDiv(cancel_b);

		window.addDiv(split);
	}

	window.waitOnClose();
	return handeler.ok?handeler.selected:null;
}

void shallow_copy(T)(T s, T d) if(is(T == class)) {
	ubyte[] sp = (cast(ubyte*)s)[0..T.classinfo.m_init.length];
	ubyte[] dp = (cast(ubyte*)d)[0..T.classinfo.m_init.length];
	dp[] = sp[];
}