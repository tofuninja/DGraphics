module util.integerSeq;

import std.meta;

/// Compile time integer seq
template IntegerSeq(int start, int end, int dif = 1) {
	static assert(dif != 0);
	static if(dif > 0) {
		static if(start < end) alias IntegerSeq = AliasSeq!(start, IntegerSeq!(start + dif, end, dif));
		else alias IntegerSeq = AliasSeq!();
	} else {
		static if(start > end) alias IntegerSeq = AliasSeq!(start, IntegerSeq!(start + dif, end, dif));
		else alias IntegerSeq = AliasSeq!();
	}
}