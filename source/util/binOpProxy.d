module util.binOpProxy;

import std.algorithm : joiner, map;
import std.array : array;
struct __typeproxy(T, string s) {
	enum op = s;
	T payload;
	auto opUnary(string newop)() {
		return __typeproxy!(T,newop~op)(payload);
	}
}

/**
 * Mixin used to highjack unary operators to 
 * extend the binary operator set!
 * 
 * To create a new bin op, take one existing 
 * bin op and appened any number of unary ops 
 * to the end. The very last unary op that 
 * you chose matters the most as it is the 
 * one doing the highjacking and requires the 
 * proxy.
 * 
 * Both of the types on either side of the 
 * operation require the proxy to be inplace 
 * if you want to allow other type on the rhs 
 * of the new ops. 
 * 
 * <proxies> The list of unary ops you wish to 
 *      highjack to make new bin ops out of
 * 
 * Example:
 * 
 * struct test
 * {
 *     mixin(binOpProxy!("~", "*"));
 * 
 *     void opBinary(string op : "+~~", T)(T rhs)
 *     {
 *         writeln("hello!");
 *     }
 * 
 *     void opBinary(string op : "+~+-~*--+++----*", T)(T rhs)
 *     {
 *         writeln("world");
 *     }
 * 
 *     void opBinary(string op, T)(T rhs)
 *     {
 *         writeln("default");
 *     }
 * }
 * 
 */
enum binOpProxy(proxies ...) = `
    import ` ~ __MODULE__ ~ ` : __typeproxy;
    auto opBinary(string op, D : __typeproxy!(T, T_op), T, string T_op) (D rhs) {
        return opBinary!(op~D.op)(rhs.payload);
    }
` ~ [proxies].map!((string a) => `
    auto opUnary(string op : "` ~ a ~ `")() {
        return __typeproxy!(typeof(this),op)(this);
    }
`).joiner.array;
