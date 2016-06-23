module util.serial;
import std.experimental.allocator.mallocator;
import std.experimental.allocator;
import std.exception : enforce;
import std.range;
import std.traits;
import std.digest.md;


//	  _____           _       _ 
//	 / ____|         (_)     | |
//	| (___   ___ _ __ _  __ _| |
//	 \___ \ / _ \ '__| |/ _` | |
//	 ____) |  __/ |  | | (_| | |
//	|_____/ \___|_|  |_|\__,_|_|
//	                            
//	                            

// TODO support for seralizing CList
// TODO this must be changed, it takes too much to serialize even simple things with this

enum NoSerialzie; 

// There really should be something like this already, but there is not... 
/// Checks if Alloc is an allocator 
enum isAllocator(Alloc) = __traits(compiles, {IAllocator alloc = new CAllocatorImpl!Alloc;});

struct SerializerAllocT(Alloc, bool insertChecksums = true) if(isAllocator!(Alloc)) {
	private Alloc alloc;

	@disable this(); 
	this(Alloc a) {
		alloc = a;
	}


	/**
	* Serializes the value out to a ubyte output range
	* Returns the number of ubytes serialized
	*/
	size_t serialize(R, T)(R out_range, T v) if(!is(T == class) && isOutputRange!(R, ubyte)) {
		auto malloc = Mallocator.instance;
		auto malloc_serial = SerializerAlloc(malloc);

		ubyte[] array = malloc_serial.serialize(v);
		scope(exit) if(array) malloc.dispose(array);
		out_range.put(array);

		return array.length;
	}

	/// Same as above but allocates a ubyte[] and serializes it into that, returns the result 
	ubyte[] serialize(T)(T v) if(!is(T == class)) {
		static if(insertChecksums) {
			ubyte[16] checksum; 
			size_t size = doSize(v);
			size_t checksum_size = doSize(checksum);
			size_t size_size = doSize(size);

			ubyte[] array = alloc.makeArray!ubyte(size + checksum_size + size_size);
			scope(failure) if(array) alloc.dispose(array);

			auto checksum_section 	= array[0 .. checksum_size];
			auto size_section 		= array[checksum_size .. checksum_size + size_size];
			auto serial_section 	= array[checksum_size + size_size .. $];

			doSerialize(size, size_section);
			auto real_serial_size = doSerialize(v, serial_section);
			checksum = md5Of(serial_section);
			doSerialize(checksum, checksum_section);
			enforce(real_serial_size == size, "Some one did not report there size corectly!");
			return array;
		} else {
			size_t size = doSize(v);
			size_t size_size = doSize(size);

			ubyte[] array = alloc.makeArray!ubyte(size + size_size);
			scope(failure) if(array) alloc.dispose(array);

			auto size_section 		= array[0 .. size_size];
			auto serial_section 	= array[size_size .. $];

			doSerialize(size, size_section);
			auto real_serial_size = doSerialize(v, serial_section);
			enforce(real_serial_size == size, "Some one did not report there size corectly!");
			return array;
		}
		
	}

