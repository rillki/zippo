module zinterface;

// dlang std library
import std.stdio: writef;
import std.conv: to;
import std.algorithm.searching: canFind, startsWith;
import std.algorithm.iteration: filter, each;
import std.file: getcwd;
import std.getopt: getopt, GetoptResult, defaultGetoptPrinter;

// Zippo module containing functions for working with *.zip files
import zutil = zutility;

// std commands
enum Commands: string {
    zip = "zip",
    unzip = "unzip",
    list = "list",
    help = "help",
}

// std options
enum Options: string {
    verbose = "-v",		// --verbose
    files = "-f",		// --files
    filename = "-n",	// --name
    path = "-p",		// --path
    ignore = "-i",		// --ignore
    
    verboseLong = "--verbose",
    filesLong = "--files",
    filenameLong = "--name",
    pathLong = "--path",
    ignoreLong = "--ignore",

    none = "none",
}

void app(string[] args) {
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
                "\n\t-f, --files\t(un)zip selected files: -f=file1,file2,...,fileX" ~
                "\n\t-n, --name\tzipfile name: -n=file.zip" ~
                "\n\t-p, --path\tpath to files, which should be (de)compressed: -p=someFolder/anotherFolder" ~ 
                "\n\t-i, --ignore\texclude files from (de)compression: -i=file.jpg\n";
    
    // if too few args passed, safely exit
    if(args.length < 2) {
    writef("%s\n", "\n# Command wasn't specified!\n# Use 'zippo help' for more information.\n");
    return;
    }
    
    // Command: zip/unzip/list/help
    immutable Commands command = (args.canFind([Commands.zip], [Commands.unzip], [Commands.list])) ? 
    (args[1].to!Commands) : (Commands.help);
    
    // Options: find the zip filename
    auto l = ((const string[] args, const string canfind) => {
        foreach(arg; args) {
            if(arg.canFind(canfind)) {
                return arg;
            }
        }

        return null;
    });
    string filename = zutil.multipleSplit(l(args, ".zip")(), "=")[$-1];

    // Options: path
    const string path = zutil.multipleSplit(l(args, Options.path)(), "=")[$-1];
    
    // Options: verbose mode?
    bool verbose = (args.canFind([Options.verbose], [Options.verboseLong])) ? (true) : (false);
    
    // Options: (un)zip specified files only?
    const string files = zutil.multipleSplit(l(args, Options.files)(), "=")[$-1];
    
    // Options: exclude some files from compression?
    const string fignore = zutil.multipleSplit(l(args, Options.ignore)(), "=")[$-1];

    // verbose output, if enabled
    if(verbose) {
        writef("\n");
        writef("%17s\t%s\n", "Command:", command);
        writef("%17s\t%s\n", "Zip filename:", ((filename is null) ? ("file does not exist!") : (filename)));
        writef("%17s\t%s\n", "Path:", (path is null) ? (getcwd) : (path));

        if(command != Commands.list) {
            writef("%17s\t%s\n", "Files to (un)zip:", ((files is null) ? ("all") : (files)));
            writef("%17s\t%s\n", "Files to ignore:", ((fignore is null) ? (Options.none) : (fignore)));
        }
    
        writef("\n");
    }
    
    // zip/list/unzip based on command entered
    switch(command) with(Commands) {
        case zip:
            zutil.compress(filename, path, 
                            ((files is null) ? (null) : (zutil.multipleSplit(files, ","))), 
                            ((fignore is null) ? (null) : (zutil.multipleSplit(fignore, ","))), verbose);
            break;
        case unzip:
            zutil.decompress(filename,
                            ((files is null) ? (null) : (zutil.multipleSplit(files, ","))),
                            ((fignore is null) ? (null) : (zutil.multipleSplit(fignore, ","))), verbose);
            break;
        case list:
            zutil.listZipContents(filename);
            break;
        default:
            writef("%s\n", manpage);
            return;
    }
}



