module graphics.gui.console;

import graphics.hw;
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

/*mixin loadUIString!(`
Panel console_div
{
	background = RGB(90,90,90);
	foreground = RGB(130, 130, 130);
	textcolor = RGB(255,255,255);

	Textbox textentry
	{
		background = parent.background;
		textcolor = parent.textcolor;
		hintColor  = parent.foreground;
		text = "console box";
		bounds.loc = vec2(0, parent.bounds.size.y - defaultHeight);
		bounds.size.x = parent.bounds.size.x;
	}
	
	Scrollbox logbox
	{
		background = parent.background;
		foreground = parent.foreground;
		bounds.loc = vec2(0,0);
		bounds.size = vec2(parent.bounds.size.x, textentry.bounds.loc.y);
		
		Label log
		{
			textcolor = parent.parent.textcolor;
			bounds.loc = vec2(4,4);
		}
	}
}
`);*/


//@needsExtends
//class Console(ExtendType) : console_div!(ExtendType, div)
class Console : Panel
{
	//import util.event;
	//Event!(div, dstring) onCmd;
	private dstring[consoleCmdMemory] pastCommand;
	private int memStart = 0;
	private int memLoc = 0;

	private dchar[consoleBufferSize] textBuffer;
	private int textSize = consoleBufferSize;

	private Textbox textentry;
	private Scrollbox logbox;
	private Label log;

	this() {
		textentry = new Textbox();
		textentry.text = "console box";
		addDiv(textentry);

		logbox = new Scrollbox();
		addDiv(logbox);

		log = new Label();
		logbox.addDiv(log);

		void event(EventArgs args) {
			if(args.type != EventType.Key) return;
			this.textEnterProc(args.key_value, args.mods, args.down);
		}
		
		textentry.eventHandeler = &event;
	}

	override protected void stylizeProc() {
		textentry.doStylize();
		textentry.bounds.loc 	= vec2(0, this.bounds.size.y - textentry.bounds.size.y);
		textentry.bounds.size.x = this.bounds.size.x;

		logbox.bounds.loc = vec2(0,0);
		logbox.bounds.size = vec2(this.bounds.size.x, textentry.bounds.loc.y);

		log.bounds.loc = vec2(4,4);
	}

	public void write(T...)(T args) {
		import std.format;
		import std.array;
		import std.traits;
		import std.range;

		dchar[consoleBufferSize] tempBuffer;
		struct myAppender
		{
			dchar[] target;
			uint loc = 0;

			void put(A)(A writeme) if (is(ElementType!A : const(dchar)) && isInputRange!A && !isInfinite!A) {
	        	foreach(c; writeme) {
	        		put(c);
	        	}
	        }

			void put(C)(C c) if (is(C : const(dchar))) {
				if(loc < target.length) {
					target[loc] = c;
					loc ++;
				}
			}
		}

		//auto w = appender!dstring();
		auto w = myAppender(tempBuffer, 0);

		foreach (arg; args) {
			alias A = typeof(arg);
			static if (isAggregateType!A || is(A == enum)) {
				std.format.formattedWrite(&w, "%s", arg);
			} else static if (isSomeString!A) {
				import std.range : put;
				put(w, arg);
			} else static if (isIntegral!A) {
				import std.conv : toTextRange;
				toTextRange(arg, &w);
			} else static if (isBoolean!A) {
				put(w, arg ? "true" : "false");
			} else static if (isSomeChar!A) {
				import std.range : put;
				put(w, arg);
			} else {
				import std.format : formattedWrite;
				// Most general case
				std.format.formattedWrite(&w, "%s", arg);
			}
		}

		for(int i = 0; i < consoleBufferSize; i ++) {
			if(i < consoleBufferSize - w.loc) {
				textBuffer[i] = textBuffer[i + w.loc];
			} else {
				textBuffer[i] = w.target[i - (consoleBufferSize - w.loc)];
			}
		}

		
		textSize -= w.loc;
		if(textSize < 0) textSize = 0;

		log.text = cast(immutable dchar[])(textBuffer[textSize .. $]); // FUCK THE POLICE! I DO WHAT I WANT!
		logbox.scroll = vec2(0, 1);
		invalidate();
	}

	public void writeln(T...)(T args) {
		write(args, '\n');
	}

	bool textEnterProc(hwKey k ,hwKeyModifier m,bool down) {
		if((k == hwKey.ENTER || k == hwKey.KP_ENTER) && down) {
			auto cmd = textentry.value;
			textentry.value = "";

			pastCommand[memStart] = cmd;
			memStart ++;
			memStart %= consoleCmdMemory;
			pastCommand[memStart] = "";
			memLoc = memStart;

			writeln(">", cmd);
			{
				EventArgs e = {type: EventType.Action};
				e.svalue = cmd;
				doEvent(e);
			}
		} else if(k == hwKey.UP && down) {
			memLoc --;
			if(memLoc == -1) memLoc = consoleCmdMemory - 1;
			textentry.value = pastCommand[memLoc];
			invalidate();
		} else if(k == hwKey.DOWN && down) {
			memLoc ++;
			memLoc %= consoleCmdMemory;
			textentry.value = pastCommand[memLoc];
			invalidate();
		}
		return false;
		//return false;
	}
}

