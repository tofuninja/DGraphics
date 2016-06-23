module graphics.gui.verticalArrangement;
import graphics.hw;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
//import util.event;

// TODO horizontal arangement 
class VerticalArrangement : div
{
	public float padding = 0;
	public override void doStylize() {
		import std.range;

		stylizeProc();
		doEventStylize();

		Rectangle b = Rectangle(0,0,0,0);
		float pen = 0;
		foreach(div d; childrenList[].retro) {
			d.doStylize();
			d.bounds.loc.y = pen;
			b.expandToFit(d.bounds);
			pen += d.bounds.size.y + padding;
		}

		this.bounds.size = b.size;
	}
}