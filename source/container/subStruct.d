module container.subStruct;
import std.traits;

/**
 * Used to get the a sub-set of a structs members
 * Any thing antoated with UDA 
*/
struct SubStruct(T, alias UDA)
{
	import std.traits;
	mixin(SubStructStringMixin!(T, UDA)());
	
	void opAssign(T rhs)
	{
		foreach(s; __traits(allMembers, T))
		{
			static if(hasUDA!(mixin("T." ~ s), UDA)) {
				static if(isCallable!(mixin("T." ~ s)) && __traits(compiles,arity!(mixin("T." ~ s))) && arity!(mixin("T." ~ s)) == 0)
				{
					mixin("this." ~ s) = mixin("rhs." ~ s)();
				}
				else static if(!isCallable!(mixin("T." ~ s)))
				{
					mixin("this." ~ s) = mixin("rhs." ~ s);
				}
			}
		}
	}
}

private string SubStructStringMixin(T, alias UDA)()
{
	import std.traits;
	import std.conv;
	string r = "";
	foreach(s; __traits(allMembers, T))
	{
		static if(hasUDA!(__traits(getMember, T, s), UDA)) {
			static if(isCallable!(mixin("T." ~ s)) && __traits(compiles,arity!(mixin("T." ~ s))) && arity!(mixin("T." ~ s)) == 0)
			{
				for(int i = 0; i < __traits(getAttributes, mixin("T." ~ s)).length; i++)
				{
					r ~= "@(__traits(getAttributes, T." ~ s ~")[" ~ i.to!string ~ "]) ";
				}
				r ~= "typeof(T." ~ s ~ "()) " ~ s ~ ";";
			}
			else static if(!isCallable!(mixin("T." ~ s)))
			{
				for(int i = 0; i < __traits(getAttributes, mixin("T." ~ s)).length; i++)
				{
					r ~= "@(__traits(getAttributes, T." ~ s ~")[" ~ i.to!string ~ "]) ";
				}
				r ~= "typeof(T." ~ s ~ ") " ~ s ~ ";";
			}
		}
	}
	return r;
}