void consoleCommandGenerator(alias mod)(Console console) {
	void commandCallBack(EventArgs event_args) {
		import std.traits;
		import std.conv;
		import std.typecons;

		if(event_args.type != EventType.Action) return;

		auto con = cast(Console)event_args.origin;
		auto commandString = event_args.svalue;

		dstring commandName, args;
		getCommandName(commandString, commandName, args);

		// Check all members of module mod if they are callable and have a command uda
		if(commandName == "help") {
			auto ir = getCommandArgs(args);
			if(ir.empty) {
				con.writeln("To get command specific help, type \"help <command>\"\n#Commands\nhelp");
				foreach(s; __traits(allMembers, mod)) {
					static if(__traits(compiles, () { 
						mixin("alias member = mod." ~ s ~";"); 
						static assert(isCallable!(member));
						static assert(hasUDA!(member, command));
					})) {
						mixin("alias member = mod." ~ s ~";");
						con.writeln(s);
					}
				}
			} else {
				dstring helpName = ir.front;
				ir.popFront();
				if(!ir.empty) { 
					con.writeln("Failed to parse arguments"); 
					return; 
				}

				if(helpName == "help") {
					con.writeln("#help\nArguments: dstring \nProvides help information about commands");
					return;
				}

				foreach(s; __traits(allMembers, mod)) {
					static if(__traits(compiles, () { 
						mixin("alias member = mod." ~ s ~";"); 
						static assert(isCallable!(member));
						static assert(hasUDA!(member, command));
					})) {
						mixin("alias member = mod." ~ s ~";");
						// Get the command uda
						enum com = getCommand!member();
						if(helpName == s) {
							con.writeln("#" ~ s);
							con.write("Arguments: ");
							static if(com.simpleCommand) {
								con.write("dstring");
							} else {
								// Loop through each of the function arguments and print the type name
								foreach(i; intrange!(0, Parameters!(member).length)) {
									con.write(Parameters!(member)[i].stringof, " ");
								}
							}

							con.writeln("\n", com.help);
							return;
						}
					}
				}
			}

			return;
		}

		foreach(s; __traits(allMembers, mod)) {
			static if(__traits(compiles, () { 
				mixin("alias member = mod." ~ s ~";"); 
				static assert(isCallable!(member));
				static assert(hasUDA!(member, command));
			})) {
				mixin("alias member = mod." ~ s ~";");

				// Get the command uda
				enum com = getCommand!member();
				if(commandName == s) {
					// if its a simple command just give it the args as one string
					static if(com.simpleCommand) {
						try
						{
							member(args);
						}
						catch(Exception e) {
							con.writeln(e); 
						}
						catch(Error e) {
							con.writeln(e); 
						}
					} else {
						// Non simple command tries to parse the args
						Tuple!(Parameters!member) memargs;
						auto ir = getCommandArgs(args);

						// Loop through each of the function argumen and try to parse it
						foreach(i; intrange!(0, Parameters!(member).length)) {
							if(ir.empty) { 
								con.writeln("Failed to parse arguments"); 
								return; 
							}

							static if(is(Parameters!(member)[i] == dstring)) {
								// No conversion needed
								memargs[i] = ir.front;
							} else static if(is(Parameters!(member)[i] == string) || is(Parameters!(member)[i] == wstring)) {
								// Try to convert
								try{
									memargs[i] = ir.front.to!(Parameters!(member)[i])();
								}catch(Exception e) {
									con.writeln("Failed to parse arguments"); 
									return; 
								}
							} else {
								// Try to parse
								try{
									memargs[i] = ir.front.parse!(Parameters!(member)[i])();
								}catch(Exception e) {
									con.writeln("Failed to parse arguments"); 
									return; 
								}
							}

							ir.popFront();
						}

						// Make sure there are no more args
						if(!ir.empty) { 
							con.writeln("Failed to parse arguments"); 
							return; 
						}

						try
						{
							member(memargs.expand);
						}
						catch(Exception e) {
							con.writeln(e); 
						}
						catch(Error e) {
							con.writeln(e); 
						}
					}
					return;
				}
			}
		}

		con.writeln("Unknown command"); 
	}

	console.eventHandeler = &commandCallBack;
}

struct command
{
	dstring help;
	bool simpleCommand = false;
	this(dstring help_text, bool simple = false) {
		help = help_text;
		simpleCommand = simple;
	}
}


private template intrange(int start, int end) {
	import std.meta;
	static if(start == end)
		alias intrange = AliasSeq!();
	else
		alias intrange = AliasSeq!(start, intrange!(start + 1, end));
}

private command getCommand(alias a)() {
	foreach(s; __traits(getAttributes, a)) {
		static if(is(typeof(s) == command)) {
			return s;
		}
	}

	assert(0);
}

private void getCommandName(dstring cmd, out dstring name, out dstring args) {
	uint start = 0;
	while(start < cmd.length && (cmd[start] == ' ' || cmd[start] == '\t' || cmd[start] == '\n')) start ++;

	uint end = start;
	while(end < cmd.length && !(cmd[end] == ' ' || cmd[end] == '\t' || cmd[end] == '\n')) end ++;

	name = cmd[start .. end];

	start = end;
	while(start < cmd.length && (cmd[start] == ' ' || cmd[start] == '\t' || cmd[start] == '\n')) start ++;
	
	args = cmd[start .. $];
}

private auto getCommandArgs(dstring input) {
	import std.range;
	struct result
	{
		private dstring args;
		public dstring front;
		public bool empty = false;
		public void popFront() {

			uint start = 0, end = 0;
			while(start < args.length && (args[start] == ' ' || args[start] == '\t' || args[start] == '\n')) start ++;

			if(args[start .. $].length == 0) {
				empty = true;
				return;
			}
			
			end = start;
			if(args[end] == '"') {
				start ++;
				end ++;
				while(end < args.length && (args[end] != '"')) end ++;
			} else {
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