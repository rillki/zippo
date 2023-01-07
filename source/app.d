module main;

import std.stdio: writefln;
import std.file: getcwd;
import std.array: split;
import std.string: format;
import std.algorithm: remove;
import std.getopt: getopt, GetoptResult, defaultGetoptPrinter;

import util = zutility;

/// version
enum ZIPPO_VERSION = "0.1.0";

void main(string[] args) {    
    if(args.length < 2) {
        writefln("#zippo: no commands provided! See \'zippo help\' for more info.");
        return;
    }

    // remove the option, since we are going to use getopt later
    const option = args[1];
    args = args.remove(1);

    // check case
    switch(option) {
        case "z":
        case "zip":
            zippoZip(args);
            break;
        case "u":
        case "unzip":
            zippoUnzip(args);
            break;
        case "l":
        case "list":
            zippoList(args);
            break;
        case "v":
        case "version":
            import std.compiler: version_major, version_minor;
            writefln("zippo version %s - A simple command line ZIP utility.", ZIPPO_VERSION);
            writefln("Built with %s v%s.%s on %s", __VENDOR__, version_major, version_minor, __DATE__);
            break;
        case "h":
        case "help":
            writefln("zippo version %s -- A simple command line ZIP utility.", ZIPPO_VERSION);
            writefln("z     zip [OPTIONS]  use -h to read more on creating a zip archive");
            writefln("u   unzip [OPTIONS]  use -h to read on how to extract an archive file");
            writefln("l    list            lists zip archive contents");
            writefln("v version            display current version");
            writefln("h    help            This help information.\n");
            writefln("EXAMPLE: zippo zip ");
            break;
        default:
            writefln("#zippo: Unrecognized option %s!", option);
            break;
    }
}

/++
    Parses zip options

    Params:
        args = command line arguments
+/
void zippoZip(string[] args) {
    if(args.length < 2) {
        writefln("#zippo zip: no commands provided! See \'zippo zip -h\' for more info.");
        return;
    }

    // define additional options
    string
        opt_filename = "myZippoArchive.zip",
        opt_pathToFiles = getcwd,
        opt_include = null,
        opt_exclude = null;
    bool 
        opt_verbose = false;

    // parsing arguments
    GetoptResult argInfo;
    try {
        argInfo = getopt(
            args,
            "name|n", "archive name (default: myZippoArchive.zip)", &opt_filename,
            "path|p", "path to files (default: cwd)", &opt_pathToFiles,
            "include|i", "archive listed files only", &opt_include,
            "exclude|e", "exclude listed files (use either include or exclude)", &opt_exclude,
            "verbose|v", "verbose output", &opt_verbose
        );

        // print help if needed
        if(argInfo.helpWanted) {
            defaultGetoptPrinter("zippo version v%s -- A simple command line ZIP utility.".format(ZIPPO_VERSION), argInfo.options);
            writefln("\nEXAMPLE: zippo zip --path=../temp --include=img1.png,img2.jpg --name=myZippoArchive.zip\n");
            return;
        }
    } catch(Exception e) {
        writefln("#zippo zip: error! %s", e.msg);
        return;
    }

    // call compress function here
    writefln("#zippo zip: STARTING compression...");
    util.compress(opt_filename, opt_pathToFiles,opt_include.split(","), opt_exclude.split(","), opt_verbose);
    writefln("#zippo zip: FINISHED...");
}

/++
    Parses unzip options

    Params:
        args = command line arguments
+/
void zippoUnzip(string[] args) {
    if(args.length < 2) {
        writefln("#zippo zip: no commands provided! See \'zippo zip -h\' for more info.");
        return;
    }

    // define additional options
    string
        opt_filename = "myZippoArchive.zip",
        opt_include = null,
        opt_exclude = null;
    bool 
        opt_verbose = false;

    // parsing arguments
    GetoptResult argInfo;
    try {
        argInfo = getopt(
            args,
            "filename|f", "archive name (default: myZippoArchive.zip)", &opt_filename,
            "include|i", "unarchive listed files only", &opt_include,
            "exclude|e", "exclude listed files (use either include or exclude)", &opt_exclude,
            "verbose|v", "verbose output", &opt_verbose
        );

        // print help if needed
        if(argInfo.helpWanted) {
            defaultGetoptPrinter("zippo version v%s -- A simple command line ZIP utility.".format(ZIPPO_VERSION), argInfo.options);
            writefln("\nEXAMPLE: zippo unzip --include=img1.png,img2.jpg --filename=myZippoArchive.zip\n");
            return;
        }
    } catch(Exception e) {
        writefln("#zippo zip: error! %s", e.msg);
        return;
    }

    // call decompress function here
    writefln("#zippo unzip: STARTING decompression...");
    util.decompress(opt_filename, opt_include.split(","), opt_exclude.split(","), opt_verbose);
    writefln("#zippo unzip: FINISHED...");
}

/++
    Lists zip contents

    Params:
        args = command line arguments
+/
void zippoList(string[] args) {
    if(args.length < 2) {
        writefln("#zippo list: no archive provided!");
        return;
    }

    // list zip contents
    util.listZipContents(args[1]);
}