	/**
	* Deserializes the result of a previous serialization
	* Certain types will cause an allocation when deserialization such as pointers or dynamic arrays
	* These allocations can be cleaned up with serializer.free(t); 
	*/
	size_t deserialize(R, T)(ref R input_range, out T v) if(!is(T == class) && isInputRange!R && is(ElementType!R == ubyte)) {
		static if(insertChecksums) {
			auto malloc = Mallocator.instance;
			uint amountGrabed = 0;
			void grabFromRange(ubyte[] dest) {
				for(uint i = 0; i < dest.length; i++) {
					enforce(!input_range.empty, "Range ended too soon");
					dest[i] = input_range.front;
					input_range.popFront();
				}
				amountGrabed += dest.length;
			}

			ubyte[] toByteArray(T)(ref T t) {
				return (cast(ubyte*)(&t))[0 .. T.sizeof];
			}


			size_t serial_size;
			ubyte[16] checksum;

			grabFromRange(toByteArray(checksum));
			grabFromRange(toByteArray(serial_size));

			ubyte[] array = malloc.makeArray!ubyte(serial_size);
			scope(exit) malloc.dispose(array);

			grabFromRange(array);
			auto realCheck = md5Of(array);
			enforce(checksum == realCheck, "Checksum did not match, input corupt");
			size_t real_serial_size = doDeserialize(v, array, alloc);
			enforce(real_serial_size == serial_size, "Some one did not report there size corectly!");

			return amountGrabed;
		} else {
			auto malloc = Mallocator.instance;
			uint amountGrabed = 0;
			void grabFromRange(ubyte[] dest) {
				for(uint i = 0; i < dest.length; i++) {
					enforce(!input_range.empty, "Range ended too soon");
					dest[i] = input_range.front;
					input_range.popFront();
				}
				amountGrabed += dest.length;
			}

			ubyte[] toByteArray(T)(ref T t) {
				return (cast(ubyte*)(&t))[0 .. T.sizeof];
			}


			size_t serial_size;
			grabFromRange(toByteArray(serial_size));
			ubyte[] array = malloc.makeArray!ubyte(serial_size);
			scope(exit) malloc.dispose(array);
			grabFromRange(array);
			size_t real_serial_size = doDeserialize(v, array, alloc);
			enforce(real_serial_size == serial_size, "Some one did not report there size corectly!");
			return amountGrabed;
		}
	}

	/**
	* Will deallocate the allocations made by a deserialization 
	*/
	void free(T)(T v) if(!is(T == class)) {
		doFree(v, alloc);
	}

	/**
	* Will return the number of bytes that will be serialized if you serialize v 
	*/
	size_t size(T)(T v) if(!is(T == class)) {
		static if(insertChecksums) {
			ubyte[16] checksum;
			size_t size = doSize(v);
			size_t checksum_size = doSize(checksum);
			size_t size_size = doSize(size);
			return (size + checksum_size + size_size);
		} else {
			size_t size = doSize(v);
			size_t size_size = doSize(size);
			return (size + size_size);
		}
	}
}

/// A GC based serializer
auto Serializer() {
	import std.experimental.allocator.gc_allocator;
	return SerializerAlloc(GCAllocator.instance);
}

/// A Malloc based serializer
auto SerializerMalloc() {
	return SerializerAlloc(Mallocator.instance);
}

/// An alloc based serializer
auto SerializerAlloc(A)(A alloc) if(isAllocator!A) {
	return SerializerAllocT!(A)(alloc);
}

/// A serializer that does not allocate
auto SerializerNoAlloc() {
	import util.memory.noallocator;
	return SerializerAlloc(NoAllocator.instance);
}


// this is probably how the serializer should have been from the start.... 
// this way is alot simpler and does not require doSize... 
// but w/e
import std.range.interfaces;
struct autoSerializer{
	private OutputRange!(ubyte[]) range;
	private MD5 hash;

	this(O)(O outRange) {
		start(outRange);
	}

	void start(O)(O outRange) {
		auto malloc = Mallocator.instance;
		range =  malloc.make!(OutputRangeObject!(O, ubyte[]))(outRange);
		hash.start();
	}

	void serialize(T)(T t) {
		auto malloc = Mallocator.instance;
		auto malloc_serial = SerializerAllocT!(typeof(malloc), false)(malloc);

		ubyte[] array = malloc_serial.serialize(t);
		scope(exit) if(array) malloc.dispose(array);
		hash.put(array);
		range.put(array);
	}

	void end() {
		auto malloc = Mallocator.instance;
		ubyte[16] result = hash.finish();
		range.put(result);
		malloc.dispose(cast(Object)range);
	}
}

struct autoDeserializer
{
	private InputRange!(ubyte) range;
	private MD5 hash;
	
	this(I)(I inputRange) {
		start(inputRange);
	}

