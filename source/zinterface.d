module zinterface;

// dlang std library
import std.stdio: writef;
import std.conv: to;
import std.algorithm.searching: canFind, startsWith;
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

enum Options: string {
    verbose = "-v",
    files = "-f",
    
    verboseLong = "--verbose",
    filesLong = "--files",

    none = "none",
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
				"\n\t-v, --verbose\tverbose output" ~ 
				"\n\t-f, --files\tunzip selected files: -f=file1,file2,...,fileX\n";
    
    // if too few args passed, safely exit
    if(args.length < 2) {
	writef("%s\n", "\n# Command wasn't specified!\n# Use 'zippo help' for more information.\n");
	return;
    }
    
    // Command: zip/unzip/list/help
    immutable Commands command = (args.canFind([Commands.zip], [Commands.unzip], [Commands.list])) ? 
	(args[1].to!Commands) : (Commands.help);
    
    // find the zip filename
    auto l = ((const string[] args, const string canfind) => {
	foreach(arg; args) {
	    if(arg.canFind(canfind)) {
		return arg;
	    }
	}

	return "none";
    });
    const string filename = l(args, ".zip")();

    // Options: verbose mode?
    bool verbose = (args.canFind([Options.verbose], [Options.verboseLong])) ? (true) : (false);
    
    // Options: unzip specified files only?
    const string files = zutil.multipleSplit(l(args, Options.files)(), "=")[$-1];
    
    // verbose output, if enabled
    if(verbose) {
	writef("\n");
	writef("Command:\t%s\n", command);
	writef("Zip filename:\t%s\n", ((filename == Options.none) ? ("file does not exist!") : (filename)));
	
	if(command == Commands.unzip) {
	    writef("Files to unzip:\t%s\n", ((files == Options.none) ? ("all") : (files)));
	}
	
	writef("\n");
    }
    
    // zip/list/unzip based on command entered
    switch(command) with(Commands) {
	//case zip:
	case unzip:
	    zutil.decompress(filename, (files == Options.none ? (null) : (zutil.multipleSplit(files, ","))), verbose);
	    break;
	case list:
	    zutil.listZipContents(filename);
	    break;
	default:
	    writef("%s\n", manpage);
	    return;
    }
}


