module util.event;

struct Event(ARGS...) {
	import std.container.dlist;
	import std.algorithm;
	import std.range;
	private DList!(bool delegate(ARGS)) subscriptions;
	
	void opCall(ARGS args) {
		// if the delegate returns true, then remove it from subscriptions.... 
		remove!(a => a(args))(subscriptions[]);
	}

	/*
	void subscribe(bool delegate(ARGS) d) {
		subscriptions.insert(d);
	}
	
	void opOpAssign(string op : "+")(bool delegate(ARGS) d) {
		subscribe(d);
	}
	*/

	void subscribe(T)(T f) {
		import std.functional;
		bool delegate(ARGS) d = f.toDelegate();
		subscriptions.insert(d);
	}
	
	void opOpAssign(string op : "+", T)(T d) {
		subscribe(d);
	}
}