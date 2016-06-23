module math.geo.binpacker2d;
import std.algorithm;
import std.range;
import math.geo.rectangle;
import math.matrix;
import std.experimental.allocator;
import std.experimental.allocator.mallocator;

alias alloc = Mallocator.instance;

private struct packNode
{
	iRectangle rec;
	bool used = false;
	packNode* down;
	packNode* right;
	
	this(iRectangle r) {
		rec = r;
	}
	
	~this() {
		if(down) alloc.dispose(down);
		if(right) alloc.dispose(right);
	}
}

private packNode* root;

ivec2 binPack2D(iRectangle[] input) {
	auto r = alloc.makeArray!(iRectangle*)(input.length);
	for(int i = 0; i < input.length; i++) {
		r[i] = &input[i];
	}

	auto rtn = binPack2D_imp(r);

	alloc.dispose(r);
	return rtn;
}

ivec2 binPack2D(iRectangle*[] input) {
	auto r = alloc.makeArray!(iRectangle*)(input.length);
	for(int i = 0; i < input.length; i++) {
		r[i] = input[i];
	}
	
	auto rtn = binPack2D_imp(r);
	
	alloc.dispose(r);
	return rtn;
}

ivec2 binPack2D(R)(R input, size_t count) if(is(typeof(R.init.front) == iRectangle*)) {
	auto r = alloc.makeArray!(iRectangle*)(count);
	int i = 0;
	foreach(p; input) {
		if(i >= count) break;
		r[i] = p;
		i++;
	}
	
	auto rtn = binPack2D_imp(r);
	
	alloc.dispose(r);
	return rtn;
}

ivec2 binPack2D(R)(R input) if(is(typeof(R.init.front) == iRectangle*) && hasLength!R) {
	auto count = input.length;
	auto r = alloc.makeArray!(iRectangle*)(count);
	int i = 0;
	foreach(p; input) {
		if(i >= count) break;
		r[i] = p;
		i++;
	}
	
	auto rtn = binPack2D_imp(r);
	
	alloc.dispose(r);
	return rtn;
}





private ivec2 binPack2D_imp(iRectangle*[] r) {

	r.sort!("(a.size.x*a.size.y) > (b.size.x*b.size.y)")();
	
	auto w = (!r.empty) ? r.front.size.x : 0;
	auto h = (!r.empty) ? r.front.size.y : 0;
	root = alloc.make!packNode(iRectangle(0,0,w,h));
	
	foreach(block; r) {
		auto t = findNode(root, block.size.x, block.size.y);
		if(t !is null)
			splitNode(t, *block);
		else
			growNode(*block);
	}
	auto rtn = root.rec.size;
	alloc.dispose(root);
	return rtn;
}
	
private packNode* findNode(packNode* root, int w, int h) {
	if(root is null) return null;

	if (root.used) {
		auto t = findNode(root.right, w, h);
		if(t !is null) return t;
		return findNode(root.down, w, h);
	} else if ((w <= root.rec.size.x) && (h <= root.rec.size.y))
		return root;
	else
		return null;
}
		
private packNode* splitNode(packNode* node, ref iRectangle rec) {
	auto w = rec.size.x;
	auto h = rec.size.y;
	node.used = true;
	node.down  = alloc.make!packNode(iRectangle( node.rec.loc.x, node.rec.loc.y + h, node.rec.size.x, node.rec.size.y - h));
	node.right  = alloc.make!packNode(iRectangle(node.rec.loc.x + w, node.rec.loc.y, node.rec.size.x - w, h));
	rec.loc = node.rec.loc;
	return node;
}
		
private void growNode(ref iRectangle rec) {
	auto w = rec.size.x;
	auto h = rec.size.y;
	bool canGrowDown  = (w <= root.rec.size.x);
	bool canGrowRight = (h <= root.rec.size.y);
	bool shouldGrowRight = canGrowRight && (root.rec.size.y >= (root.rec.size.x + w)); // attempt to keep square-ish by growing right when height is much greater than width
	bool shouldGrowDown  = canGrowDown  && (root.rec.size.x >= (root.rec.size.y + h)); // attempt to keep square-ish by growing down  when width  is much greater than height
	
	if (shouldGrowRight)
		growRight(rec);
	else if (shouldGrowDown)
		growDown(rec);
	else if (canGrowRight)
		growRight(rec);
	else if (canGrowDown)
		growDown(rec);
	else 
		assert(false);
}

private void growRight(ref iRectangle rec) {
	auto w = rec.size.x;
	auto h = rec.size.y;
	auto cur = root;

	root = alloc.make!packNode(iRectangle(
			0,
			0, 
			cur.rec.size.x + w,
			cur.rec.size.y
			));

	root.used = true;
	root.down = cur;
	root.right = alloc.make!packNode(iRectangle(cur.rec.size.x, 0, w, cur.rec.size.y));

	auto t = findNode(root, w, h);
	if (t !is null)
		splitNode(t, rec);
	else
		assert(false);
}
	
private void growDown(ref iRectangle rec) {
	auto w = rec.size.x;
	auto h = rec.size.y;
	auto cur = root;

	root = alloc.make!packNode(iRectangle(
			0,
			0, 
			cur.rec.size.x,
			cur.rec.size.y + h
			));

	root.used = true;
	root.down = alloc.make!packNode(iRectangle(0, cur.rec.size.y, cur.rec.size.x, h));
	root.right = cur;

	auto t = findNode(root, w, h);
	if (t !is null)
		splitNode(t, rec);
	else
		assert(false);
}


