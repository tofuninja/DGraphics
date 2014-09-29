module gui.Panel;

import std.stdio;
import std.container;
import graphics.Image;
import graphics.render;
import graphics.Color;
import graphics.GraphicsState;
import math.matrix;

struct mouseState
{
	vec2 pos;
	int left;
	int right;
	int mid;
}


class Panel
{
	protected DList!Panel children = DList!Panel();
	protected vec2 loc = vec2(0,0);
	protected vec2 windowLoc = vec2(0,0);
	protected vec2 size = vec2(0,0);
	protected Image img;
	protected Panel parent;
	protected BasePanel base;

	public this(vec2 Location, vec2 Size, Panel owner)
	{
		parent = owner;
		base = (owner is null)? null : owner.base;

		loc = Location;
		windowLoc = ((owner is null)? vec2(0) : owner.windowLoc) + loc;
		size = Size;
		if(size != vec2(0,0)) img = Image(cast(int)size.x, cast(int)size.y);
		
		if(owner !is null && owner != this) owner.addChild(this);
	}

	public this(vec2 Location, vec2 Size)
	{
		this(Location, size, basePan);
	}

	public void tick()
	{

	}

	public void mouseMove(mouseState state)
	{

	}

	public void mouseDown(mouseState state)
	{

	}

	public void mouseUp(mouseState state)
	{

	}

	public void mouseEnter(mouseState state)
	{

	}

	public void mouseExit(mouseState state)
	{

	}

	public void keyPress(int key, int scanCode, int action, int mods)
	{
		
	}

	public void charPress(dchar key)
	{
		
	}

	public void addChild(Panel p)
	{
		children.stableInsertFront(p);
	}

	public void removeChild(Panel p)
	{

	}

	private bool inBounds = false;
	final public bool handleMouse(mouseState state)
	{
		auto bound = windowLoc + size;
		if(state.pos.x > windowLoc.x && state.pos.y > windowLoc.y && state.pos.x < bound.x && state.pos.y < bound.y) // Determin if mouse falls in panelBounds
		{
			if(!inBounds)
			{
				mouseEnter(state);
			}

			inBounds = true;
			//writeln("In bounds");
			bool found = false;
			foreach(Panel p; children)
			{
				found = p.handleMouse(state);
				if(found) break;
			}

			if(!found)
			{

				mouseMove(state);
				if(state.left == 1 || state.right == 1 || state.mid == 1)
				{
					// You clicked me *shy face* 
					base.focus = this;
					mouseDown(state);
				}

				if(state.left == -1 || state.right == -1 || state.mid == -1)
				{
					mouseUp(state);
				}
			}
			return true;
		}

		if(inBounds)// mouse exiting
		{
			mouseExit(state);
		}

		inBounds = false;
		return false;
	}

	final public void sendTick()
	{
		tick();
		foreach_reverse(Panel p; children)
		{
			p.sendTick();
		}
	}

	final void composit()
	{
		auto l = windowLoc;

		if(size != vec2(0,0) && base !is null)
		{
			import derelict.opengl3.gl;
			float x = (l.x/base.size.x)*2.0f - 1.0f;
			float y = 1.0f - (l.y/base.size.y)*2.0f;

			glRasterPos2f(x,y);
			glDrawPixels(img.Width, img.Height, GL_RGBA, GL_UNSIGNED_BYTE, img.Data.ptr);
		}

		foreach_reverse(Panel p; children)
		{
			p.composit();
		}
	}
}

class BasePanel : Panel
{
	import derelict.glfw3.glfw3;

	public static mouseState state;
	public Panel focus;

	public this(int w, int h)
	{
		base = this;
		focus = this;
		super(vec2(0,0), vec2(0,0), this);
		size = vec2(w,h);
		state.left = -1;
		state.mid = -1;
		state.right = -1;
	}

