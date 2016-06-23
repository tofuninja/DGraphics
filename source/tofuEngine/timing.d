module tofuEngine.timing;
import std.datetime;
import core.time;

//	 _______ _           _             
//	|__   __(_)         (_)            
//	   | |   _ _ __ ___  _ _ __   __ _ 
//	   | |  | | '_ ` _ \| | '_ \ / _` |
//	   | |  | | | | | | | | | | | (_| |
//	   |_|  |_|_| |_| |_|_|_| |_|\__, |
//	                              __/ |
//	                             |___/ 

class EngineClock {
	private enum fpsUpdateFreq = 1000; // update fps every 1000 ms
	private SysTime lastTime;
	private SysTime start;
	private uint framesSinceLastSecond;
	private TimeStamp currentTime;
	package Timer timerListHead;

	this() {
		currentTime.time = start = Clock.currTime;
		lastTime = start;
		framesSinceLastSecond = 0;
		currentTime.totalFrames = 0;
		currentTime.fps = 0;
		currentTime.delta_ms = 0;
		currentTime.delta = dur!"msecs"(0);
		currentTime.timeSinceStart = dur!"msecs"(0);
	}

	package void doFrame() {
		auto temp = Clock.currTime;
		currentTime.delta = temp - currentTime.time;
		currentTime.delta_ms = cast(float)(currentTime.delta.total!"nsecs" / 1e+6L);
		currentTime.time = temp;
		currentTime.timeSinceStart = temp - start;
		currentTime.totalFrames++;
		framesSinceLastSecond++;

		// Calc fps
		auto dif = (temp - lastTime).total!"msecs";
		if(dif > fpsUpdateFreq) {
			currentTime.fps = framesSinceLastSecond*((cast(float)fpsUpdateFreq)/(cast(float)dif));
			lastTime = temp;
			framesSinceLastSecond = 0;
		}
	}

	/// Returns a time stamp, the time stamp corresponds to the start of the current frame
	TimeStamp getTimeStamp() {
		return currentTime;
	}

	SysTime now() {
		return currentTime.time;
	}

	package void runTimers() {
		timerListHead.runTimers();
	}
}

struct TimeStamp {
	SysTime time;
	float fps;
	float delta_ms;
	Duration delta;
	Duration timeSinceStart;
	ulong totalFrames;
}

// Used for timed events
struct Timer {
	import tofuEngine.engine : tofu_Clock;
	import tofuEngine.component : Component;

	private Timer* next = null;
	private Timer* prev = null;
	private void delegate(ref TimerMsg) target = null; 
	private SysTime time;

	@disable this(this); 

	void setTimer(Duration d, Component tar) {
		setTimer(d, &(tar.broadcast!TimerMsg));
	}

	void setTimer(SysTime time, Component tar) {
		setTimer(time, &(tar.broadcast!TimerMsg));
	}

	void setTimer(Duration d, void delegate(ref TimerMsg) target) {
		setTimer(tofu_Clock.now + d, target);
	}

	void setTimer(SysTime time, void delegate(ref TimerMsg) target) {
		cancel();
		this.time = time;
		this.target = target;
		tofu_Clock.timerListHead.addTimer(this);
	}

	void setTimerNextFrame(Component tar){
		setTimer(dur!"msecs"(0), tar);
	}

	void setTimerNextFrame(void delegate(ref TimerMsg) target){
		setTimer(dur!"msecs"(0), target);
	}

	void cancel() {
		if(prev != null) remove();
	}

	private void addTimer(ref Timer t) {
		auto head = &this;
		while(head.next != null && head.next.time < t.time) head = head.next;
		t.prev = head;
		t.next = head.next;
		if(head.next != null) head.next.prev = &t;
		head.next = &t;
	}

	private void remove() {
		prev.next = next;
		if(next != null) next.prev = prev;
		next = null;
		prev = null;
		target = null;
		//time = 0; 
	}

	private void runTimers() {
		auto currentTime = tofu_Clock.now;
		auto end = &this;
		while(end.next != null && end.next.time <= currentTime) end = end.next;
		if(end == &this) return;
		auto head = next;
		next = end.next;
		end.next = null;

		while(head != null) {
			auto n = head;
			head = head.next;
			n.next = null;
			n.prev = null;
			auto del = n.target;
			n.target = null;

			auto msg = TimerMsg(n);
			del(msg);
		}
	}

	~this() {
		cancel();
	}
}

struct TimerMsg {
	Timer* timer;
}

