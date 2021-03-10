module zippo;

import ziputil;

import std.stdio: writeln;

/++ a list of all available commands
+/
enum Commands {
    Name = "name",
    Path = "path",
    File = "file",
    Zip = "zip",
    Ignore = "ignore",
    All = "all"
}

/++ handles the zip utility's logic
+/
void zippoUtility(const(string[]) args) {
    immutable string help = "\n/******* Zippo: a command line ZIP utility *******/\n\n" ~
                            "1) name=\"zipName\"\t\tZIP file name\n\t\t\t\t[default: ZIP_FILE is used]\n\n" ~
                            "2) path=\"path\"\t\t\tspecify the directory\n\t\t\t\t[default: cwd is used]\n\n" ~
                            "3) file=\"filename\"\t\tspecify a single file to convert to a ZIP\n\t\t\t\t[default: compresses all files in a directory]\n\n" ~
                            "4) file=\"file1|file2\"\t\tuse the \"|\" bar to add multiple files\n\n" ~
                            "5) zip=y/n/ls\t\t\ty - zip, n - unzip, ls - list zip contents\n\t\t\t\t[default: y]\n\n" ~
                            "6) ignore=\"filename\"\t\tfiles to exclude from compression\n\t\t\t\t[default: none]\n\n" ~
                            "7) ignore=\"file1|file2\"\t\tuse the \"|\" bar to exclude multiple files\n\n" ~
                            "8) all\t\t\t\tuse the defaults\n";

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
    writeln("---------- PROCESS STARTED! ----------");

    // check if we should zip, unzip or list zip contents
    if(info[Commands.Zip] == "y") {
        compressUtility(info);
    } else if(info[Commands.Zip] == "n") {
        decompressUtility(info);
    } else {
        listZipContents(info[Commands.Name], info[Commands.Path]);
    }

    // notify when the user when finished
    writeln("---------- PROCESS FINISHED! ----------");
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

    if((Commands.Ignore in info) is null) {
        info[Commands.Ignore] = Defaults.Ignore;
    }
}

/++ compresses the data into a zip file
    in:
        const(string[string]) info
+/
void compressUtility(const(string[string]) info) {
    // if the defaults are chosen, compress all files in the current directory and save to ZIP_FILE.zip
    if((Commands.All in info) !is null) {
        compressAll;
    } else {
        // if files are not specified, then compress all files in a directory excluding the specified files, if provided
        if((Commands.File in info) is null) {
            if(info[Commands.Ignore] != Defaults.Ignore) {
                ignoreAndCompress(info[Commands.Name], info[Commands.Path], info[Commands.Ignore].multipleSplit("|"));
            } else {
                compressAll(info[Commands.Name], info[Commands.Path]);
            }
        } else {
            compress(info[Commands.Name], info[Commands.Path], info[Commands.File].multipleSplit("|"));
        }
    }
}

/++ decompresses zipped data
    in:
        const(string[string]) info
+/
void decompressUtility(const(string[string]) info) {
    decompress(info[Commands.Name], info[Commands.Path], ((Commands.File in info) ? (info[Commands.File].multipleSplit("|")) : (null)));
}











