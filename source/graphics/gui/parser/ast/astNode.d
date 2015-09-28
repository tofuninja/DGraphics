module graphics.gui.parser.ast.astNode;
import std.container;
import std.algorithm;
import graphics.gui.parser.ast.astMixins;

class astNode
{
	astNode[] children;
	astNode parrent;

	void replaceSelf(astNode replacement)
	{
		if(parrent is null)
		{
			throw new Exception("Can not replace self if there is no parrent");
		}
		swapRanges(parrent.children[].find(this), [replacement]);
	}

	void addChild(astNode child)
	{
		child.parrent = this;
		children ~= child;
	}

	void visit()
	{
		// do nothing
	}

	string nodeName() { return "astNode"; }

	mixin(astToString("astNode", "children"));
}

class divNode : astNode
{
	string name;
	string className;
	string[] styles;
	this(string Name, string Class, string[] Styles)
	{
		name 		= Name;
		className 	= Class;
		styles 		= Styles;
	}

	mixin(astToString("divNode", "name", "className", "styles", "children"));
	override string nodeName() { return "divNode"; }
}

class styleNode : astNode
{
	string name;
	string[] styles;
	this(string Name, string[] Styles)
	{
		name 		= Name;
		styles 		= Styles;
	}
	
	mixin(astToString("styleNode", "name", "styles", "children"));
	override string nodeName() { return "styleNode"; }
}

class expressionNode : astNode
{
	mixin(astToString("expressionNode"));

	string expressionMixin()
	{
		return "";
	}
	override string nodeName() { return "expressionNode"; }
}

class binOpNode : expressionNode
{
	string op;
	expressionNode left;
	expressionNode right; 
	this(string operator, astNode l, astNode r)
	{
		op 		= operator;
		left 	= cast(expressionNode)l;
		right 	= cast(expressionNode)r;
	}

	override string expressionMixin()
	{
		return left.expressionMixin() ~ op ~ right.expressionMixin();
	}

	mixin(astToString("binOpNode", "op", "left", "right"));
	override string nodeName() { return "binOpNode"; }
}



class nameLookUpNode : expressionNode
{
	string[] names;
	bool sty;
	this(string[] Names, bool stylize = false)
	{
		names = Names;
		sty = stylize;
	}

	override string expressionMixin()
	{
		string r = "(t"; 

		if(sty)
			foreach(string id; names) r ~= ".getStylizedProperty!\"" ~ id ~ "\"()";
		else
			foreach(string id; names) r ~= "." ~ id;

		return r ~ ")";
	}

	mixin(astToString("nameLookUpNode", "names"));
	override string nodeName() { return "nameLookUpNode"; }
}


class numberNode : expressionNode
{
	bool sign;
	uint integer;
	uint fractional;
	this(bool negitiveSign, uint integerPart, uint fragtionalPart)
	{
		sign 		= negitiveSign;
		integer 	= integerPart;
		fractional 	= fragtionalPart;
	}

	override string expressionMixin()
	{
		import std.conv;
		return (sign?"-":"") ~ integer.to!string ~ ((fractional != 0)? "." ~ fractional.to!string:"");
	}

	mixin(astToString("numberNode", "sign", "integer", "fractional"));
	override string nodeName() { return "numberNode"; }
}

class assignStmtNode : astNode
{
	expressionNode left;
	expressionNode right;
	string name;
	this(astNode lvalue, astNode rvalue, string styleName)
	{
		left 	= cast(expressionNode)lvalue;
		right	= cast(expressionNode)rvalue;
		name = styleName;
	}

	mixin(astToString("assignStmtNode", "left", "right"));
	override string nodeName() { return "assignStmtNode"; }
}


class stringTermNode : expressionNode
{
	string value;
	this(string string_value)
	{
		value = string_value;
	}
	
	override string expressionMixin()
	{
		return "\"" ~ value ~ "\"";
	}
	
	mixin(astToString("stringTermNode", "value"));
	override string nodeName() { return "stringTermNode"; }
}


class funcCallExpressionNode : expressionNode
{
	string name;
	astNode[] args;
	this(string func, astNode[] nodes)
	{
		name = func;
		args = nodes;
	}
	
	override string expressionMixin()
	{
		string r = name ~ "( ";
		foreach(arg; args)
		{
			string s = (cast(expressionNode)arg).expressionMixin();
			r ~= s ~ ",";
		}
		r = r[0 .. $-1] ~ ")";
		return r;
	}
	
	mixin(astToString("funcCallExpressionNode", "name", "args"));
	override string nodeName() { return "stringTermNode"; }
}


class boolExpressionNode : expressionNode
{
	bool value;
	this(bool b)
	{
		value = b;
	}
	
	override string expressionMixin()
	{
		if(value) return "true";
		return "false";
	}
	
	mixin(astToString("boolExpressionNode", "value"));
	override string nodeName() { return "boolExpressionNode"; }
}






