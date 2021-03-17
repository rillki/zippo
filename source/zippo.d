module zippo;

import ziputil;

import std.stdio: writeln, writefln;
import std.algorithm.searching: canFind;
import std.algorithm.mutation: remove;

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
                            "<OPTIONS>:\n" ~
                            "\tzip/unzip/list \t\t\tto zip, unzip or list zipfile contents\n\n" ~
                            "\t\t\t\t\t [default: list]\n" ~
                            "<WHERE AND WHAT>:\n" ~ 
                            "\tpath=\"<...>\" \t\t\tspecify a directory, a file(s) to be ziped or unziped\n" ~
                            "\t\t\t\t\t [default: cwd is used]\n" ~
                            "\tfile=\"file1,file2,fileX\" \tuse the \",\" comma to zip/unzip specified files only\n" ~
                            "\t\t\t\t\t [default: includes all files]\n" ~
                            "\tignore=\"file1|file2,fileX\" \tuse the \",\" comma to exclude certains files\n" ~
                            "\t\t\t\t\t [default: none are ignored]\n";

    // display help manual
    if(args.length < 2 || args[1] == "-h" || args[1] == "--help") {
        writeln(help);
        return;
    }
    
    // find what should it do: zip, unzip or list zipfile contents
    immutable(string) action = args.canFind("zip") ? ("zip") : (args.canFind("unzip") ? ("unzip") : ("list"));
    auto newArgs = (args.dup).remove!(a => a == action);

    // get command line arguments
    string[string] info = getCommandLineArguments(newArgs);

    // configure command line arguments (what is not specified will be set to the default value)
    // TODO: start from here, simplify
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











