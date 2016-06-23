module graphics.hw.util;
import graphics.hw.structs;
import graphics.hw.enums;
import math.matrix;

public struct hwAttachmentLocation {
	uint location;
}

public void hwRegisterAttachments(T)(ref hwVaoCreateInfo info, uint startLocation, uint bindIndex) {
	foreach(m; __traits(allMembers, T)) {
		foreach(s; __traits(getAttributes, mixin("T." ~ m))) {
			static if(is(typeof(s) == hwAttachmentLocation)) {
				info.attachments[startLocation + s.location].enabled = true;
				info.attachments[startLocation + s.location].bindIndex = bindIndex;

				// Only the common types are supported

				//	 ______ _             _    __      __       _                 
				//	|  ____| |           | |   \ \    / /      | |                
				//	| |__  | | ___   __ _| |_   \ \  / /__  ___| |_ ___  _ __ ___ 
				//	|  __| | |/ _ \ / _` | __|   \ \/ / _ \/ __| __/ _ \| '__/ __|
				//	| |    | | (_) | (_| | |_     \  /  __/ (__| || (_) | |  \__ \
				//	|_|    |_|\___/ \__,_|\__|     \/ \___|\___|\__\___/|_|  |___/
				//	                                                              
				//	                                                              
				static if(is(typeof(mixin("T." ~ m)) == float)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.float32;
					info.attachments[startLocation + s.location].elementCount = 1;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == vec2)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.float32;
					info.attachments[startLocation + s.location].elementCount = 2;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == vec3)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.float32;
					info.attachments[startLocation + s.location].elementCount = 3;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == vec4)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.float32;
					info.attachments[startLocation + s.location].elementCount = 4;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				}
				//	 _____       _    __      __       _                 
				//	|_   _|     | |   \ \    / /      | |                
				//	  | |  _ __ | |_   \ \  / /__  ___| |_ ___  _ __ ___ 
				//	  | | | '_ \| __|   \ \/ / _ \/ __| __/ _ \| '__/ __|
				//	 _| |_| | | | |_     \  /  __/ (__| || (_) | |  \__ \
				//	|_____|_| |_|\__|     \/ \___|\___|\__\___/|_|  |___/
				//	                                                     
				//	                                                     
				else static if(is(typeof(mixin("T." ~ m)) == int)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.int32;
					info.attachments[startLocation + s.location].elementCount = 1;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == ivec2)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.int32;
					info.attachments[startLocation + s.location].elementCount = 2;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == ivec3)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.int32;
					info.attachments[startLocation + s.location].elementCount = 3;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == ivec4)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.int32;
					info.attachments[startLocation + s.location].elementCount = 4;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				}
				//	 _    _ _       _    __      __       _                 
				//	| |  | (_)     | |   \ \    / /      | |                
				//	| |  | |_ _ __ | |_   \ \  / /__  ___| |_ ___  _ __ ___ 
				//	| |  | | | '_ \| __|   \ \/ / _ \/ __| __/ _ \| '__/ __|
				//	| |__| | | | | | |_     \  /  __/ (__| || (_) | |  \__ \
				//	 \____/|_|_| |_|\__|     \/ \___|\___|\__\___/|_|  |___/
				//	                                                        
				//	                                                        
				else static if(is(typeof(mixin("T." ~ m)) == uint)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.uint32;
					info.attachments[startLocation + s.location].elementCount = 1;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == uvec2)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.uint32;
					info.attachments[startLocation + s.location].elementCount = 2;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == uvec3)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.uint32;
					info.attachments[startLocation + s.location].elementCount = 3;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				} else static if(is(typeof(mixin("T." ~ m)) == uvec4)) {
					info.attachments[startLocation + s.location].elementType = hwVertexType.uint32;
					info.attachments[startLocation + s.location].elementCount = 4;
					info.attachments[startLocation + s.location].offset = mixin("T." ~ m ~ ".offsetof"); 
				}
				//	 ______ _             _     _  _        _  _     __  __       _        _      
				//	|  ____| |           | |   | || |      | || |   |  \/  |     | |      (_)     
				//	| |__  | | ___   __ _| |_  | || |___  _| || |_  | \  / | __ _| |_ _ __ ___  __
				//	|  __| | |/ _ \ / _` | __| |__   _\ \/ /__   _| | |\/| |/ _` | __| '__| \ \/ /
				//	| |    | | (_) | (_| | |_     | |  >  <   | |   | |  | | (_| | |_| |  | |>  < 
				//	|_|    |_|\___/ \__,_|\__|    |_| /_/\_\  |_|   |_|  |_|\__,_|\__|_|  |_/_/\_\
				//	                                                                              
				//	                                                                              
				else static if(is(typeof(mixin("T." ~ m)) == mat4)) {
					for(int i = 0; i < 4; i++) {
						info.attachments[startLocation + s.location+i].enabled = true;
						info.attachments[startLocation + s.location+i].bindIndex = bindIndex;
						info.attachments[startLocation + s.location+i].elementType = hwVertexType.float32;
						info.attachments[startLocation + s.location+i].elementCount = 4;
						info.attachments[startLocation + s.location+i].offset = cast(uint)(mixin("T." ~ m ~ ".offsetof") + vec4.sizeof*i);
					}
				} else assert(0);
			}
		}
	}
}