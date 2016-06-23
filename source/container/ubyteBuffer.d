module container.ubyteBuffer;
import container.clist;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;
import std.experimental.allocator.gc_allocator;

private enum entrySize = 1024*4;
private struct bufferEntry{
	ushort count = 0;
	ubyte[entrySize] buffer;
}

/// Used to build up a buffer of ubytes
struct ubyteBuffer {
	private CList!bufferEntry list;
	
	/// Write a ubyte array into the buffer
	void write(const(ubyte)[] data) {
		import std.algorithm:min;
		if(list.length == 0) {
			list.insert(bufferEntry());
		}

		while(data.length > 0) {
			bufferEntry* cur = &(list.peekBack());

			int amountLeft = entrySize - cur.count;
			assert(amountLeft >= 0);
			if(amountLeft == 0) {
				list.insertBack(bufferEntry());
				cur = &(list.peekBack());
				amountLeft = entrySize;
			}
			
			int amountToWrite = min(data.length, amountLeft);
			assert(amountToWrite > 0);
			cur.buffer[cur.count .. cur.count + amountToWrite][] = data[0 .. amountToWrite][];
			cur.count += amountToWrite;
			data = data[amountToWrite .. $];
		}
	}
	
	/// Converts data to ubyte array and writes it to the buffer
	void write(T)(ref T data) {
		import std.traits:isArray;
		static if(isArray!T) {
			const(void)[] arr = data;
		} else {
			const(void)[] arr = (&data)[0 .. 1];
		}
		write(cast(const(ubyte)[])arr);
	}
	
	/// Clears the data in the buffer
	void clear() {
		list.clear();
	}
	
	/// Current number of ubytes in buffer
	size_t length() {
		if(list.length == 0) return 0;
		return (list.length - 1)*entrySize + list.peekBack().count;
	}
	
	/// Mallocs a ubyte buffer and copies the current data into it
	ubyte[] getBuffer() {
		return getBufferAlloc(Mallocator.instance);
	}

	/// GC allocates a ubyte buffer and copies the current data into it
	ubyte[] getBufferGC() {
		return getBufferAlloc(GCAllocator.instance);
	}
	
	/// Allocates a ubyte buffer and copies the data into it
	ubyte[] getBufferAlloc(Alloc)(ref Alloc a) {
		size_t size = this.length();
		if(size == 0) return null;

		ubyte[] ret = a.makeArray!ubyte(size);
		size_t loc = 0;
		foreach(ref bufferEntry ent; list[]) {
			ret[loc .. loc + ent.count][] = ent.buffer[0 .. ent.count][];
			loc += ent.count;
			assert(loc <= size);
		}
		assert(loc == size);
		return ret;
	}
}

unittest{
	import std.algorithm:equal;
	ubyteBuffer buf;
	int a = 5;
	buf.write(a);

	{
		ubyte[] test = [5,0,0,0];
		assert(equal(buf.getBufferGC(), test));
	}

	{
		ubyte[10000] data;
		data[] = 9;
		buf.write(data);
	}

	{
		ubyte[] test1 = [5,0,0,0];
		ubyte[10000] test2;
		test2[] = 9;
		assert(equal(buf.getBufferGC(), test1 ~ test2));
	}

	{
		string data = "test";
		buf.write(data);
	}

	{
		ubyte[] test1 = [5,0,0,0];
		ubyte[10000] test2;
		test2[] = 9;
		string data = "test";
		ubyte[] test3 = cast(ubyte[])(data);
		assert(equal(buf.getBufferGC(), test1 ~ test2 ~ test3));
	}

	{
		assert(buf.length == 4+10000+4);
	}

	{
		buf.clear();
		assert(buf.length == 0);
		assert(buf.getBufferGC() == null);
		ubyte[] test1 = [];
		assert(equal(buf.getBufferGC(),test1));
	}
}