module world.entity;
import math.matrix;
import settings;
import container.clist;
import graphics.gui;


class Entity{
	dstring name;
	@NoPropertyPane uint id;
	private uint comids = 0;
	private CList!Component component_list;
	this(uint id)
	{
		this.id = id;
	}

	public void addComponent(Component com)
	{
		component_list.insertBack(com);
		com.id = comids;
		com.addProc(this);
		comids++; // Each new 
	}

	public auto components()
	{
		return component_list.Range();
	}
}

class Component
{
	@NoPropertyPane uint id;
	dstring name;
	public abstract void editProperties(PropertyPane pane);
	public void addProc(Entity e) {}
}

class testComponent : Component
{
	int testProp;
	int other;


	public override void editProperties(PropertyPane pane)
	{
		// This will almost always be the same override
		// but because setData is a template(it has to be)
		// you need to always override it.
		auto t = this;
		pane.setData(t);
	}
}