	public void featchMouse(GLFWwindow* window)
	{
		int left = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT);
		int mid = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_MIDDLE);
		int right = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT);
		double posx;
		double posy;
		glfwGetCursorPos(window,&posx, &posy);

		if(left == GLFW_PRESS)
		{
			if(state.left < 0) state.left = 0;
			state.left ++;
		}
		else
		{
			if(state.left > 0) state.left = 0;
			state.left --;
		}

		if(mid == GLFW_PRESS)
		{
			if(state.mid < 0) state.mid = 0;
			state.mid ++;
		}
		else
		{
			if(state.mid > 0) state.mid = 0;
			state.mid --;
		}

		if(right == GLFW_PRESS)
		{
			if(state.right < 0) state.right = 0;
			state.right ++;
		}
		else
		{
			if(state.right > 0) state.right = 0;
			state.right --;
		}

		state.pos = vec2(cast(float)posx, cast(float)posy);

		handleMouse(state);
	}
}

class Button : Panel
{
	enum float r = 8;
	enum float bHeight = 4;
	private void delegate() bc;
	private string btntxt;
	public Color color = Color(100,100,100);
	private bool down = true;

	public this(vec2 loc, vec2 size, string text, void delegate() buttonClick, Panel owner)
	{
		super(loc, size, owner); 
		bc = buttonClick;
		btntxt = text;
		drawBtnUp();
	}

	public this(vec2 loc, vec2 size, string text, void delegate() buttonClick)
	{
		this(loc, size, text, buttonClick, basePan);
	}

	private void drawBtnDown()
	{
		import gui.Font;
		if(down) return;
		down = true;
		img.clear(Color(0));
		img.drawRoundedRectangleFill(vec2(0, bHeight),size - vec2(0, bHeight),r,color);
		img.drawRoundedRectangle(vec2(0, bHeight),size - vec2(0, bHeight),r,Color(0,0,0));
		img.drawText(btntxt, size/2 - vec2(btntxt.length*4, 2),  Color(0,0,0));
	}

	private void drawBtnUp()
	{
		if(!down) return;
		down = false;
		import gui.Font;
		Color darker = color;
		darker.A = 220;
		darker = alphaBlend(darker,Color(0));
		img.clear(Color(0));
		img.drawRoundedRectangleFill(vec2(0, size.y - bHeight - r*2),vec2(size.x, bHeight + r*2),r,darker);
		img.drawRoundedRectangle(vec2(0, size.y - bHeight - r*2),vec2(size.x, bHeight + r*2),r,Color(0,0,0));
		img.drawRoundedRectangleFill(vec2(0,0) ,size - vec2(0, bHeight),r,color);
		img.drawRoundedRectangle(vec2(0,0) ,size - vec2(0, bHeight),r,Color(0,0,0));
		img.drawText(btntxt, size/2 - vec2(btntxt.length*4, 2+bHeight),  Color(0,0,0));
	}

	override public void mouseDown(mouseState state) 
	{
		bc();
		drawBtnDown();
	}

	override public void mouseUp( mouseState state) {
		drawBtnUp();
	}

	override public void mouseExit( mouseState state) {
		drawBtnUp();
	}
}


class checkBox : Panel
{
	enum float r = 8;


	private string chktxt;
	public Color color = Color(100,100,100);
	private bool lastDrawValue = true;
	public bool value;
	
	public this(vec2 loc, float length, string text, Panel owner)
	{
		super(loc, vec2(length,30), owner); 
		chktxt = text;
		drawChecked();
	}
	
	public this(vec2 loc, float length, string text)
	{
		this(loc, length, text, basePan);
	}
	
	private void drawChecked()
	{
		import gui.Font;
		if(lastDrawValue == value) return;
		lastDrawValue = value;
		img.clear(Color(0));
		img.drawRoundedRectangleFill(vec2(0, 0), size, r, color);
		img.drawRoundedRectangle(vec2(0, 0), size, r, Color(0,0,0));
		img.drawText(chktxt, vec2(8,11),  Color(0,0,0));

		img.drawBoxFill(vec2(size.x - 20, 10), vec2(10,10), Color(255,255,255));
		img.drawBox(vec2(size.x - 20, 10), vec2(10,10), Color(0,0,0));
		if(value) img.drawBoxFill(vec2(size.x - 18, 12), vec2(6,6), Color(0,0,0));
	}

