module zippo;

import ziputil;

//import std.file: write;
import std.stdio: writeln;

/++ a list of all available commands
+/
enum Commands {
    Name = "name",
    Path = "path",
    File = "file",
    Zip = "zip",
    All = "all"
}

/++ handles the utility's logic
+/
void zippoUtility(const(string[]) args) {
    immutable string help = "\n/******* Zippo: a command line ZIP utility *******/\n\n" ~
                            "1) name=\"zipName\"\t\tZIP file name\n\t\t\t\t[default: ZIP_FILE is used]\n\n" ~
                            "2) path=\"path\"\t\t\tspecify the directory\n\t\t\t\t[default: cwd is used]\n\n" ~
                            "3) file=\"filename\"\t\tspecify a single file to convert to a ZIP\n\t\t\t\t[default: compresses all files in a directory]\n\n" ~
                            "4) file=\"file1|file2\"\t\tuse the \"|\" bar to add multiple files\n\n" ~
                            "5) zip=y/n\t\t\ty - zip, n - unzip\n\t\t\t\t[default: y]\n\n" ~
                            "6) all\t\t\t\tuse the defaults\n";

    // display help manual
    if(args.length < 2 || args[1] == "-h") {
        writeln(help);
        return;
    }

    // get command line arguments
    string[string] info = getCommandLineArguments(args);

    // configure command line arguments (what is not specified will be set to the default value)
    info.configureCommanLineArguments();

    // notify the user that the process has begun
    writeln("---------- OPERATION STARTED! ----------");

    // should we zip or unzip a file
    if(info[Commands.Zip] == "y") {
        compressUtility(info);
    } else {
        decompressUtility(info);
    }

    // notify when the user when finished
    writeln("-------- OPERATION SUCCESSFULL! --------");
}

/++ splits command line arguments into string[string] using "=" seperator
    in:
        const(string[string]) args
    out:
        string[string]
+/
string[string] getCommandLineArguments(const(string[]) args) {
    import std.algorithm: findSplit;

    string[string] info;
    for(size_t i = 1; i < args.length; i++) {
        auto s = findSplit(args[i], "=");
        info[s[0]] = s[2];
    }

    return info;
}

/++ configures command line arguments to the default values if the value is not specified by the user
    in:
        string[string] info
+/
void configureCommanLineArguments(string[string] info) {
    import std.algorithm: findSplit, canFind;

    if((Commands.Zip in info) is null) {
        info[Commands.Zip] = Defaults.Zip;
    }

    if((Commands.Name in info) is null) {
        info[Commands.Name] = Defaults.Name;
    }

    if((Commands.Path in info) is null) {
        info[Commands.Path] = Defaults.Path;
    }
}

/++ compresses the data into a zip file
    in:
        const(string[string]) info
+/
void compressUtility(const(string[string]) info) {
    // if the defaults are chosen, compress all files in the current directory and save to ZIP_FILE.zip
    if(("all" in info) !is null) {
        compressAll;
    } else {
        // if files are not specified, then compress all files in a directory
        if(("file" in info) is null) {
            compressAll(info["name"], info["path"]);
        } else {
            compress(info["name"], info["path"], info["file"].multipleSplit("|"));
        }
    }
}

/++ decompresses zipped data
    in:
        const(string[string]) info
+/
void decompressUtility(const(string[string]) info) {
    // UNFINISHED.... REDO....
    // ADD: decompress multiple zip files
    // ADD: compress all, but exclude some files (?)
    decompress(info["name"], info["path"]);
}











