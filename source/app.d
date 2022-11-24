module main;

enum ZIPPO_VERSION = "0.1.0";

void main(string[] args) {
    if(args.length < 2) {
        writefln("#zippo: no commands provided! See \'zippo help\' for more info.");
        return;
    }

    // check case
    switch(args[1]) {
        case "z":
        case "zip":
            break;
        case "u":
        case "unzip":
            break;
        case "l":
        case "list":
            break;
        case "v":
        case "version":
            import std.compiler: version_major, version_minor;
            writefln("zippo version %s - A simple command line ZIP utility.", ZIPPO_VERSION);
            writefln("Built with %s v%s.%s on %s", __VENDOR__, version_major, version_minor, __DATE__);
            break;
        case "h":
        case "help":
            writefln("zippo version %s - A simple command line ZIP utility.", ZIPPO_VERSION);
            writefln("z     zip [OPTIONS]  initializes a new database");
            writefln("u   unzip [OPTIONS]  removes an existing database");
            writefln("l    list [OPTIONS]  switches to the specified database");
            writefln("v version            display current version");
            writefln("h    help            This help manual.\n");
            writefln("EXAMPLE: zippo zip ");
            break;
        default:
            writefln("#zippo: Unrecognized option %s!", args[1]);
            break;
    }
}

void zippoZip() {}
void zippoUnzip() {}
void zippoList() {}

