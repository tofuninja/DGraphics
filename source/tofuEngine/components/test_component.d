module tofuEngine.components.test_component;
import tofuEngine;
import core.time;

import std.stdio;

mixin registerComponent!TestComponent;
class TestComponent : Component
{
	int x;
	int y;

	void message(OwnerMoveMsg msg) {
		writeln("owner move");
	}

	void message(EditorSelectMsg msg) {
		writeln("select ", msg.selected);
	}

	void message(EditorChangeMsg msg) {
		writeln("Change x:", x, " y:", y);
	}
}
