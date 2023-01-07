module zutility;

import std.zip: ZipArchive, ArchiveMember, CompressionMethod;

/++
    Lists zip contents

    Params:
        name = archive file name
+/
void listZipContents(in string name) {
    import std.stdio: writef, writefln, readln;
    import std.conv: to;
    import std.file: exists, read;
    import std.algorithm: endsWith, filter, count;

    enum MAX_DISPLAY_ELEMENTS = 12;

    // check if file exists
    if(!name.exists) {
        writefln("#zippo list: error! Zip file <%s> does not exist!", name);
        return;
    }

    // read zip file into memory
    ZipArchive zip = new ZipArchive(read(name));
    
    // ask the user whether to print the contents of the zip file
    char input = 'y';
    immutable elementsInZip = zip.directory.keys.filter!(a => !a.endsWith("/")).count();
    if(elementsInZip > MAX_DISPLAY_ELEMENTS) {
        writefln("#zippo list: <%s> contains %s files.", name, zip.directory.length);
        writef("Show them all? (y/N): ");
        input = readln()[0];
    }

    if(input == 'y' || input == 'Y') { 
        // iterate over all zip members
        writefln("%8s\t%s", "Size", "Name");
        foreach(file, data; zip.directory) {
            // skip folders
            if(file.endsWith("/")) {
                continue;
            }

            // print some info about each member
            const fileSize = (
                (data.expandedSize > 1_000_000_000) ? ((data.expandedSize.to!float / 1_000_000_000).to!string ~ " Gb") : (
                    (data.expandedSize > 1_000_000) ? ((data.expandedSize.to!float / 1_000_000).to!string ~ " Mb") : (
                        (data.expandedSize > 1_000) ? ((data.expandedSize.to!float / 1_000).to!string ~ " Kb") : (
                            data.expandedSize.to!string ~ " b"
                        )
                    )
                )
            );
            
            writefln("%10s\t%s", fileSize, file);
        }
    } else {
        writefln("#zippo list: cancelled...");
    }
}

/++
    Extracts file contents

    Params:
        filename = path the ZIP file including the filename itself
        finclude = unzip the specified files only
        fexclude = unzip all files excluding the specified files only
        verbose = verbose output
+/
void decompress(in string filename, string[] finclude = null, string[] fexclude = null, in bool verbose = false) {
    import std.stdio: writefln;
    import std.file: isDir, exists, read, write, mkdirRecurse;
    import std.path: dirSeparator;
    import std.array: array, empty;
    import std.conv: to;
    import std.algorithm: canFind, endsWith, remove;
    import std.parallelism: parallel;

    // check if file exists
    if(!filename.exists) {
        writefln("#zippo unzip: error! Zip file <%s> does not exist!", filename);
        return;
    }

    // check if both finclude and fexclude are specified
    if(!finclude.empty && !fexclude.empty) {
        writefln("#zippo unzip: specify either what to extract or exclude, not both!");
        return;
    }

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(filename));
   
    // create the directory structure as in the zip file
    foreach(path, data; zip.directory) {
        if(path.endsWith("/")) {
            mkdirRecurse(path);
        }
    }

    // extract selected files only
    if(!finclude.empty) {
        foreach(pair; zip.directory.byKeyValue.parallel) {
            // skip directories
            if(pair.key.endsWith("/")) { continue; }

            foreach(idx, el; finclude) {
                if(pair.key.endsWith(el)) {
                    // decompress the archive member
                    pair.key.write(zip.expand(pair.value));    
            
                    // verbose output
                    if(verbose) {
                        writefln("#zippo unzip: <%s> decompressed!", pair.key);
                    }

                    // remove the element we decompressed from finclude and break out the loop
                    finclude = finclude.remove(idx);
                    break;
                }
            }
        }
    } else if(!fexclude.empty) { // exclude selected files, extract everything else
        foreach(pair; zip.directory.byKeyValue.parallel) {
            // skip directories
            if(pair.key.endsWith("/")) { continue; }

            // check if we should skip current entry
            bool shouldSkip = false;
            foreach(idx, el; fexclude) {
                if(pair.key.endsWith(el)) {
                    shouldSkip = true;

                    // remove the element we need to skip from the exclude list
                    fexclude = fexclude.remove(idx);
                    break;
                }
            }

            if(!shouldSkip) {
                // decompress the archive member
                pair.key.write(zip.expand(pair.value));    
        
                // verbose output
                if(verbose) {
                    writefln("#zippo unzip: <%s> decompressed!", pair.key);
                }
            }
        }
    } else { // extract all
        foreach(pair; zip.directory.byKeyValue.parallel) {
            // skip directories
            if(pair.key.endsWith("/")) { continue; }

            // decompress the archive member
            pair.key.write(zip.expand(pair.value));    
    
            // verbose output
            if(verbose) {
                writefln("#zippo unzip: <%s> decompressed!", pair.key);
            }
        }
    }
}

/++
    Compresses specified files

    Params:
        filename = path the ZIP file including the filename itself
        finclude = unzip the specified files only
        fexclude = unzip all files excluding the specified files only
        verbose = verbose output
