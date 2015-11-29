module world.component;
import std.traits;
import graphics.gui;

public ComponentManager componentList;

mixin template registerComponent(T)
{
	static this()
	{
		import world.management.entityManager;
		if(componentList is null) componentList = new ComponentManager();
		componentList.register!T();
	}
}

class ComponentManager
{
	private struct comEntry
	{
		dstring name;
		dstring fullName;
		size_t hash;
		size_t com_size;
		Component function(void[] data) makeComponent;
	}

	private comEntry[size_t] registered_components;

	this()
	{
		// empty
	}

	void register(T)() if(is(T == struct))
	{
		import std.stdio;
		import std.conv;

		comEntry entry; 
		entry.fullName = typeid(T).to!dstring;
		entry.name = {
		 		auto ids = entry.fullName;
		 		uint loc = ids.length;
		 		for(;loc > 0; loc--) if(ids[loc-1] == '.') break;
		 		return ids[loc .. $];
		 	}();

		entry.hash = hashOf(entry.fullName);
		entry.com_size = T.sizeof;

		registered_components[entry.hash] = entry;
	}
}


class Component
{
	uint id;
	public abstract void editProperties(PropertyPane pane);
}