	void start(I)(I inputRange) {
		import std.array;
		auto malloc = Mallocator.instance;
		range = malloc.make!(InputRangeObject!(I))(inputRange);
		hash.start();
	}

	void deserialize(T)(ref T t) {
		auto malloc = Mallocator.instance;
		uint amountGrabed = 0;
		void grabFromRange(ubyte[] dest) {
			for(uint i = 0; i < dest.length; i++) {
				enforce(!range.empty, "Range ended too soon");
				dest[i] = range.front;
				range.popFront();
			}
			amountGrabed += dest.length;
		}

		ubyte[] toByteArray(T)(ref T t) {
			return (cast(ubyte*)(&t))[0 .. T.sizeof];
		}


		size_t serial_size;
		grabFromRange(toByteArray(serial_size));
		ubyte[] full = malloc.makeArray!ubyte(serial_size + serial_size.sizeof);
		(cast(size_t*)(full.ptr))[0] = serial_size;
		ubyte[] array = full[serial_size.sizeof..$];
		scope(exit) malloc.dispose(full);

		grabFromRange(array);
		hash.put(full);
		size_t real_serial_size = doDeserialize(t, array, malloc);
		enforce(real_serial_size == serial_size, "Some one did not report there size corectly!");
	}

	void end() {
		void grabFromRange(ubyte[] dest) {
			for(uint i = 0; i < dest.length; i++) {
				enforce(!range.empty, "Range ended too soon");
				dest[i] = range.front;
				range.popFront();
			}
		}

		auto malloc = Mallocator.instance;
		ubyte[16] result = hash.finish();
		ubyte[16] hashInInput;
		grabFromRange(hashInInput);
		enforce(result == hashInInput);
		malloc.dispose(cast(Object)range);
	}
}


//	 _____      _            _       
//	|  __ \    (_)          | |      
//	| |__) | __ ___   ____ _| |_ ___ 
//	|  ___/ '__| \ \ / / _` | __/ _ \
//	| |   | |  | |\ V / (_| | ||  __/
//	|_|   |_|  |_| \_/ \__,_|\__\___|
//	                                 
//	                                 



//	  _____           _       _ _         
//	 / ____|         (_)     | (_)        
//	| (___   ___ _ __ _  __ _| |_ _______ 
//	 \___ \ / _ \ '__| |/ _` | | |_  / _ \
//	 ____) |  __/ |  | | (_| | | |/ /  __/
//	|_____/ \___|_|  |_|\__,_|_|_/___\___|
//	                                      
//	                                      
private size_t doSerialize(T)(T v, ubyte[] array) if(!is(T == class)) {
	static if(hasCustomSerialize!T) {
		alias ts = T;
		return ts.serialize(v, array);
	} else static if(hasTypeSerialize!T) {
		alias ts = typeSerialize!T;
		return ts.serialize(v, array);
	} else static if(isPointer!T) {
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		size_t size = doSerialize(v != null, array);
		if(v != null) size += doSerialize(*v, array[size .. $]);
		return size;
	} else static if(is(T == struct)) {
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		size_t size = 0;
		enum uint mem_count = memberCount!T();
		size += doSerialize(mem_count, array[size .. $]);
		foreach(m; __traits(allMembers, T)) {
			static if(canSerializeMember!(T,m)) {
				size_t member_size = doSize(mixin("v." ~ m)); 
				ubyte[16] id_hash = md5Of(m);
				size += doSerialize(id_hash, array[size .. $]);
				size += doSerialize(member_size, array[size .. $]);
				size += doSerialize(mixin("v." ~ m), array[size .. $]); 
			}
		}
		return size;
	} else static if(isBasicType!T) {
		enforce(array.length >= T.sizeof, "Reached end of store");
		*(cast(Unqual!(T)*)(array.ptr)) = v;
		return T.sizeof;
	} else {
		static assert(0); // class not supported right now :) 
	}
}


