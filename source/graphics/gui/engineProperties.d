module graphics.gui.engineProperties;
import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import container.rstring;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;

alias alloc = Mallocator.instance;

import std.path;
import std.file;
import std.conv;

import graphics.gui.treeView;
import graphics.gui.propertyPane;
import graphics.gui.panel;
import graphics.gui.verticalSplit;
import graphics.gui.button;
import graphics.gui.scrollbox;

import tofuEngine;


class EngineProperties : VerticalSplit { 
	private Scrollbox scroll;
	private LevelTree top;
	private PropertyPane bot;
	public EngineTree currentSelect;

	this() {
		scroll = new Scrollbox();
		scroll.fillFirst = true;
		top = new LevelTree(this);
		bot = new PropertyPane();
		bot.eventHandeler = &handeler;
		scroll.addDiv(top);
		addDiv(scroll);
		addDiv(bot);
		percentageSplit = true;
		split = 0.5f;
	}

	private void handeler(EventArgs e) {
		if(e.type == EventType.ValueChange && e.origin is bot) {
			if(currentSelect !is null) currentSelect.change();
		}
	}

	Object selectedItem() {
		if(currentSelect !is null) return currentSelect.item;
		return null;
	}

	void addItem(Object i) {
		top.addItem(i);
		top.selectItem(i);
	}
	
	void removeItem(Object i) {
		top.removeItem(i);
	}

	void selectItem(Object i) {
		top.selectItem(i);
	}
}

class EngineTree : TreeView {
	Object item; 
	this() {
		expanded = true;
	}
	override void selectProc(bool select) {
		auto o = getOwner();
		o.currentSelect = null;
		o.bot.clearData();
		if(select) {
			getOwner().currentSelect = this;
		}
	}

	void change() {}
	void addItem(Object i) {}
	void setData(T)(ref T t) {
		getOwner().bot.setData(t);
	}

	void clearData() {
		getOwner().bot.clearData();
	}

	EngineProperties getOwner() {
		return (cast(LevelTree)getRoot()).owner;
	}

	bool selectItem(Object i) {
		if(i is item) {
			setSelect(true);
			//base.makeFocus(this);
			return true;
		}
		foreach(d; children[]) if(auto et = cast(EngineTree)d) if(et.selectItem(i)) return true;
		return false;
	}

	bool removeItem(Object i) {
		EngineTree found;
		foreach(d; children[]) if(auto et = cast(EngineTree)d) {
			if(et.item is i) {
				found = et;
				break;
			} else {
				if(et.removeItem(i)) return true;
			}
		}
		if(found !is null) {
			found.setSelect(false);
			this.removeDiv(found);
			return true;
		}
		return false;
	}
}


class LevelTree : EngineTree { 
	EntityListTree entList;
	EngineProperties owner;
	this(EngineProperties o) { owner = o; }
	override protected void stylizeProc() {
		if(auto l = cast(Level)item) {
			if(l.name == "") text = "Level: no-name";
			else if(l.name != text) text = "Level: " ~ l.name.to!dstring;
			icon = '\uF1B3';
		} else {
			text = "No Level";
			icon = '\uF05E';
		}
	}

	override void addItem(Object i) {
		if(auto l = cast(Level)i) {
			expanded = true;
			clearData();
			clearSelect();
			children.clear();
			item = l;
			entList = new EntityListTree();
			addDiv(entList);
		} else if(entList) entList.addItem(i);
	}

	override void selectProc(bool select) {
		super.selectProc(select);
		if(select && item !is null) {
			auto l = cast(Level)item;
			setData(l);
		}
	}
	
	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		auto cs = owner.currentSelect;
		if(cs !is this && cs !is null) cs.div.doKey(k,mods,down);
	}
	
}

class EntityListTree : EngineTree {
	private int currentC = -1;
	override protected void initProc() {
		super.initProc;
		auto l = base.engine.level;
		foreach(e; l.entityRange) {
			addEnt(e);
		}
	}

	override protected void stylizeProc() {
		auto l = base.engine.level;
		int c = l.entityCount();
		if(c != currentC) text = "Entities(" ~ c.to!dstring ~ ")";
		currentC = c;
		icon = 0;
	}
	
