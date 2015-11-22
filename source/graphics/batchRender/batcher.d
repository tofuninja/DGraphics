 module graphics.batchRender.batcher;

mixin template Batcher(uint batchSize, ARGS...)
{
	import std.typecons : Tuple;

	private enum size = batchSize;
	private alias arrayType = Tuple!ARGS;
	private arrayType[size] data;
	private uint currentCount = 0;

	public void postBatch(ARGS args)
	{
		arrayType v = args;
		data[currentCount] = v;
		currentCount++;
		if(currentCount == size) runBatch();
	}

	public void runBatch()
	{
		doBatch(data[0 .. currentCount]);
		currentCount = 0;
	}
}