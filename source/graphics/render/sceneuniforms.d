module graphics.render.sceneuniforms;
import math.matrix;
import graphics.hw;

//	  _____                       _    _       _  __                         
//	 / ____|                     | |  | |     (_)/ _|                        
//	| (___   ___ ___ _ __   ___  | |  | |_ __  _| |_ ___  _ __ _ __ ___  ___ 
//	 \___ \ / __/ _ \ '_ \ / _ \ | |  | | '_ \| |  _/ _ \| '__| '_ ` _ \/ __|
//	 ____) | (_|  __/ | | |  __/ | |__| | | | | | || (_) | |  | | | | | \__ \
//	|_____/ \___\___|_| |_|\___|  \____/|_| |_|_|_| \___/|_|  |_| |_| |_|___/
//	                                                                         
//	                                                                         
class SceneUniforms
{
	public struct uniformData
	{
		mat4 projection;
		vec4 size;
	}
	public hwBufferRef buffer;
	public uniformData data;
	alias data this;

	public this() {
		auto info 		= hwBufferCreateInfo();
		info.size 		= (uniformData.sizeof);
		info.dynamic 	= true;
		info.data 		= null;
		buffer 			= hwCreate(info);
	}

	public ~this() {
		hwDestroy(buffer);
	}

	public void update() {
		hwBufferSubDataInfo info;
		uniformData[1] d = data;
		info.data = d;
		buffer.subData(info);
	}

	public void bind(uint loc) {
		hwUboCommand info;
		info.location = loc;
		info.size = SceneUniforms.uniformData.sizeof;
		info.ubo = buffer;
		hwCmd(info);
	}
}