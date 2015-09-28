module graphics.gui.console;

import graphics.hw.game;
import graphics.gui.div;

import graphics.simplegraphics;
import graphics.color;
import math.geo.rectangle;
import math.matrix;

import graphics.gui.panel;
import graphics.gui.textbox;
import graphics.gui.scrollbox;
import graphics.gui.label;

enum consoleCmdMemory = 20;
// TODO write console text out to a fixed sized buffer
enum consoleBufferSize = 1024*20;

mixin loadUIString!(`
Panel console_div
{
	background = RGB(70,70,70);
	Textbox textentry
	{
		background = RGB(90,90,90);
		foreground = RGB(255,255,255);
		hintColor  = RGB(130,130,130);
		text = "console box";
		bounds.loc = vec2(2, parent.bounds.size.y -2 - defaultHeight);
		bounds.size.x = parent.bounds.size.x-4;
	}
	
	Scrollbox logbox
	{
		background = RGB(90,90,90);
		bounds.loc = vec2(2,2);
		bounds.size = vec2(parent.bounds.size.x-4, textentry.bounds.loc.y - 4);
		
		Label log
		{
			foreground = RGB(255,255,255);
			bounds.loc = vec2(4,4);
		}
	}
}
`);


@needsExtends
class Console(ExtendType) : console_div!(ExtendType, div)
{
	import util.event;
	Event!(div, dstring) onCmd;
	private dstring[consoleCmdMemory] pastCommand;
	private int memStart = 0;
	private int memLoc = 0;

	private dchar[consoleBufferSize] textBuffer;
	private int textSize = consoleBufferSize;

	public void write(T...)(T args)
	{
		import std.format;
		import std.array;
		import std.traits;
		import std.range.primitives;

		dchar[consoleBufferSize] tempBuffer;
		struct myAppender
		{
			dchar[] target;
			uint loc = 0;

			void put(A)(A writeme) if (is(ElementType!A : const(dchar)) && isInputRange!A && !isInfinite!A)
	        {
	        	foreach(c; writeme)
	        	{
	        		put(c);
	        	}
	        }

			void put(C)(C c) if (is(C : const(dchar)))
			{
				if(loc < target.length)
				{
					target[loc] = c;
					loc ++;
				}
			}
		}

		//auto w = appender!dstring();
		auto w = myAppender(tempBuffer, 0);

		foreach (arg; args)
		{
			alias A = typeof(arg);
			static if (isAggregateType!A || is(A == enum))
			{
				std.format.formattedWrite(&w, "%s", arg);
			}
			else static if (isSomeString!A)
			{
				import std.range.primitives : put;
				put(w, arg);
			}
			else static if (isIntegral!A)
			{
				import std.conv : toTextRange;
				toTextRange(arg, &w);
			}
			else static if (isBoolean!A)
			{
				put(w, arg ? "true" : "false");
			}
			else static if (isSomeChar!A)
			{
				import std.range.primitives : put;
				put(w, arg);
			}
			else
			{
				import std.format : formattedWrite;
				// Most general case
				std.format.formattedWrite(&w, "%s", arg);
			}
		}

		for(int i = 0; i < consoleBufferSize; i ++)
		{
			if(i < consoleBufferSize - w.loc)
			{
				textBuffer[i] = textBuffer[i + w.loc];
			}
			else
			{
				textBuffer[i] = w.target[i - (consoleBufferSize - w.loc)];
			}
		}

		
		textSize -= w.loc;
		if(textSize < 0) textSize = 0;

		logbox.log.text = cast(immutable dchar[])(textBuffer[textSize .. $]); // FUCK THE POLICE! I DO WHAT I WANT!

		logbox.scroll = vec2(0, 1);
		invalidate();
	}

	public void writeln(T...)(T args)
	{
		write(args, '\n');
	}

	override protected void initProc()
	{
		super.initProc();
		this.textentry.onKey += &textEnterProc;
	}

	bool textEnterProc(div d,key k ,keyModifier m,bool down)
	{
		if(k == key.ENTER && down) {
			auto cmd = textentry.value;
			textentry.value = "";

			pastCommand[memStart] = cmd;
			memStart ++;
			memStart %= consoleCmdMemory;
			pastCommand[memStart] = "";
			memLoc = memStart;

			writeln(">", cmd);
			onCmd(this, cmd);
		}
		else if(k == key.UP && down)
		{
			memLoc --;
			if(memLoc == -1) memLoc = consoleCmdMemory - 1;
			textentry.value = pastCommand[memLoc];
			invalidate();
		}
		else if(k == key.DOWN && down)
		{
			memLoc ++;
			memLoc %= consoleCmdMemory;
			textentry.value = pastCommand[memLoc];
			invalidate();
		}
		return false;
	}
}