	override void addItem(Object i) {
		if(auto e = cast(Entity)i) {
			addEnt(e);
		} else if(auto com = cast(Component)i) {
			foreach(c; children[]) {
				auto et = cast(EntityTree)c;
				if(et.item is com.owner()) {
					et.addItem(i);
					return;
				}
			}
		}
	}

	void addEnt(Entity e) {
		addDiv(new EntityTree(e));
	}
}

class EntityTree : EngineTree {
	private entityProperties currentEnt;
	this(Entity e) { item = e; }

	override protected void initProc() {
		super.initProc;
		foreach(c; (cast(Entity)item).getComponents()) {
			addCom(c);
		}
	}

	override void addItem(Object i) {
		if(auto c = cast(Component)i) addCom(c);
	}
	
	void addCom(Component c) {
		EditorGetEntryMsg msg;
		c.broadcast(msg);
		if(msg.entry !is null)
			addDiv(msg.entry);
		else
			addDiv(new ComTree(c));
	}

	override protected void stylizeProc() {
		auto e = cast(Entity)item;
		if(e.name == "") text = "no-name";
		else if(e.name != text) text = e.name.to!dstring;
		icon = '\uF1B2';
	}

	override void selectProc(bool select) {
		super.selectProc(select);
		auto e = cast(Entity)item;
		if(select) {
			currentEnt = entityProperties(e);
			setData(currentEnt);
		}
		auto msg = EditorSelectMsg(select);
		e.broadcast(msg);
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		if(down && k == hwKey.DELETE) {
			if(auto ent = cast(Entity)item) {
				ent.kill();
			}
		}
	}
}

class ComTree : EngineTree { 
	this(Component c) { item = c; }
	override protected void initProc() {
		super.initProc;
		auto msg = EditorEntryMsg(this);
		(cast(Component)item).broadcast(msg);
	}
	
	override void change() {
		auto com = cast(Component)item;
		EditorChangeMsg msg;
		com.broadcast(msg);
	}

	override protected void stylizeProc() {
		auto com = cast(Component)item;
		text = com.entry.name;
		icon = '\uF12E';
	}

	override void selectProc(bool select) {
		super.selectProc(select);
		auto com = cast(Component)item;
		if(select) com.editProperties(getOwner().bot);
		auto msg = EditorSelectMsg(select);
		com.broadcast(msg);
	}

	override protected void keyProc(hwKey k,hwKeyModifier mods,bool down) {
		if(down && k == hwKey.DELETE) {
			if(auto com = cast(Component)item) {
				com.removeFromOwner();
			}
		}
	}
}

//private entityProperties currentEnt;
private struct entityProperties {
	@NoPropertyPane
	private Entity me;

	rstring name;
	vec3 location;
	Quaternion rotation;
	bool dynamic;
	bool persistent;

	this(Entity me) {
		this.me = me;
		onStylize();
	}

	void onStylize() {
		if(me is null) return;
		name = me.getName;
		location = me.getLocation;
		rotation = me.getRotation;
		dynamic = me.dynamic;
		persistent = me.persistent;
	}

	void onChange() {
		if(me is null) return;
		me.move(location, rotation);
		me.setName(name);

		me.dynamic = dynamic;
		me.persistent = persistent;
	}
}

struct EditorEntryMsg{
	EngineTree entry;
}

struct EditorGetEntryMsg{
	EngineTree entry = null;
}


