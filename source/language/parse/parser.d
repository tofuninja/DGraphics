module language.parse.parser;

struct ParseResult
{
	bool success = false;
	dstring parse; 
	dstring remain; // in the event of a parse fail, this is the start of the unexpected chars
	dstring error;
}