//	 _____                      _       _ _         
//	|  __ \                    (_)     | (_)        
//	| |  | | ___  ___  ___ _ __ _  __ _| |_ _______ 
//	| |  | |/ _ \/ __|/ _ \ '__| |/ _` | | |_  / _ \
//	| |__| |  __/\__ \  __/ |  | | (_| | | |/ /  __/
//	|_____/ \___||___/\___|_|  |_|\__,_|_|_/___\___|
//	                                                
//	                                                
private size_t doDeserialize(T, A)(out T v, ubyte[] array, A alloc) if(!is(T == class) && isAllocator!A) {
	static if(hasCustomSerialize!T) {
		alias ts = T;
		return ts.deserialize(v, array, alloc);
	} else static if(hasTypeSerialize!T) {
		alias ts = typeSerialize!T;
		return ts.deserialize(v, array, alloc);
	} else static if(isPointer!T) {
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		bool b;
		size_t size = doDeserialize(b, array, alloc);
		if(b) {
			v = alloc.make!(typeof(*v))();
			size += doDeserialize(*v, array[size .. $], alloc);
		} else v = null;
		return size;
	} else static if(is(T == struct)) {
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		size_t size = 0;
		uint mem_count;
		size += doDeserialize(mem_count, array[size .. $], alloc);
		for(uint i = 0; i < mem_count; i++) {
			ubyte[16] id_hash_in_serial;
			size_t member_size;
			size += doDeserialize(id_hash_in_serial, array[size .. $], alloc);
			size += doDeserialize(member_size, array[size .. $], alloc);

			foreach(m; __traits(allMembers, T)) {
				static if(canSerializeMember!(T,m)) {
					ubyte[16] id_hash = md5Of(m);
					if(id_hash == id_hash_in_serial) {
						auto real_member_size = doDeserialize(mixin("v." ~ m), array[size .. $], alloc); 
						enforce(real_member_size == member_size, "Member size does not mach the amount deserialized, maybe input corupt"); 
					}
				}
			}

			size += member_size;
		}
		
		return size;
	} else static if(isBasicType!T) {
		enforce(array.length >= T.sizeof, "Reached end of input");
		v = *(cast(T*)(array.ptr));
		return T.sizeof;
	} else {
		static assert(0); // class not supported right now :) 
	}
}

//	 ______             
//	|  ____|            
//	| |__ _ __ ___  ___ 
//	|  __| '__/ _ \/ _ \
//	| |  | | |  __/  __/
//	|_|  |_|  \___|\___|
//	                    
//	                    
private void doFree(T, A)(T v, A alloc) if(!is(T == class) && isAllocator!A) {
	static if(hasCustomSerialize!T) {
		alias ts = T;
		ts.free(v, alloc);
		return;
	} else static if(hasTypeSerialize!T) {
		alias ts = typeSerialize!T;
		ts.free(v, alloc);
		return;
	} else static if(isPointer!T) {
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		if(v != null) alloc.dispose(v);
		return;
	} else static if(is(T == struct)) {
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		foreach(m; __traits(allMembers, T)) {
			static if(canSerializeMember!(T,m)) {
				doFree(mixin("v." ~ m), alloc);
			}
		}
		return;
	} else static if(isBasicType!T) {
		return; 
	} else {
		static assert(0); // class not supported right now :) 
	}
}

//	  _____ _         
//	 / ____(_)        
//	| (___  _ _______ 
//	 \___ \| |_  / _ \
//	 ____) | |/ /  __/
//	|_____/|_/___\___|
//	                  
//	                  
private size_t doSize(T)(T v) {
	static if(hasCustomSerialize!T) {
		alias ts = T;
		return ts.serialSize(v);
	} else static if(hasTypeSerialize!T) {
		alias ts = typeSerialize!T;
		return ts.serialSize(v);
	} else static if(isPointer!T) {
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		size_t size = doSize(v != null);
		if(v != null) size += doSize(*v);
		return size;
	} else static if(is(T == struct)) {
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		size_t size = 0;
		enum uint mem_count = memberCount!T();
		size += doSize(mem_count);
		foreach(m; __traits(allMembers, T)) {
			static if(canSerializeMember!(T,m)) {
				size_t member_size = doSize(mixin("v." ~ m)); 
				ubyte[16] id_hash = md5Of(m);
				size += doSize(id_hash);
				size += doSize(member_size);
				size += member_size ; 
			}
		}
		return size;
	} else static if(isBasicType!T) {
		return T.sizeof;
	} else {
		static assert(0); // class not supported right now :) 
	}
}

