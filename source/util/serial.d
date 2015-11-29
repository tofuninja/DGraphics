module util.serial;
import std.experimental.allocator.mallocator;
import std.experimental.allocator;
import std.exception : enforce;

import std.stdio;

byte[] Serialize(T)(T v) if(!is(T == class))
{
	size_t checksum; 
	size_t size = doSerialize_size(v);
	size_t checksum_size = doSerialize_size(checksum);

	byte[] array = Mallocator.instance.makeArray!byte(size + checksum_size);

	doSerialize(v, array[0 .. size]);
	checksum = hashOf(array[0.. size]);
	doSerialize(checksum, array[size .. $]);

	return array;
}

size_t Deserialize(T)(out T v, byte[] array) if(!is(T == class))
{
	size_t checksum_in_serial;
	size_t size = doDeserialize(v, array);
	size_t checksum_size = doDeserialize(checksum_in_serial, array[size .. $]);
	size_t checksum = hashOf(array[0..size]);
	enforce(checksum == checksum_in_serial, "Checksum did not match, input corupt");
	return size + checksum_size;
}

size_t doDeserialize(T)(out T v, byte[] array) if(!is(T == class))
{
	import std.traits;
	static if(hasCustomSerialize!T)
	{
		return T.deserialize(v, array);
	}
	else static if(isArray!T)
	{
		// To serialize an array, we write the size then the data
		alias ARRAY_TYPE = Unqual!(typeof(v[0]));
		size_t array_length;
		size_t size = doDeserialize(array_length, array);
		auto temp = Mallocator.instance.makeArray!ARRAY_TYPE(array_length);
		for(int i = 0; i < array_length; i++) size += doDeserialize(temp[i], array[size .. $]); 
		v = cast(T)temp;
		return size;
	}
	else static if(isPointer!T)
	{
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		bool b;
		size_t size = doDeserialize(b, array);
		if(b) {
			v = Mallocator.instance.make!(typeof(*v))();
			size += doDeserialize(*v, array[size .. $]);
		}
		else v = null;
		return size;
	}
	else static if(is(T == struct))
	{
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		size_t size = 0;
		uint mem_count;
		size += doDeserialize(mem_count, array[size .. $]);
		for(uint i = 0; i < mem_count; i++)
		{
			size_t id_hash_in_serial;
			size_t member_size;
			size += doDeserialize(id_hash_in_serial, array[size .. $]);
			size += doDeserialize(member_size, array[size .. $]);

			foreach(m; __traits(allMembers, T))
			{
				static if(__traits(compiles, function(T v, byte[] a) { doSerialize(mixin("v." ~ m), a); }))
				{
					enum size_t id_hash = hashOf(m);
					if(id_hash == id_hash_in_serial)
					{
						auto real_member_size = doDeserialize(mixin("v." ~ m), array[size .. $]); 
						enforce(real_member_size == member_size, "Member size does not mach the amount deserialized, maybe input corupt"); 
					}
				}
			}

			size += member_size;
		}
		
		return size;
	}
	else static if(isBasicType!T)
	{
		enforce(array.length >= T.sizeof, "Reached end of input");
		v = *(cast(T*)(array.ptr));
		return T.sizeof;
	}
	else
	{
		static assert(0); // class not supported right now :) 
	}
}

private size_t doSerialize_size(T)(T v)
{
	import std.traits;
	static if(hasCustomSerialize!T)
	{
		return v.serialSize;
		
	}
	else static if(isArray!T)
	{
		// To serialize an array, we write the size then the data
		size_t size = doSerialize_size(v.length);
		foreach(m; v) size += doSerialize_size(m); 
		return size;
	}
	else static if(isPointer!T)
	{
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		size_t size = doSerialize_size(v == null);
		if(v != null) size += doSerialize_size(*v);
		return size;
	}
	else static if(is(T == struct))
	{
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		size_t size = 0;
		enum uint mem_count = memberCount!T();
		size += doSerialize_size(mem_count);
		foreach(m; __traits(allMembers, T))
		{
			static if(__traits(compiles, doSerialize_size(mixin("v." ~ m))))
			{
				size_t member_size = doSerialize_size(mixin("v." ~ m)); 
				enum size_t id_hash = hashOf(m);
				size += doSerialize_size(id_hash);
				size += doSerialize_size(member_size);
				size += member_size ; 
			}
		}
		return size;
	}
	else static if(isBasicType!T)
	{
		return T.sizeof;
	}
	else
	{
		static assert(0); // class not supported right now :) 
	}
}

