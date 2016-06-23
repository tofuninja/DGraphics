module util.dump;

mixin template dump(Names ... ) {
	auto _unused_dump = {
		import std.stdio : writeln, write; 
		foreach(i,name; Names) {
			write(name, " = ", mixin(name), (i<Names.length-1)?", ": "\n");
		}
		return false;
	}();
}

//unittest{
//	int x = 5;
//	int y = 3;
//	int z = 15;

//	mixin dump!("x", "y"); // x = 5, y = 3
//	mixin dump!("z");      // z = 15
//	mixin dump!("x+y");    // x+y = 8
//	mixin dump!("x+y < z");// x+y < z = true
//}