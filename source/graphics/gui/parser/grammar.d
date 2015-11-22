module graphics.gui.parser.grammar;
import std.stdio;
import std.container;
import graphics.gui.parser.token;
import graphics.gui.parser.ast.astMixins;
import graphics.gui.parser.ast.astNode;

/*
 * Parse the ui mark up and return an ast node repesenting the markup 
 * 
 */

 // TODO fix function calling 

bool uiFileParse(ref astNode node, string input)
{
	parser p = new parser(input);
	return p.entryGramer(node);
}

bool customStyleParse(ref astNode node, string input)
{
	parser p = new parser(input);
	return p.customStyleEntry(node);
}

private class parser
{
	tokenizer tok;
	uint anon_div_name = 0;

	public this(string code)
	{
		tok = new tokenizer();
		tok.setInput(code);
	}


	bool entryGramer(ref astNode node)
	{
		astNode r = new astNode();
		astNode n;
		while(globalStmt(n)) r.addChild(n);
		if(!tok.eof()) return false;
		node = r;
		return true;
	}

	bool globalStmt(ref astNode node)
	{
		return divStmt(node) || styleStmt(node);
	}

	bool styleStmt(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			
			string name = "";
			string[] styles;

			if(!word("style")) 		{ setInput(back); return false; }
			if(!identifier(name)) 	{ setInput(back); return false; } 
			if(name == "style") 	{ setInput(back); return false; }

			if(operator(":"))
			{
				while(true)
				{
					string style;
					if(!identifier(style)) break;
					styles ~= (style);
				}
			}

			styleNode r = new styleNode(name, styles);
			astNode n;
			if(!operator("{")) 		{ setInput(back); return false; }
			while(styleBodyStmt(n)) r.addChild(n); 
			if(!operator("}")) 		{ setInput(back); return false; }
			
			node = r;
			return true;
		}
	}

	bool customStyleEntry(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			
			string name = "";
			string[] styles;

			styleNode r = new styleNode(name, styles);
			astNode n;
			while(styleBodyStmt(n)) r.addChild(n); 
			node = r;
			return true;
		}
	}

	bool divStmt(ref astNode node)
	{
		import std.conv;
		with(tok)
		{
			auto back = getInput();
			
			string className = "";
			string name = "";
			string[] styles;
			
			if(!identifier(className)) 	{ setInput(back); return false; }
			if(!identifier(name))		{ name = "anon_div_" ~ anon_div_name.to!string(); anon_div_name++; }
			if(name == "style")			{ setInput(back); return false; }
			if(className == "style")	{ setInput(back); return false; }
			if(operator(":"))
			{
				while(true)
				{
					string style;
					if(!identifier(style)) break;
					styles ~= (style);
				}
			}
			
			divNode r = new divNode(name, className, styles);
			astNode n;

			if(!operator("{")) 			{ setInput(back); return false; }
			while(divBodyStmt(n)) 		r.addChild(n); 
			if(!operator("}")) 			{ setInput(back); return false; }

			node = r;
			return true;
		}
	}

	bool divBodyStmt(ref astNode node)
	{
		return divStmt(node) || styleBodyStmt(node);
	}

	bool styleBodyStmt(ref astNode node)
	{
		return assignStmt(node);
	}

	bool assignStmt(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			astNode target;
			astNode exp;
			if(!nameLookUpExpression(target, true)) 			{ setInput(back); return false; }
			if(!operator("=")) 									{ setInput(back); return false; }
			if(!(expression(exp) || stringTermExpression(exp))) { setInput(back); return false; }
			if(!operator(";")) 									{ setInput(back); return false; }
			node = new assignStmtNode(target, exp, (cast(nameLookUpNode)target).names[0]);
			return true;
		}
	}


	bool expression(ref astNode node)
	{
		return addExpression(node);
	}

	bool addExpression(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			
			astNode mul;
			if(!mulExpression(mul)) return false;
			if(operator("+"))
			{
				astNode add;
				if(!addExpression(add)) { setInput(back); return false; }
				node = new binOpNode("+", mul, add);
				return true;
			}
			else if(operator("-"))
			{
				astNode add;
				if(!addExpression(add)) { setInput(back); return false; }
				node = new binOpNode("-", mul, add);
				return true;
			}
			else
			{
				node = mul;
				return true;
			}
		}
	}

	bool mulExpression(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			
			astNode term;
			if(!termExpression(term)) return false;
			if(operator("*"))
			{
				astNode mul;
				if(!mulExpression(mul)) { setInput(back); return false; }
				node = new binOpNode("*", term, mul);
				return true;
			}
			else if(operator("/"))
			{
				astNode mul;
				if(!mulExpression(mul)) { setInput(back); return false; }
				node = new binOpNode("/", term, mul);
				return true;
			}
			else
			{
				node = term;
				return true;
			}
		}
	}

	bool termExpression(ref astNode node)
	{
		return boolExpression(node) || funcCallExpression(node) || nameLookUpExpression(node) || numberExpression(node) || parenExpression(node);
	}

	bool nameLookUpExpression(ref astNode node, bool insert_t = false)
	{
		with(tok)
		{
			auto back = getInput();
			string[] names;
			string n;
			if(!identifier(n)) return false;
			names ~= (n);
			
			while(operator("."))
			{
				if(!identifier(n)) { setInput(back); return false; }
				names ~= (n);
			}
			node = new nameLookUpNode(names, insert_t);
			return true;
		}
	}

	bool numberExpression(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			bool sign = operator("-");
			uint left, right = 0;
			if(!hexinteger(left))
			{
				// not hex, read decimal
				if(!integer(left))  { setInput(back); return false; }
				if(operator("."))
				{
					if(!integer(right))  { setInput(back); return false; }
				}
			}
			node = new numberNode(sign, left, right);
			return true;
		}
	}

	bool parenExpression(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			astNode exp;
			if(!operator("(")) 		{ setInput(back); return false; }
			if(!expression(exp)) 	{ setInput(back); return false; }
			if(!operator(")"))  	{ setInput(back); return false; }
			node = exp;
			return true;
		}
	}

	bool stringTermExpression(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			string str;
			if(!stringtoken(str)) { setInput(back); return false; }
			node = new stringTermNode(str);
			return true;
		}
	}

	bool funcCallExpression(ref astNode node)
	{

		with(tok)
		{
			auto back = getInput();
			string n;
			astNode exp;
			astNode[] args;

			if(!identifier(n))		{ setInput(back); return false; }
			if(!operator("(")) 		{ setInput(back); return false; }
			if(expression(exp)) 	args ~= [exp];
			while(operator(","))
			{
				if(!expression(exp)){ setInput(back); return false; }
				args ~= [exp];
			}
			if(!operator(")")) 		{ setInput(back); return false; }

			node = new funcCallExpressionNode(n, args);
			return true;
		}
	}

	bool boolExpression(ref astNode node)
	{
		with(tok)
		{
			auto back = getInput();
			bool value;
			
			if(word("true")) value = true;
			else if(word("false")) value = false;
			else { setInput(back); return false; }
			
			node = new boolExpressionNode(value);
			return true;
		}
	}
}