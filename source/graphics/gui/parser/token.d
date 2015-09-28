module graphics.gui.parser.token;
import std.stdio;
import std.typetuple : allSatisfy;

enum implicityConvertibleToBool(T) = is(T : bool);

class tokenizer
{
	private string prog;

	/**
	 * Set all tokenizer operations to read from INPUT.
	 */
	public void setInput(string INPUT)
	{
		prog = INPUT;
	}

	/**
	 * Return the remaining input
	 */
	public string getInput()
	{
		return prog;
	}

	/**
	 * Check if any input left to be read.
	 */
	public bool eof()
	{
		empty();
		return prog.length == 0; 
	}

	/**
	 * Consumes all empty chars(space, tab, newline).
	 * Always succeeds. 
	 */
	public bool empty()
	{
		while(charOr(" \t\n\r")) {} 
		return true;
	}




	/**
	 * Reads a key word(after empty chars), the keyword must match the idetntifer semantics
	 * The keyword must match the whole identifier(aka "void_1" will not match key word "void").
	 * 
	 * Different from operator() in that it requiers the identifier sematics. 
	 */
	bool word(string w)
	{
		string ident;
		string backup = prog;
		if(identifier(ident))
		{
			if(ident != w)
			{
				prog = backup;
				return false;
			}
			return true;
		}
		return false;
	}

	bool _expect_word(string w)
	{
		import std.stdio;
		bool b = word(w);
		if(!b) writeln("Error, expected ", w);
		return b;
	}




	/**
	 * Similar to word() but does not require the same restrictions. 
	 * Matches the op at the begining of the input(after empty chars).
	 * 
	 * For example "+=abc" will match the op "+=". 
	 * Or "void_1" would match the op "void" which word() would not. 
	 */
	bool operator(string op)
	{
		string backup = prog;
		empty();
		
		for(int i = 0; i < op.length; i++)
		{
			if(!charOne(op[i]))
			{
				prog = backup;
				return false;
			}
		}
		return true;
	}

	bool _expect_operator(string op)
	{
		import std.stdio;
		bool b = operator(op);
		if(!b) writeln("Error, expected ", op);
		return b;
	}




	/**
	 * Reads the first identifer in the input(after empty chars).
	 * 
	 * An identifer starts with either a letter or an underscore.
	 * The rest can be either a letter, number or an underscore.
	 * 
	 * Consumes until a non valid char is hit. 
	 */
	bool identifier(ref string id_string)
	{
		string backup = prog;
		empty();
		
		int count = 0;
		string start = prog;
		
		if(!tok_or(charRange('a', 'z'), charRange('A', 'Z'), charOne('_'))) 
		{
			prog = backup;
			return false;
		}
		count++;
		
		while(tok_or(charRange('a', 'z'), charRange('A', 'Z'), charRange('0', '9'), charOne('_'))) count ++;
		
		id_string = start[0 .. count];
		return true;
	}




	/**
	 * Reads an integer(after empty chars) consisting of the chars [0..9]
	 */
	bool integer(ref uint uint_value)
	{
		import std.conv;
		string backup = prog;
		empty();
		
		int count = 0;
		string start = prog;
		
		while(charRange('0', '9')) count ++;
		if(count == 0) 
		{
			prog = backup;
			return false;
		}
		
		auto s = start[0 .. count];
		uint_value = parse!uint(s);
		return true;
	}

	bool hexinteger(ref uint uint_value)
	{
		uint r = 0;
		string backup = prog;
		empty();

		if(!(charOne('0') && (charOne('x') || charOne('X'))))
		{
			prog = backup;
			return false;
		}

		while(prog.length != 0)
		{
			char c = prog[0];
			if(c >= '0' && c <= '9')
			{
				r = (r << 4) | (c - '0');
			}
			else if(c >= 'a' && c <= 'f')
			{
				r = (r << 4) | (c - 'a' + 10);
			}
			else if(c >= 'A' && c <= 'F')
			{
				r = (r << 4) | (c - 'A' + 10);
			}
			else break;

			prog = prog[1 .. $];
		}
		
		uint_value = r;
		return true;
	}

	bool stringtoken(ref string string_value)
	{
		string backup = prog;
		empty();
		string r = "";

		if(!charOne('"')) {prog = backup;return false;}

		while(prog.length != 0)
		{
			char c = prog[0];

			if(prog.length >= 2 && prog[0] == '\\' && prog[1] == '"')
			{
				r ~= "\\\"";
				prog = prog[2 .. $];
				continue;
			}

			if(c == '"') break;
			else if(c == '\r') r ~= "\\r";
			else if(c == '\n') r ~= "\\n";
			else r ~= c;
			prog = prog[1 .. $];
		}

		if(!charOne('"')) {prog = backup;return false;}
		string_value = r;
		return true;
	}





	/**
	 * Checks each of the tokens in order, if one fails, it rolls back the input to the start
	 * 
	 * Example:
	 * 		setInput("abc =");
	 * 		assert( tok_and(identifier(ident), operator("="), integer(value)) == false );
	 * 		assert( tok_and(identifier(ident), operator("=")) == true );
	 */
	bool tok_and(Args...)(lazy Args terms) if(allSatisfy!(implicityConvertibleToBool, Args))
	{
		string backup = prog;
		foreach(term; terms)
		{
			if(term == false)
			{
				prog = backup;
				return false;
			}
		}
		return true;
	}



	/**
	 * Checks each of the tokens in order, if one succeeds, that is the one that is used
	 */
	bool tok_or(Args...)(lazy Args terms) if(allSatisfy!(implicityConvertibleToBool, Args))
	{
		foreach(term; terms)
		{
			if(term == true)
			{
				return true;
			}
		}
		
		return false;
	}

	bool tok_peek(lazy bool tok)
	{
		string backup = prog;
		bool b = tok;
		prog = backup;
		return b;
	}

	/*
	 * Char read operations....  
	 */

	/**
	 * Matches any of the chars in consume.
	 */
	private bool charOr(string consume)
	{
		if(prog.length == 0) return false;
		
		for(int i = 0; i < consume.length; i ++)
		{
			if(prog[0] == consume[i])
			{
				prog = prog[1 .. $];
				return true;
			}
		}
		
		return false; 
	}

	/**
	 * Matches any of the chars in the range [start..end] inclusive. 
	 */
	private bool charRange(char start, char end)
	{
		if(prog.length == 0) return false;
		if(prog[0] >= start && prog[0] <= end) {
			prog = prog[1 .. $];
			return true;
		}
		return false; 
	}

	/**
	 * Matches the single char c. 
	 */
	private bool charOne(char c)
	{
		if(prog.length == 0) return false;
		if(prog[0] == c)
		{
			prog = prog[1 .. $];
			return true;
		}
		
		return false; 
	}
}