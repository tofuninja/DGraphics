module util.getChildClasses;
import container.clist;

// Returns a list of all the classinfo objects for all the classes that are derived from C
CList!ClassInfo getChildClasses(C)() if(is(C == class) || is(C == interface)) { 
	ClassInfo c = C.classinfo;
	auto info = clist!ClassInfo();

	foreach(mod; ModuleInfo) {
		foreach(cla; mod.localClasses) {
			bool hasC(ClassInfo derived) {
				if(derived is null || derived is Object.classinfo) return false;
				else if(derived.base is c) return true;
				else return hasC(derived.base);
			}

			if(hasC(cla))
				info.insertBack(cla);
		}
	}

	return info;
}