private size_t doSerialize(T)(T v, byte[] array) if(!is(T == class))
{
	import std.traits;
	static if(hasCustomSerialize!T)
	{
		return v.serialize(array);
	}
	else static if(isArray!T)
	{
		// To serialize an array, we write the size then the data
		size_t size = doSerialize(v.length, array);
		foreach(m; v) size += doSerialize(m, array[size .. $]); 
		return size;
	}
	else static if(isPointer!T)
	{
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		size_t size = doSerialize(v == null, array);
		if(v != null) size += doSerialize(*v, array[size .. $]);
		return size;
	}
	else static if(is(T == struct))
	{
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		size_t size = 0;
		enum uint mem_count = memberCount!T();
		size += doSerialize(mem_count, array[size .. $]);
		foreach(m; __traits(allMembers, T))
		{
			static if(__traits(compiles, doSerialize(mixin("v." ~ m), array)))
			{
				size_t member_size = doSerialize_size(mixin("v." ~ m)); 
				enum size_t id_hash = hashOf(m);
				size += doSerialize(id_hash, array[size .. $]);
				size += doSerialize(member_size, array[size .. $]);
				size += doSerialize(mixin("v." ~ m), array[size .. $]); 
			}
		}
		return size;
	}
	else static if(isBasicType!T)
	{
		enforce(array.length >= T.sizeof, "Reached end of store");
		*(cast(T*)(array.ptr)) = v;
		return T.sizeof;
	}
	else
	{
		static assert(0); // class not supported right now :) 
	}
}

void free_Deserialize(T)(T v)
{
	import std.traits;
	static if(hasCustomSerialize!T)
	{
		return;
	}
	else static if(isArray!T)
	{
		// To serialize an array, we write the size then the data
		dispose(v);
		return;
	}
	else static if(isPointer!T)
	{
		// To serialize a pointer, first we write if its null or not with a bool, and if its not null then we write the actual data
		if(v != null) dispose(v);
		return;
	}
	else static if(is(T == struct))
	{
		// To serialzie a struct we will serialize all the public members / all the members that can be serialized!
		// But the layout if the struct could change at any time so we need to write out member identifications so each 
		// member will also write out a hash of the member name 
		// Because the count could change to we will serialize out the number of members first
		// Incase when we are deserializing we find a member we dont recognize, we need to know the member size to skip by, so we first serialize out the member size
		foreach(m; __traits(allMembers, T))
		{
			static if(__traits(compiles, function(T v) { free_Deserialize(mixin("v." ~ m)); }))
			{
				free_Deserialize(mixin("v." ~ m));
			}
		}
		return;
	}
	else static if(isBasicType!T)
	{
		return; 
	}
	else
	{
		static assert(0); // class not supported right now :) 
	}
}

private template hasCustomSerialize(T)
{
	enum hasCustomSerialize = __traits(compiles, 
			function(T x) { 
				size_t s = x.serialSize; 
				byte[] b = new byte[s]; 
				size_t s2 = x.serialize(b); 
				T y;
				size_t s3 = T.deserialize(y, b);
			}
		);
}

private uint memberCount(T)()
{
	uint count = 0;
	foreach(m; __traits(allMembers, T))
	{
		static if(__traits(compiles, function(T v, byte[] b) { doSerialize(mixin("v." ~ m), b); }))
		{
			count++;
		}
	}
	return count;
}