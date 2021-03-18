module zippo;

import ziputil;

import std.stdio: write, writeln, writefln;
import std.algorithm.searching: canFind;
import std.path: dirSeparator;

/*
# ZIP
: zippo zip
    zip all files in cwd
: zippo zip path=/Desktop
    zip all files in '/Desktop'
: zippo zip name=flower.zip
    zip all files in cwd, name the zip file as 'flower.zip'
: zippo zip file=flower1.png,flower2.jpg,flowers.txt
    zip only 'flower1.png', 'flower2.jpg' and 'flowers.txt'
: zippo zip ignore=flower7.png,flower3.jpg
    zip all files in cwd excluding 'flower7.png' and 'flower3.jpg'

# UNZIP
: zippo unzip
    unzip all *.zip files in cwd

# LIST
: zippo list
    error! 
: zippo list path=/Desktop/zipfile.zip
    list contents of 'zipfile.zip' located at '/Desktop'
: zippo list path=/Desktop name=zipfile.zip
    list contents of 'zipfile.zip' located at '/Desktop'


*/

// TODO: 
// - ignoreAndCompress
// - compress


/++ a list of all available commands
+/
enum Commands {
    Name = "name",
    Path = "path",
    File = "file",
    Ignore = "ignore",
}

/++ handles the zip utility's logic
+/
void zippoUtility(const(string[]) args) {
    import std.array: empty;

    immutable string help = "\n/******* Zippo: a command line ZIP utility *******/\n\n" ~
                            "<OPTIONS>:\n" ~
                            "\tzip/unzip/list \t\t\tto zip, unzip or list zipfile contents\n" ~
                            "\t-h/--help \t\t\tprint man page\n" ~ 
                            "\t-v/--verbose \t\t\tverbose mode, output the entire process\n\n" ~ 
                            "<WHERE AND WHAT>:\n" ~ 
                            "\tpath=\"<...>\" \t\t\tspecify a directory, a file(s) to be ziped or unziped\n" ~
                            "\t\t\t\t\t [default: cwd is used]\n" ~
                            "\tfile=\"file1,file2,fileX\" \tuse the \",\" comma to zip/unzip specified files only\n" ~
                            "\t\t\t\t\t [default: includes all files]\n" ~
                            "\tignore=\"file1|file2,fileX\" \tuse the \",\" comma to exclude certains files\n" ~
                            "\t\t\t\t\t [default: none are ignored]\n"; 

    // display help manual
    if(args.length < 2 || args[1] == "-h" || args[1] == "--help" || args[1] == "-v" || args[1] == "--verbose") {
        writeln(help);
        return;
    }
    
    // find what should it do: zip, unzip or list zipfile contents
    immutable(string) action = args.canFind("zip") ? ("zip") : (args.canFind("unzip") ? ("unzip") : (args.canFind("list") ? ("list") : ("")));
    if (action.empty()) {
        writeln("\n# Action wasn't specified! [zip/unzip/list]");
        writeln("# Use -h or --help for more information.\n");
        return;
    }

    // get command line arguments
    immutable(string[string]) info = getCommandLineArguments(args);
    writeln(info);

    // notify the user that the process has begun
    writeln("---------- PROCESS STARTED! ----------");

    // check if we should zip, unzip or list zip contents
    if(action == "zip") {
        compressUtility(info);
    } else if(action == "unzip") {
        decompressUtility(info);
    } else {
        if(info[Commands.Path].canFind(".zip")) {
            listZipContents(info[Commands.Path]);
        } else {
            listZipContents(info[Commands.Path] ~ dirSeparator ~ info[Commands.Name]);
        }
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
immutable(string[string]) getCommandLineArguments(const(string[]) args) {
    import std.algorithm: findSplit, canFind;
    import std.file: getcwd;

    string[string] info = [
        Commands.Name : "zipfile.zip",
        Commands.Path : getcwd(),
        Commands.File : "none",
        Commands.Ignore : "none",
    ];

    for(size_t i = 1; i < args.length; i++) {
        auto s = findSplit(args[i], "=");
        info[s[0]] = s[2];
    }

    return cast(immutable)(info);
}

/++ compresses the data into a zip file
    in:
        const(string[string]) info
+/
void compressUtility(const(string[string]) info) {
    import std.stdio: readln;

    // if the defaults are chosen, compress all files in the current directory and save to ZIP_FILE.zip
    if(info[Commands.File] == "none" && info[Commands.Ignore] == "none") {
        write("# Procede to ziping all files in the directory? (y/n): ");
        const(char) c = (readln())[0];

        if(c == 'y') {
            compressAll;
        }

        return;
    } else {
        // if some files are excluded from the compression ignore them
        // and compress the rest;
        // if only certain files are specified for compression
        // ignore the rest
        if(info[Commands.Ignore] != "none") {
            ignoreAndCompress(info[Commands.Name], info[Commands.Path], info[Commands.Ignore].multipleSplit("|"));
        } else {
            compress(info[Commands.Name], info[Commands.Path], info[Commands.File].multipleSplit("|"));
        }


        
        /*if((Commands.File in info) is null) {
            if(info[Commands.Ignore] != Defaults.Ignore) {
                ignoreAndCompress(info[Commands.Name], info[Commands.Path], info[Commands.Ignore].multipleSplit("|"));
            } else {
                compressAll(info[Commands.Name], info[Commands.Path]);
            }
        } else {
            compress(info[Commands.Name], info[Commands.Path], info[Commands.File].multipleSplit("|"));
        }*/
    }
}

/++ decompresses zipped data
    in:
        const(string[string]) info
+/
void decompressUtility(const(string[string]) info) {
    decompress(info[Commands.Name], info[Commands.Path], ((Commands.File in info) ? (info[Commands.File].multipleSplit("|")) : (null)));
}