	override public void tick() 
	{
		drawChecked;
	}

	override public void mouseDown(mouseState state) 
	{
		value = !value;
		drawChecked();
	}
}

class ValueSlider : Panel
{
	private string title;
	private float l;
	private float r;
	private bool down = false;

	public Color color = Color(100,100,100);
	public float value;

	public this(vec2 loc, float length, string text, float left, float right, Panel owner)
	{
		super(loc, vec2(length, 28), owner); 
		title = text;
		l = left;
		r = right;
		value = l;
		drawSlider();
	}

	public this(vec2 loc, float length, string text, float left, float right)
	{
		this(loc, length, text, left, right, basePan);
	}

	override public void tick() 
	{
		import std.algorithm;

		if(down)
		{
			if(BasePanel.state.left < 0) 
			{
				down = false;
			}
			else
			{
				float mousex = BasePanel.state.pos.x;
				value = l + ((mousex - loc.x - 8) / (size.x-16))*(r - l);
				value = max(l, value);
				value = min(r, value);
				drawSlider();
			}
		}
	}

	private void drawSlider()
	{
		import gui.Font;
		import std.conv;
		import graphics.Image;
		enum float roundRecR = 5;
		img.clear(Color(0));

		string vs = value.to!string;
		img.drawRoundedRectangleFill(vec2(0,0),size ,roundRecR,color);
		img.drawRoundedRectangle(vec2(0,0),size,roundRecR,Color(0,0,0));
		img.drawText(title ~ ":" ~ vs, vec2(4, size.y - 12), Color(0,0,0));
		img.drawLine(vec2(8, 8), vec2(size.x - 8, 8), Color(0,0,0));
		img.drawLine(vec2(8, 7), vec2(size.x - 8, 7), Color(70,70,70));
		img.drawLine(vec2(8, 6), vec2(8, 10), Color(0,0,0));
		img.drawLine(vec2(size.x - 8, 6), vec2(size.x - 8, 10), Color(0,0,0));
		
		
		float ratio = (value - l)/(r - l);
		img.drawEllipseFill(vec2(8 + ratio*(size.x-16), 8),vec2(6,6), Color(150,150,150));
		img.drawEllipse(vec2(8 + ratio*(size.x-16), 8),vec2(6,6), Color(0,0,0));
	}

	override public void mouseDown(mouseState state) 
	{
		if(state.left > 0) down = true;
	}
}

class ImageBox : Panel
{

	public this(vec2 loc, vec2 size, Image image, Panel owner)
	{
		super(loc,size,owner);
		setImage(image);
	}

	public this(vec2 loc, vec2 size, Image image)
	{
		this(loc, size, image, basePan);
	}

	public this(vec2 loc, vec2 size, Panel owner)
	{
		super(loc,size,owner);
		img.clear(Color(100,100,100));
		img.drawBox(vec2(0,0),size,Color(0,0,0));
	}

	public this(vec2 loc, vec2 size)
	{
		this(loc, size, basePan);
	}

	public void setImage(Image image)
	{
		img.clear(Color(100,100,100));
		img.drawImage(image, vec2(1,1));
		img.drawBox(vec2(0,0),size,Color(0,0,0));
	}

}

class label : Panel
{
	import gui.Font;
	enum float r = 8;
	enum int boarder = 8;
	public Color color = Color(100,100,100);
	public this(vec2 loc, string txt, Panel owner)
	{
		super(loc, txt.renderSize + vec2(boarder*2,boarder*2), owner);

		img.clear(Color(0));
		img.drawRoundedRectangleFill(vec2(0, 0), size, r, color);
		img.drawRoundedRectangle(vec2(0, 0), size, r, Color(0,0,0));
		img.drawText(txt, vec2(boarder,boarder),  Color(0,0,0));
	}
	
	public this(vec2 loc, string txt)
	{
		this(loc, txt, basePan);
	}
}