private template hasCustomSerialize(T) {
	enum hasCustomSerialize = __traits(compiles, 
			function(T x) { 
				//auto alloc = Mallocator.instance;

				//size_t s = x.serialSize; 
				//ubyte[] b = new ubyte[s]; 
				//size_t s2 = x.serialize(b); 
				//T y;
				//size_t s3 = T.deserialize(y, b);
				
				auto alloc = Mallocator.instance;
				//alias ts = typeSerialize!T;
				alias ts = T;
				size_t s = ts.serialSize(x);
				ubyte[] b = new ubyte[s]; 
				size_t s2 = ts.serialize(x,b); 
				T y;
				size_t s3 = ts.deserialize(y, b, alloc);
				ts.free(y, alloc);
			}
		);
}

private uint memberCount(T)() {
	uint count = 0;
	foreach(m; __traits(allMembers, T)) {
		static if(canSerializeMember!(T,m)) {
			count++;
		}
	}
	return count;
}

private template canSerializeMember(T, string m) {
	static if(
			__traits(compiles, typeof(mixin("T." ~ m))) &&			// Member has a type
			!isCallable!(mixin("T." ~ m)) && 						// Member not a function
			__traits(compiles, (T v, ubyte[] b) { doSerialize(mixin("v." ~ m), b); }) && 
			!hasUDA!(mixin("T." ~ m), NoSerialzie)
			) {
		enum canSerializeMember = true;
	} else {
		enum canSerializeMember = false;
	}
}


//	 _______                               _       _ _                  
//	|__   __|                             (_)     | (_)                 
//	   | |_   _ _ __   ___   ___  ___ _ __ _  __ _| |_ _______ _ __ ___ 
//	   | | | | | '_ \ / _ \ / __|/ _ \ '__| |/ _` | | |_  / _ \ '__/ __|
//	   | | |_| | |_) |  __/ \__ \  __/ |  | | (_| | | |/ /  __/ |  \__ \
//	   |_|\__, | .__/ \___| |___/\___|_|  |_|\__,_|_|_/___\___|_|  |___/
//	       __/ | |                                                      
//	      |___/|_|                                                      

private template hasTypeSerialize(T) {
	enum hasTypeSerialize = __traits(compiles, (T x) {
			auto alloc = Mallocator.instance;
			alias ts = typeSerialize!T;
			size_t s = ts.serialSize(x);
			ubyte[] b = new ubyte[s]; 
			size_t s2 = ts.serialize(x,b); 
			T y;
			size_t s3 = ts.deserialize(y, b, alloc);
			ts.free(y, alloc);
		});
}

//	 __  __       _        _      
//	|  \/  |     | |      (_)     
//	| \  / | __ _| |_ _ __ ___  __
//	| |\/| |/ _` | __| '__| \ \/ /
//	| |  | | (_| | |_| |  | |>  < 
//	|_|  |_|\__,_|\__|_|  |_/_/\_\
//	                              
//	                              
import math.matrix;
private template typeSerialize(T)
	if(isMatrix!T || isVector!T) {
	struct mymat
	{
		typeof(T.data) data;
	}

	size_t serialSize(T mat) {
		mymat m;
		return doSize(m);
	}

	size_t serialize(T mat, ubyte[] data) {
		mymat m;
		m.data[] = mat.data[];
		return doSerialize(m, data);
	}

	size_t deserialize(A)(ref T mat, ubyte[] data, A alloc) {
		mymat m; 
		auto size = doDeserialize(m, data, alloc);
		mat.data[] = m.data[];
		return size;
	}

	void free(A)(T mat, A alloc) {

	}
}
static assert(hasTypeSerialize!(vec2));
static assert(hasTypeSerialize!(vec3));
static assert(hasTypeSerialize!(vec4));
static assert(hasTypeSerialize!(mat2));
static assert(hasTypeSerialize!(mat3));
static assert(hasTypeSerialize!(mat4));


