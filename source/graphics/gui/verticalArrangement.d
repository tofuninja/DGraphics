module graphics.gui.verticalArrangement;
import graphics.hw.game;
import graphics.gui.div;
import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;
import util.event;

// TODO horizontal arangement 
class VerticalArrangement : div
{
	public float padding = 0;
	private bool flip = false;
	private vec2 expanded;

	mixin(customStyleMixin(`
			bounds.size = expandToFitChildren;
		`));

	public override void doStylize()
	{
		flip = true;
		stylizeProc();
		onStylize(this);
		flip = false;
		this.bounds.size = children_doStylize(this.padding);
	}

	private vec2 children_doStylize(float pad)
	{
		import std.range;
		if(flip) return expanded;

		Rectangle b = Rectangle(0,0,0,0);
		float pen = 0;
		foreach(div d; children().retro)
		{
			d.doStylize();
			d.bounds.loc.y = pen;
			b.expandToFit(d.bounds);
			pen += d.bounds.size.y + pad;
		}

		flip = true;
		expanded = b.size;
		return expanded;
	}

	public override void doAfterStylize()
	{
		flip = false;
	}

	protected vec2 expandToFitChildren(this T)()
	{
		auto t = stylized(cast(T)this);
		return children_doStylize(t.padding);
	}
}