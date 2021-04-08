module zinterface;

import std.stdio: writef;
import std.conv: to;
import std.algorithm.searching: canFind;

import zutil = zutility;

enum Commands: string {
    zip = "zip",
    unzip = "unzip",
    list = "list",
    help = "help",
}

void app(const string[] args) {
    immutable string manpage = "\nOVERVIEW: Zippo - the (de)compression utility v2.0\n" ~
				"\nUSAGE: zippo [command] [options]\n" ~
				"\nCOMMANDS:" ~
				"\n\tzip\t\tcompresses a file(s)" ~
				"\n\tunzip\t\tdecompresses a zip file" ~
				"\n\tlist\t\tlists zip file contents" ~
				"\n\thelp\t\tdisplay available options and exit\n" ~
				"\nOPTIONS:\n" ~
				"\n\t";

    if(args.length < 2) {
	writef("%s\n", "\n# Command wasn't specified!\n# Use 'zippo help' for more information.\n");
	return;
    }

    immutable Commands command = (args.canFind([Commands.zip], [Commands.unzip], [Commands.list])) ? 
	(args[1].to!Commands) : (Commands.help);
    
    // verbose writef("%s\n", command);

    switch(command) with(Commands) {
	//case zip:
	//case unzip:
	case list:
	    zutil.listZipContents(args[$-1]);
	    break;
	default:
	    writef("%s\n", manpage);
	    return;
    }
}