//	  _____      _            
//	 / ____|    | |           
//	| |     ___ | | ___  _ __ 
//	| |    / _ \| |/ _ \| '__|
//	| |___| (_) | | (_) | |   
//	 \_____\___/|_|\___/|_|   
//	                          
//	                          
import graphics.color;
private template typeSerialize(T)
	if(is(T == Color)) {
	struct myc
	{
		uint c;
	}

	size_t serialSize(T col) {
		myc m;
		return doSize(m);
	}

	size_t serialize(T col, ubyte[] data) {
		myc m;
		m.c = col.m_RGBA;
		return doSerialize(m, data);
	}

	size_t deserialize(A)(ref T col, ubyte[] data, A alloc) {
		myc m; 
		auto size = doDeserialize(m, data, alloc);
		col.m_RGBA = m.c;
		return size;
	}

	void free(A)(T col, A alloc) {

	}
}
static assert(hasTypeSerialize!(Color));


//	  _____ _        _   _                                   
//	 / ____| |      | | (_)                                  
//	| (___ | |_ __ _| |_ _  ___    __ _ _ __ _ __ __ _ _   _ 
//	 \___ \| __/ _` | __| |/ __|  / _` | '__| '__/ _` | | | |
//	 ____) | || (_| | |_| | (__  | (_| | |  | | | (_| | |_| |
//	|_____/ \__\__,_|\__|_|\___|  \__,_|_|  |_|  \__,_|\__, |
//	                                                    __/ |
//	                                                   |___/ 
private template typeSerialize(T)
	if(isStaticArray!T) {
	size_t serialSize(T v) {
		size_t size = 0;
		foreach(m; v) size += doSize(m); 
		return size;
	}

	size_t serialize(T v, ubyte[] data) {
		size_t size = 0;
		foreach(m; v) size += doSerialize(m, data[size .. $]); 
		return size;
	}

	size_t deserialize(A)(ref T v, ubyte[] data, A alloc) {
		size_t array_length = v.length;
		size_t size = 0;
		for(int i = 0; i < array_length; i++) size += doDeserialize(v[i], data[size .. $], alloc); 
		return size;
	}

	void free(A)(T v, A alloc) {
		foreach(m;v) doFree(m, alloc); 
	}
}

auto test = function(vec2 x) {
	alias T = vec2;
	auto alloc = Mallocator.instance;
	alias ts = typeSerialize!T;
	size_t s = ts.serialSize(x);
	ubyte[] b = new ubyte[s]; 
	size_t s2 = ts.serialize(x,b); 
	T y;
	size_t s3 = ts.deserialize(y, b, alloc);
	ts.free(y, alloc);
};

static assert(hasTypeSerialize!(int[0]));
static assert(hasTypeSerialize!(int[1]));
static assert(hasTypeSerialize!(int[2]));
static assert(hasTypeSerialize!(Color[5]));
static assert(hasTypeSerialize!(vec2[5]));