//class compEntry: engPropertiesEntry {
//    Component com; 
//    this(Component c) { com = c; } 
//
//    override void init() {
//        auto msg = EditorEntryMsg(this);
//        com.broadcast(msg);
//    }
//
//    override void style() {
//        text = com.entry.name;
//        icon = "\uF12E";
//    }
//
//    override void select(bool b, PropertyPane props) {
//        if(b) com.editProperties(props);
//        auto msg = EditorSelectMsg(b);
//        com.broadcast(msg);
//    }
//
//    override void change() {
//        EditorChangeMsg msg;
//        com.broadcast(msg);
//    }
//}
//
//class globalComsEntry: engPropertiesEntry {
//    Engine eng;
//    this(Engine e) { eng = e; }
//    override void init() {
//        foreach(ent; eng.componentTypes.registered_components) {
//            if(ent.isGlobal()) {
//                auto c = ent.global;
//                addChild(new globalcompEntry(c));
//            }
//        }
//    }
//
//    override void style() {
//        text = "Global Components";
//        icon = "\uF0AC";
//    }
//}
//
//class globalcompEntry: engPropertiesEntry {
//    Component com; 
//    this(Component c) { com = c; } 
//
//    override void init() {
//        auto msg = EditorEntryMsg(this);
//        com.broadcast(msg);
//    }
//
//    override void style() {
//        text = com.entry.name;
//        icon = "\uF12E";
//    }
//
//    override void select(bool b, PropertyPane props) {
//        if(b) com.editProperties(props);
//        auto msg = EditorSelectMsg(b);
//        com.broadcast(msg);
//    }
//
//    override void change() {
//        EditorChangeMsg msg;
//        com.broadcast(msg);
//    }
//}
//








