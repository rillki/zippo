module zinterface;

// dlang std library
import std.stdio: writef;
import std.conv: to;
import std.algorithm.searching: canFind;
import std.algorithm.iteration: filter, each;

// Zippo module containing functions for working with *.zip files
import zutil = zutility;

// std commands
enum Commands: string {
    zip = "zip",
    unzip = "unzip",
    list = "list",
    help = "help",
}

void app(const string[] args) {
    // quick overview 
    immutable string manpage = "\nOVERVIEW: Zippo - the (de)compression utility v2.0\n" ~
				"\nUSAGE: zippo [command] [options]\n" ~
				"\nCOMMANDS:" ~
				"\n\tzip\t\tcompresses a file(s)" ~
				"\n\tunzip\t\tdecompresses a zip file" ~
				"\n\tlist\t\tlists zip file contents" ~
				"\n\thelp\t\tdisplay available options and exit\n" ~
				"\nOPTIONS:" ~
				"\n\t-v, --verbose\tverbose output";
    
    // if too few args passed, safely exit
    if(args.length < 2) {
	writef("%s\n", "\n# Command wasn't specified!\n# Use 'zippo help' for more information.\n");
	return;
    }
    
    // find the command
    immutable Commands command = (args.canFind([Commands.zip], [Commands.unzip], [Commands.list])) ? 
	(args[1].to!Commands) : (Commands.help);
    
    // find the zip file
    auto l = ((const string[] args) => {
	foreach(arg; args) {
	    if(arg.canFind(".zip")) {
		return arg;
	    }
	}

	return "File does not exist!";
    });
    const string filename = l(args)();

    // verbose mode?
    bool verbose = (args.canFind("-v")) ? (true) : (false);

    // verbose output, if enabled
    if(verbose) {
	writef("\n");
	writef("Command:\t%s\n", command);
	writef("Zip filename:\t%s\n", filename);
	writef("\n");
    }
    
    // zip/list/unzip based on command entered
    switch(command) with(Commands) {
	//case zip:
	//case unzip:
	case list:
	    zutil.listZipContents(filename);
	    break;
	default:
	    writef("%s\n", manpage);
	    return;
    }
}


