module graphics.gui.parser.ast.astMixins;
import std.container;
import std.algorithm;
import std.string;
import std.array;

enum tab = "   ";

/**
 * A string mixin to produce the code for the toString for an astNode.
 * Supply it with the vars that you want printed and the name of the node,
 * and it will produce the code to print them. 
 */
string astToString(string nodeName, string[] names ...)
{
	string mod = __MODULE__;
	string mix = "override string toString() { import " ~ mod ~ "; import std.array;";
	mix ~= "string s = \"" ~ nodeName ~ "\n{\\n\";";
	foreach(string name; names)
	{
		mix ~= "s ~= tab ~ \"" ~ name ~ ": \" ~ _ast_member_toStr(" ~ name ~ ").replace(\"\\n\", \"\\n\" ~ tab) ~ \"\\n\";";
	}
	mix ~= "s ~= \"}\"; return s;}";
	return mix;
}






string _ast_member_toStr(T)(T x)
{
	import std.traits;
	import std.conv;
	static if(isInstanceOf!(DList, T))
		return listToString(x);
	else return x.to!string;
}

private string listToString(T)(DList!T list)
{
	import std.conv;
	if(list.empty) return "{}";
	
	DList!string items;
	bool hasNL = false;
	foreach(T x; list)
	{
		string ts = x.to!string();
		hasNL = hasNL || !ts.find('\n').empty;
		items.insertBack(ts);
	}
	
	if(hasNL)
	{
		string s = "\n{";
		foreach(string x; items)
			s ~= "\n" ~ tab ~ x.replace("\n", "\n" ~ tab) ~ "\n" ~ tab ~ ",";
		return s[0 .. $-(2 + tab.length)] ~ "\n}";
	}
	else
	{
		string s = "{ ";
		foreach(string x; items)
			s ~= x ~ ", ";
		return s[0 .. $-2] ~ " }";
	}
}