void consoleCommandGenerator(alias mod, T)(T console)
{
	bool commandCallBack(div d, dstring commandString)
	{
		import std.traits;
		import std.conv;
		import std.typecons;

		T con = cast(T)d;
		dstring commandName, args;
		getCommandName(commandString, commandName, args);

		// Check all members of module mod if they are callable and have a command uda

		if(commandName == "help")
		{
			auto ir = getCommandArgs(args);
			if(ir.empty)
			{
				con.writeln("To get command specific help, type \"help <command>\"\n#Commands\nhelp");
				foreach(s; __traits(allMembers, mod))
				{
					mixin("alias member = mod." ~ s ~";");
					static if(isCallable!(member) && hasUDA!(member, command))
					{
						con.writeln(s);
					}
				}
			}
			else
			{
				dstring helpName = ir.front;
				ir.popFront();
				if(!ir.empty) 
				{ 
					con.writeln("Failed to parse arguments"); 
					return false; 
				}

				if(helpName == "help")
				{
					con.writeln("#help\nArguments: dstring \nProvides help information about commands");
					return false;
				}

				foreach(s; __traits(allMembers, mod))
				{
					mixin("alias member = mod." ~ s ~";");
					static if(isCallable!(member) && hasUDA!(member, command))
					{
						// Get the command uda
						enum com = getCommand!member();
						if(helpName == s)
						{
							con.writeln("#" ~ s);
							con.write("Arguments: ");
							static if(com.simpleCommand)
							{
								con.write("dstring");
							}
							else
							{
								// Loop through each of the function arguments and print the type name
								foreach(i; intrange!(0, Parameters!(member).length))
								{
									con.write(Parameters!(member)[i].stringof, " ");
								}
							}

							con.writeln("\n", com.help);
							return false;
						}
						
						
					}
				}
			}

			return false;
		}

		foreach(s; __traits(allMembers, mod))
		{
			mixin("alias member = mod." ~ s ~";");

			static if(isCallable!(member) && hasUDA!(member, command))
			{

				// Get the command uda
				enum com = getCommand!member();
				if(commandName == s)
				{
					// if its a simple command just give it the args as one string
					static if(com.simpleCommand)
					{
						try
						{
							member(args);
						}
						catch(Exception e)
						{
							con.writeln(e); 
						}
						catch(Error e)
						{
							con.writeln(e); 
						}
					}
					else
					{
						// Non simple command tries to parse the args
						Tuple!(Parameters!member) memargs;
						auto ir = getCommandArgs(args);

						// Loop through each of the function argumen and try to parse it
						foreach(i; intrange!(0, Parameters!(member).length))
						{
							if(ir.empty) 
							{ 
								con.writeln("Failed to parse arguments"); 
								return false; 
							}

							static if(is(Parameters!(member)[i] == dstring))
							{
								// No conversion needed
								memargs[i] = ir.front;
							}
							else static if(is(Parameters!(member)[i] == string) || is(Parameters!(member)[i] == wstring))
							{
								// Try to convert
								try{
									memargs[i] = ir.front.to!(Parameters!(member)[i])();
								}catch(Exception e){
									con.writeln("Failed to parse arguments"); 
									return false; 
								}
							}
							else
							{
								// Try to parse
								try{
									memargs[i] = ir.front.parse!(Parameters!(member)[i])();
								}catch(Exception e){
									con.writeln("Failed to parse arguments"); 
									return false; 
								}
							}

							ir.popFront();
						}

						// Make sure there are no more args
						if(!ir.empty) 
						{ 
							con.writeln("Failed to parse arguments"); 
							return false; 
						}

						try
						{
							member(memargs.expand);
						}
						catch(Exception e)
						{
							con.writeln(e); 
						}
						catch(Error e)
						{
							con.writeln(e); 
						}
					}
					return false;
				}


			}
		}

		con.writeln("Unknown command"); 
		return false;
	}

	console.onCmd += &commandCallBack;
}

struct command
{
	dstring help;
	bool simpleCommand = false;
	this(dstring help_text, bool simple = false)
	{
		help = help_text;
		simpleCommand = simple;
	}
}


private template intrange(int start, int end)
{
	import std.typetuple;
	static if(start == end)
		alias intrange = AliasSeq!();
	else
		alias intrange = AliasSeq!(start, intrange!(start + 1, end));
}

private command getCommand(alias a)()
{
	foreach(s; __traits(getAttributes, a))
	{
		static if(is(typeof(s) == command))
		{
			return s;
		}
	}

	assert(0);
}

private void getCommandName(dstring cmd, out dstring name, out dstring args)
{
	uint start = 0;
	while(start < cmd.length && (cmd[start] == ' ' || cmd[start] == '\t' || cmd[start] == '\n')) start ++;

	uint end = start;
	while(end < cmd.length && !(cmd[end] == ' ' || cmd[end] == '\t' || cmd[end] == '\n')) end ++;

	name = cmd[start .. end];

	start = end;
	while(start < cmd.length && (cmd[start] == ' ' || cmd[start] == '\t' || cmd[start] == '\n')) start ++;

	args = cmd[start .. $];
}

private auto getCommandArgs(dstring input)
{
	import std.range;
	struct result
	{
		private dstring args;
		public dstring front;
		public bool empty = false;
		public void popFront(){

			uint start = 0, end = 0;
			while(start < args.length && (args[start] == ' ' || args[start] == '\t' || args[start] == '\n')) start ++;

			if(args[start .. $].length == 0) {
				empty = true;
				return;
			}
			
			end = start;
			if(args[end] == '"')
			{
				start ++;
				end ++;
				while(end < args.length && (args[end] != '"')) end ++;
			}
			else
			{
				while(end < args.length && !(args[end] == ' ' || args[end] == '\t' || args[end] == '\n')) end ++;
			}

			front = args[start .. end];
			args = args[end .. $];
			if(args.length >= 1 && args[0] == '"') args = args[1 .. $];
		}
	}
	static assert(isInputRange!result);
	result r;
	r.args = input;
	r.popFront();
	return r;
}