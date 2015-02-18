module graphics.fpsTracker;
import std.datetime;

auto FPSTracker()
{
	struct fpsTracker
	{
		private int frame = 0;
		private SysTime lastTime;
		public real fps = 0;
		public int totalFrames = 0;
		
		public this(SysTime now)
		{
			lastTime = now;
		}
		
		public void postFrame()
		{
			frame++;
			totalFrames ++;
			if((Clock.currTime - lastTime).total!"msecs" > 1000)
			{
				fps = frame*(1000.0/(Clock.currTime - lastTime).total!"msecs");
				lastTime = Clock.currTime;
				frame = 0;
			}
		}
	}
	return fpsTracker(Clock.currTime);
}

