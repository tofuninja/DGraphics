module util.hasUDA;

/**
 * Determine if a symbol has a given $(LINK2 ../attribute.html#uda, user-defined attribute).
 */
template hasUDA(alias symbol, alias attribute)
{
	import std.typetuple : staticIndexOf;
	import std.traits : staticMap;
	
	static if (is(attribute == struct) || is(attribute == class))
	{
		template GetTypeOrExp(alias S)
		{
			static if (is(typeof(S)))
				alias GetTypeOrExp = typeof(S);
			else
				alias GetTypeOrExp = S;
		}
		enum bool hasUDA = staticIndexOf!(attribute, staticMap!(GetTypeOrExp,
				__traits(getAttributes, symbol))) != -1;
	}
	else
		enum bool hasUDA = staticIndexOf!(attribute, __traits(getAttributes, symbol)) != -1;
}