+/
void compress(in string filename, in string pathToFiles, string[] finclude = null, string[] fexclude = null, in bool verbose = false) {
    import std.stdio: writef, writefln, readln;
    import std.path: buildPath;
    import std.file: write, exists, getcwd, isDir;
    import std.array: empty;
    import std.algorithm: endsWith, remove;
    import std.parallelism: parallel;

    // check if archive already exists
    if(getcwd.buildPath(filename).exists) {
        // ask the user if zippo should override the file
        char input = 'y';
        writef("#zippo zip: <%s> already exists! Override? (y/N) ", filename);
        input = readln()[0];

        // if not, return
        if(input == 'n' || input == 'N' || input == '\n') {
            writefln("#zippo zip: cancelled...");
            return;
        }
    }

    // check if pathToFiles exists
    if(!pathToFiles.exists) {
        writefln("#zippo zip: error! Files path <%s> does not exist!", pathToFiles);
        return;
    }

    // check if both finclude and fexclude are specified
    if(!finclude.empty && !fexclude.empty) {
        writefln("#zippo zip: specify either what to archive or exclude, not both!");
        return;
    }

    // create a new zip archive
    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);

    // quickly add member to archive
    void zipAddArchiveMember(ref ZipArchive zip, in string file) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(file));
        member.compressionMethod = CompressionMethod.deflate;
        zip.addMember(member);
    }

    // get all files in path
    auto filesInPath = pathToFiles.listdir();
    if(!finclude.empty) {  // compress selected files only
        foreach(file; filesInPath) {
            // skip directories
            if(file.isDir()) { continue; }

            // compress selected files only
            foreach(idx, el; finclude) {
                if(file.endsWith(el)) {
                    // create archive member and compress file contents
                    zipAddArchiveMember(zip, file);

                    // verbose output
                    if(verbose) {
                        writefln("#zippo zip: <%s> compressed!", file);
                    }

                    // remove the element we decompressed from finclude and break out the loop
                    finclude = finclude.remove(idx);
                    break;
                }
            }
        }
    } else if(!fexclude.empty) { // exclude selected files, compress everything else
        foreach(file; filesInPath) {
            // skip directories
            if(file.isDir()) { continue; }

            // check if we should skip current entry
            bool shouldSkip = false;
            foreach(idx, el; fexclude) {
                if(file.endsWith(el)) {
                    shouldSkip = true;

                    // remove the element we need to skip from the exclude list
                    fexclude = fexclude.remove(idx);
                    break;
                }
            }

            if(!shouldSkip) {
                // create archive member and compress file contents
                zipAddArchiveMember(zip, file);

                // verbose output
                if(verbose) {
                    writefln("#zippo zip: <%s> compressed!", file);
                }
            }
        }
    } else { // compress all
        foreach(file; filesInPath) {
            // skip directories
            if(file.isDir()) { continue; }

            // create archive member and compress file contents
            zipAddArchiveMember(zip, file);

            // verbose output
            if(verbose) {
                writefln("#zippo zip: <%s> compressed!", file);
            }
        }
    }

    // save zip file
    if(zip.totalEntries > 0) {
        write(getcwd.buildPath(filename), zip.build());
    } else {
        writefln("#zippo zip: nothing to archive!");
        return;
    }

    // verbose output
    if(verbose) {
        writefln("#zippo zip: %s files compressed.", zip.totalEntries);
    }
}

/++
    Reads from a file and returns the data as ubyte[]

    Params:
        filename = path to file

    Returns:
        ubyte[] raw data
+/
ubyte[] readFileData(const string filename) {
    import std.stdio: writef, File;
    import std.file: exists;
    import std.conv: to;
    
    // check if file exists
    if(!filename.exists) {
        writef("%s%s%s\n", "# error: File <", filename, "> does not exist!");
        return [];
    }
    
    // open the file
    File file = File(filename, "r"); 
    scope(exit) { file.close(); }
    
    // read file data
    ubyte[] data;
    while(!file.eof) {
        data ~= file.readln;
    }

    return data;
}

/++
    Lists all files in a directory

    Params:
        path = path to file

    Returns:
        string[] array of files in path
+/
string[] listdir(const string path = null) {
    import std.array: array;
    import std.path: baseName;
    import std.file: dirEntries, SpanMode, getcwd, isFile;
    import std.algorithm: map;

    return dirEntries(((path is null) ? (getcwd) : (path)), SpanMode.breadth)
        .map!(a => a.name)
        .array;
}

/++
    Splits a string into multiple strings given a separator

    Params:
        str = string
        sep = separator

    Returns:
        string[]
+/
string[] multipleSplit(const string str = "", const string sep = "") { 
    import std.algorithm: findSplit, canFind;

    string[] s;
    if(str.canFind(sep)) {
        auto temp = str.findSplit(sep);
        s ~= temp[0];
    
        s ~= temp[$-1].multipleSplit(sep);
    } else {
        s ~= str;
    }

    return s;
}