//class EngineProperties : VerticalSplit {
//    private componentList_div comps;
//    private PropertyPane props;
//    private bool needReset = false;
//    public engPropertiesEntry currentSelect;
//    private levelEntry curLevel;
//
//    this() {
//        comps = new componentList_div();
//        props = new PropertyPane();
//        props.eventHandeler = &paneEvent;
//        comps.owner = this;
//        comps.pane = props;
//        addDiv(comps);
//        addDiv(props);
//        percentageSplit = true;
//        split = 0.5f;
//    }
//
//    void fullReset() {
//        auto eng = base.engine;
//        clearSelect(false);
//        auto tree = comps.tree;
//        tree.clear();
//        tree.data.obj = curLevel = new levelEntry(eng, eng.level);
//        tree.data.obj.node = tree.root;
//        tree.data.obj.init();
//        tree.data.expandOnSelect = false;
//        invalidate();
//    }
//
//    override protected void stylizeProc() {
//        super.stylizeProc;
//        if(comps is null) return;
//        foreach(ref n;  comps.tree.depthfirst()) {
//            if(n.obj !is null) n.obj.style();
//        }
//    }
//
//    void addEntity(Entity e) {
//        if(curLevel !is null) {
//            clearSelect();
//            auto n = curLevel.addEntity(e);
//            selectEntity(e);
//            invalidate();
//        }
//    }
//
//    void removeEntity(Entity e) {
//        clearSelect();
//        comps.tree.Node* f = null;
//        recApply!removeEFun(comps.tree, e, &f);
//        if(f == null) return;
//        auto p = f.getParent();
//        if(p == null) return;
//        p.removeChild(f);
//        invalidate();
//    }
//    
//    private static void removeEFun(comps.tree.Node* node, Entity ent, comps.tree.Node** found) {
//        if(node == null) return;
//        if(node.data.obj is null) return;
//        if(auto c = cast(entityEntry) node.data.obj) {
//            if(c.e is ent) {
//                *found = node;
//            }
//        }
//    }
//
//    void addComponent(Entity e, Component com) {
//        recApply!addComFun(comps.tree, com, e);
//        invalidate();
//    }
//
//    private static void addComFun(comps.tree.Node* node, Component c, Entity e) {
//        if(node == null) return;
//        if(node.data.obj is null) return;
//        if(auto entry = cast(entityEntry) node.data.obj) {
//            if(entry.e is e) {
//                entry.addCom(c);
//            }
//        }
//    }
//
//    void removeComponent(Component c) {
//        clearSelect();
//        comps.tree.Node* f = null;
//        recApply!removeComFun(comps.tree, c, &f);
//        if(f == null) return;
//        auto p = f.getParent();
//        if(p == null) return;
//        p.removeChild(f);
//        invalidate();
//    }
//    
//    private static void removeComFun(comps.tree.Node* node, Component c, comps.tree.Node** found) {
//        if(node == null) return;
//        if(node.data.obj is null) return;
//        if(auto entry = cast(compEntry) node.data.obj) {
//            if(entry.com is c) {
//                *found = node;
//            }
//        }
//    }
//
//    
//    void selectEntity(Entity e)
//    {
//        if(e is null) return;
//        clearSelect();
//        recApply!selectEFun(comps.tree, e, comps);
//        invalidate();
//    }
//    
//    private static void selectEFun(comps.tree.Node* node, Entity ent, componentList_div comps) {
//        if(node == null) return;
//        if(node.data.obj is null) return;
//        if(auto e = cast(entityEntry)node.data.obj) {
//            if(e.e is ent) {
//                node.data.selected = true;
//                comps.select(node);
//            }
//        }
//    }
//
//    void loadPrefab(Entity e) {
//        clearSelect();
//        comps.tree.Node* f = null;
//        recApply!loadPFun(comps.tree, e, &f);
//        if(f == null) return;
//        f.clear();
//        auto c = new entityEntry(e);
//        f.data.obj = c;
//        c.node = f;
//        c.init();
//        invalidate();
//    }
//
//    private static void loadPFun(comps.tree.Node* node, Entity ent, comps.tree.Node** found) {
//        if(node == null) return;
//        if(node.data.obj is null) return;
//        if(auto c = cast(entityEntry) node.data.obj) {
//            if(c.e is ent) {
//                *found = node;
//            }
//        }
//    }
//
//    private void paneEvent(EventArgs args) {
//        if(args.type == EventType.ValueChange)
//        {
//            if(currentSelect is null) return;
//            currentSelect.change();
//        }
//    }
//
//    private void clearSelect(bool call = true) {
//        if(currentSelect !is null && call)
//        {
//            currentSelect.select(false, props);
//        }
//        props.clearData();
//        currentSelect = null;
//        foreach(ref n; comps.tree.depthfirst)
//        {
//            n.selected = false;
//        }
//    }
//}
//
//private void recApply(alias FUN, T, ARGS...)(T t, ARGS args) {
//    foreach(c; t.Children()) {
//        FUN(c,args);
//        recApply!FUN(c, args);
//    }
//}
//
//
//
//
//
//
//private class componentList_div : TreeView!engPropertiesEntry
//{
//    entityProperties currentEntity;
//    PropertyPane pane;
//    EngineProperties owner;
//
//    public override void initProc()
//    {
//        super.initProc();
//    }
//
//    void select(tree.Node* n) {
//        selectProc(n);
//    }
//    override protected void selectProc(tree.Node* n)
//    {
//        if(n == null) return;
//        if(n.data.obj is null) return;
//        n.data.obj.select(n.data.selected, pane);
//        if(n.data.selected) owner.currentSelect = n.data.obj;
//        invalidate();
//    }
//
//}
//
//
//private struct entityProperties
//{
//    @NoPropertyPane
//    private Entity me;
//
//    rstring name;
//    vec3 location;
//    Quaternion rotation;
//    bool dynamic;
//    bool persistent;
//
//    this(Entity me)
//    {
//        this.me = me;
//        onStylize();
//    }
//
//    void onStylize()
//    {
//        if(me is null) return;
//        name = me.getName;
//        location = me.getLocation;
//        rotation = me.getRotation;
//        dynamic = me.dynamic;
//        persistent = me.persistent;
//    }
//
//    void onChange()
//    {
//        if(me is null) return;
//        me.move(location, rotation);
//        me.setName(name);
//
//        me.dynamic = dynamic;
//        me.persistent = persistent;
//    }
//}
//
//class engPropertiesEntry {
//    TreeView!(engPropertiesEntry).tree.Node* node;
//    void select(bool b, PropertyPane props) { if(b) props.clearData(); }
//    void init() {}
//    void style() {}
//    void change() {}
//    auto addChild(engPropertiesEntry c, bool expand = true, bool expandOnSelect = false) {
//        auto dat = TreeView!(engPropertiesEntry).tree.Data();
//        dat.expandOnSelect = expandOnSelect;
//        dat.expand = expand;
//        dat.obj = c;
//        auto n = node.insertBack(dat);
//        c.node = n;
//        c.init();
//        return n;
//    }
//
//    ref dstring text() @property { return node.data.text; }
//    ref dstring icon() @property { return node.data.icon; }
//}
//
//class levelEntry: engPropertiesEntry {
//    Level l; 
//    Engine eng;
//    private entListEntry ents;
//    private globalComsEntry gcoms;
//    this(Engine e, Level lev) { l = lev; eng = e; }
//    override void init() {
//        gcoms = new globalComsEntry(eng);
//        addChild(gcoms, false, true);
//        ents = new entListEntry(l);
//        addChild(ents);
//
//    }
//
//    override void style() {
//        if(l !is null) {
//            if(l.name == "") text = "Level: no-name";
//            else if(l.name != text) text = "Level: " ~ l.name.to!dstring;
//            icon = "\uF1B3";
//        } else {
//            text = "No Level";
//            icon = "\uF05E";
//        }
//    }
//
//    override void select(bool b, PropertyPane props) {
//        if(b) props.setData(l);
//    }
//
//    auto addEntity(Entity e) {
//        return ents.addEntity(e);
//    }
//}
//
//class entListEntry: engPropertiesEntry {
//    Level l; 
//    this(Level lev) { l = lev; }
//    private int currentC = -1;
//    override void init() {
//        foreach(e; l.entityRange)
//        {
//            addChild(new entityEntry(e));
//        }
//    }
//
//    override void style() {
//        int c = l.entityCount();
//        if(c != currentC) text = "Entities(" ~ c.to!dstring ~ ")";
//        currentC = c;
//        icon = "";
//    }
//
//    auto addEntity(Entity e) {
//        return addChild(new entityEntry(e));
//    }
//}
//
//class entityEntry: engPropertiesEntry {
//    Entity e;
//    entityProperties currentEntity;
//
//    this(Entity ent) { e = ent; }
//    override void init() {
//        foreach(c; e.getComponents()) {
//            addChild(new compEntry(c));
//        }
//    }
//
//    override void style() {
//        if(e.name == "") text = " ";
//        else if(e.name != text) text = e.name.to!dstring;
//        icon = "\uF1B2";
//    }
//
//    override void select(bool b, PropertyPane props) {
//        currentEntity = entityProperties(e);
//        if(b) props.setData(currentEntity);
//        auto msg = EditorSelectMsg(b);
//        e.broadcast(msg);
//    }
//
//    void addCom(Component c) {
//        addChild(new compEntry(c));
//    }
//}
//
//class compEntry: engPropertiesEntry {
//    Component com; 
//    this(Component c) { com = c; } 
//
//    override void init() {
//        auto msg = EditorEntryMsg(this);
//        com.broadcast(msg);
//    }
//
//    override void style() {
//        text = com.entry.name;
//        icon = "\uF12E";
//    }
//    
//    override void select(bool b, PropertyPane props) {
//        if(b) com.editProperties(props);
//        auto msg = EditorSelectMsg(b);
//        com.broadcast(msg);
//    }
//
//    override void change() {
//        EditorChangeMsg msg;
//        com.broadcast(msg);
//    }
//}
//
//class globalComsEntry: engPropertiesEntry {
//    Engine eng;
//    this(Engine e) { eng = e; }
//    override void init() {
//        foreach(ent; eng.componentTypes.registered_components) {
//            if(ent.isGlobal()) {
//                auto c = ent.global;
//                addChild(new globalcompEntry(c));
//            }
//        }
//    }
//
//    override void style() {
//        text = "Global Components";
//        icon = "\uF0AC";
//    }
//}
//
//class globalcompEntry: engPropertiesEntry {
//    Component com; 
//    this(Component c) { com = c; } 
//
//    override void init() {
//        auto msg = EditorEntryMsg(this);
//        com.broadcast(msg);
//    }
//
//    override void style() {
//        text = com.entry.name;
//        icon = "\uF12E";
//    }
//
//    override void select(bool b, PropertyPane props) {
//        if(b) com.editProperties(props);
//        auto msg = EditorSelectMsg(b);
//        com.broadcast(msg);
//    }
//
//    override void change() {
//        EditorChangeMsg msg;
//        com.broadcast(msg);
//    }
//}
//
