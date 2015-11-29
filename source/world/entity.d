module world.entity;
import math.matrix;
import settings;
import container.clist;
import graphics.gui;
import world.management.entityManager;
import world.component;

class Entity{
	dstring name;
	@NoPropertyPane uint id;

	private CList!Component component_list;

	this(uint id, Component[] coms...)
	{
		this.id = id;
		uint coms_id = 0;
		foreach(c; coms)
		{
			component_list.insertBack(c);
			c.id = coms_id;
			coms_id++;
		}
	}

	public auto components()
	{
		return component_list.Range();
	}
}