//	 _____                              _                                   
//	|  __ \                            (_)                                  
//	| |  | |_   _ _ __   __ _ _ __ ___  _  ___    __ _ _ __ _ __ __ _ _   _ 
//	| |  | | | | | '_ \ / _` | '_ ` _ \| |/ __|  / _` | '__| '__/ _` | | | |
//	| |__| | |_| | | | | (_| | | | | | | | (__  | (_| | |  | | | (_| | |_| |
//	|_____/ \__, |_| |_|\__,_|_| |_| |_|_|\___|  \__,_|_|  |_|  \__,_|\__, |
//	         __/ |                                                     __/ |
//	        |___/                                                     |___/ 
private template typeSerialize(T)
	if(isDynamicArray!T) {
	// tries to deal with immutable elements
	// not sure if this is 100% ok to do but seems to work ok for strings which is what I really care about
	static if(is(T E: E[]))
		alias U = Unqual!(E);
	else static assert(0);

	size_t serialSize(T v) {
		size_t size = doSize(v.length);
		foreach(m; v) {
			U u = m;
			size += doSize(u);
		}
		return size;
	}

	size_t serialize(T v, ubyte[] data) {
		size_t size = doSerialize(v.length, data);
		foreach(m; v) {
			U u = m;
			size += doSerialize(u, data[size .. $]); 
		}
		return size;
	}

	size_t deserialize(A)(ref T v, ubyte[] data, A alloc) {
		// To serialize an array, we write the size then the data
		// grab size
		size_t array_length;
		size_t size = doDeserialize(array_length, data, alloc);

		// Make a storage and fill it in
		auto temp = alloc.makeArray!U(array_length);
		for(int i = 0; i < array_length; i++) size += doDeserialize(temp[i], data[size .. $], alloc); 

		v = cast(T)temp;
		return size;
	}

	void free(A)(T v, A alloc) {
		foreach(m;v) {
			U u = m;
			doFree(u, alloc);
		}
		alloc.dispose(cast(U[])v);
	}
}

static assert(hasTypeSerialize!(int[]));
static assert(hasTypeSerialize!(int[]));
static assert(hasTypeSerialize!(int[]));
static assert(hasTypeSerialize!(Color[]));
static assert(hasTypeSerialize!(vec2[]));
static assert(hasTypeSerialize!(string));
static assert(hasTypeSerialize!(dstring));
static assert(hasTypeSerialize!(wstring));



import container.rstring;
private template typeSerialize(T)
	if(is(T== rstring)) {
	size_t serialSize(T v) {
		size_t size = doSize(v.length);
		foreach(m; v) {
			dchar u = m;
			size += doSize(u);
		}
		return size;
	}

	size_t serialize(T v, ubyte[] data) {
		size_t size = doSerialize(v.length, data);
		foreach(m; v) {
			dchar u = m;
			size += doSerialize(u, data[size .. $]); 
		}
		return size;
	}

	size_t deserialize(A)(ref T v, ubyte[] data, A alloc) {
		// To serialize an array, we write the size then the data
		// grab size
		dchar[] a;
		size_t size = doDeserialize(a, data, Mallocator.instance);
		v = a;
		Mallocator.instance.dispose(a);
		return size;
	}

	void free(A)(T v, A alloc) {
		// Nothing to do here, rstring manages it self
	}
}

static assert(hasTypeSerialize!(rstring));









//	 _    _       _ _   _            _   
//	| |  | |     (_) | | |          | |  
//	| |  | |_ __  _| |_| |_ ___  ___| |_ 
//	| |  | | '_ \| | __| __/ _ \/ __| __|
//	| |__| | | | | | |_| ||  __/\__ \ |_ 
//	 \____/|_| |_|_|\__|\__\___||___/\__|
//	                                     
//	                                     

unittest
{
	import std.array;
	import std.algorithm;
	import std.range;

	struct test
	{
		int foo;
		float bar;
		char[] arr;
		char[] arr2;
		int* p1;
		int* p2;
		@NoSerialzie int noserial; 
	}


	// GC serializer
	auto serial = Serializer();

	{
		int* p = null;
		int* r;
		auto a = appender!(ubyte[])();
		serial.serialize(a, p);
		ubyte[] input = a.data;
		serial.deserialize(input, r);
		assert(r == null);
	}

	{
		int* p = new int(5);
		int* r;
		auto a = appender!(ubyte[])();
		serial.serialize(a, p);
		ubyte[] input = a.data;
		serial.deserialize(input, r);
		assert(*r == 5);
	}

	{
		test t1, t2;
		t1.foo = 12;
		t1.bar = 3.1415926f;
		t1.arr = ['a','b'];
		t1.p1 = null;
		t1.p2 = new int(5);

		auto a = appender!(ubyte[])();
		auto size = serial.serialize(a, t1);
		ubyte[] input = a.data;
		serial.deserialize(input, t2);

		assert(size == serial.size(t1));

		assert(t1.foo == t2.foo);
		assert(t1.bar == t2.bar);
		assert(t1.arr.equal(t2.arr));
		assert(t1.arr2.equal(t2.arr2));
		assert(t2.p1 == null);
		assert(*(t2.p2) == 5);
	}

	{
		test t1, t2;
		t1.foo = 12;
		t1.bar = 3.1415926f;
		t1.arr = ['a','b'];
		t1.p1 = null;
		t1.p2 = new int(5);
		t1.noserial = 99;

		auto a = serial.serialize(t1);
		auto input = a;
		serial.deserialize(input, t2);

		assert(a.length == serial.size(t1));

		assert(t1.foo == t2.foo);
		assert(t1.bar == t2.bar);
		assert(t1.arr.equal(t2.arr));
		assert(t1.arr2.equal(t2.arr2));
		assert(t2.p1 == null);
		assert(*(t2.p2) == 5);
		assert(t2.noserial != 99); // Didnt get serialized 
	}


	{
		struct T
		{
			string s;
		}

		T t;
		t.s = "hello world";

		auto a = serial.serialize(t);
	}

	{
		struct T2
		{
			dstring s;
		}

		T2 t;
		t.s = "hello world";

		auto a = serial.serialize(t);
	}

	{
		string t = "hello world";
		auto a = serial.serialize(t);
	}

	{
		struct T3
		{
			int[2] s;
		}

		T3 t;
		T3 t2;
		t.s[0] = 1;
		t.s[1] = 55;

		auto a = serial.serialize(t);
		auto input = a;
		serial.deserialize(input, t2);
		assert(t2.s[0] == 1);
		assert(t2.s[1] == 55);
	}

	{
		struct T4
		{
			vec4 test;
			Color c;
		}

		T4 t;
		T4 t2;
		t.test = vec4(1,2,3,4);
		t.c = RGB(1,2,3);

		auto a = serial.serialize(t);
		auto input = a;
		serial.deserialize(input, t2);
		assert(t2.test == vec4(1,2,3,4));
		assert(t2.c == RGB(1,2,3));
	}

	{
		struct CS_test{
			@NoSerialzie int a;

			static size_t serialSize(CS_test v) {
				return v.a.sizeof;
			}

			static size_t serialize(CS_test v, ubyte[] data) {
				int* p = cast(int*)data.ptr;
				*p = v.a;
				return v.a.sizeof;
			}

			static size_t deserialize(A)(ref CS_test v, ubyte[] data, A alloc) {
				int* p = cast(int*)data.ptr;
				v.a = *p;
				return v.a.sizeof;
			}

			static void free(A)(CS_test v, A alloc) {
				// Nothing to do here
			}
		}

		static assert(hasCustomSerialize!CS_test);

		CS_test t;
		t.a = 5;

		CS_test t2;
		auto a = serial.serialize(t);
		auto input = a;
		serial.deserialize(input, t2);
		assert(t2.a == 5);
	}

	{
		import std.outbuffer;
		auto output = new OutBuffer();
		auto as = autoSerializer(output);
		struct auto_test {
			int i;
			float f;
		}
		auto_test at_1 = auto_test(5, 6);
		auto_test at_2;
		as.serialize(at_1);
		int test_int = 314;
		as.serialize(test_int);
		as.end();

		ubyte[] buffer = output.toBytes();
		auto ads = autoDeserializer(buffer);
		ads.deserialize(at_2);
		int test_int_2;
		ads.deserialize(test_int_2);
		ads.end();

		assert(at_1 == at_2);
		assert(314 == test_int_2);
	}
}

