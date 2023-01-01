module zutility;

import std.zip: ZipArchive, ArchiveMember, CompressionMethod;

/++
    Lists zip contents

    Params:
        name = archive file name
+/
void listZipContents(in string name) {
    import std.stdio: writefln, writef, readln;
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

/* compresses files in a specified directory into a single zip file,
    if the directory is not specified, uses the current working directory
    in:
        const string filename   => zip file name
        const string path       => path to a file or to a directory
        const string[] files    => files to zip, if none are specified, zips all files
        const string[] fignore  => files exclude from compression
        const bool verbose      => verbose output
*/
void compress(string filename = null, string path = null, const string[] files = null, const string[] fignore = null, const bool verbose = false) {
    import std.stdio: writef;
    import std.file: write, exists, getcwd, isDir;
    import std.path: dirSeparator;
    import std.parallelism: parallel;
    import std.algorithm.mutation: remove;
    import std.algorithm.searching: canFind;

    // default file name
    if(filename is null) { filename = "archive.zip"; }

    // check if path is specified
    if(path is null) {
        path = getcwd ~ dirSeparator;
    } else {
        // check if path exists
        if(!path.exists) {
            writef("\n%s%s%s\n\n", "# ==> error: Path <", path, "> does not exist!");
            return;
        }
    }

    // compress everyting in cwd
    if(files is null) {
        if(fignore is null) { // compress all files
            compressAll(filename, path, verbose);
        } else { // compress all files, except for files that should be ignored
            ignoreAndCompress(filename, path, fignore, verbose);
        }
    } else { // compress the specified files only
        // list dir contents
        string[] zfiles = path.listdir;

        // exclude files from compression 
        foreach(file; files.parallel) {
            zfiles = zfiles.remove!(a => !a.canFind(file));
        }

        // zip specified files only
        ZipArchive zip = new ZipArchive(); 
        zip.isZip64(true);

        foreach(file; zfiles.parallel) {
            // archive the file
            ArchiveMember member = new ArchiveMember();
            if(file.isDir) {
                member.name = file ~ dirSeparator;
            } else {
                member.name = file;
                member.expandedData(readFileData(file));
            }
            
            member.compressionMethod = CompressionMethod.deflate;
            zip.addMember(member);

            // verbose output
            if(verbose) {
                writef("Compressed: %s\n", file);
            }
        }

        if(zip.totalEntries > 0) {
            write(filename, zip.build());
        }

        // verbose output
        if(verbose) {
            writef("\nINFO: %s files compressed.", zip.totalEntries);
        }
    }

    writef("\n");
}

/* compresses all files in a specified directory into a single zip file,
    if the directory is not specified, uses the current working directory
    in:
        const string filename   => zip file name
        const string path       => path to a directory
        const bool verbose      => verbose output
*/
private void compressAll(const string filename = null, const string path = null, const bool verbose = false) {
    import std.stdio: writef;
    import std.file: write, isDir;
    import std.path: dirSeparator;
    import std.array: array;
    import std.conv: to;
    import std.algorithm.iteration: filter;
    import std.parallelism: parallel;

    // get all dir contents
    string[] files = path.listdir;
    
    // create a zip archive file
    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);
    
    // zip files
    foreach(file; files.parallel) {
        ArchiveMember member = new ArchiveMember();
        if(file.isDir) {
            member.name = file ~ dirSeparator;
        } else {
            member.name = file;
            member.expandedData(readFileData(file));
        }

        member.compressionMethod = CompressionMethod.deflate;
        zip.addMember(member);

        // verbose output
        if(verbose) {
            writef("Compressed: %s\n", file);
        }
    }

 
    if(zip.totalEntries > 0) {
        write(filename, zip.build());
    }

    // verbose output
    if(verbose) {
        writef("\nINFO: %s files compressed.", zip.totalEntries);
    }
    
    writef("\n");
}

/* compresses all files in a directory excluding specified files; 
    if the directory is not specified, uses the current working directory
    in:
        const string filename   => zip file name
        const string path       => path to a file or to a directory
        const string[] fignore  => exclude files from compression
        const bool verbose      => verbose output
*/
void ignoreAndCompress(const string filename = null, string path = null, const string[] fignore = null, const bool verbose = false) {
    import std.stdio: writef;
    import std.file: write, isDir;
    import std.path: dirSeparator;
    import std.array: array;
    import std.algorithm.iteration: filter;
    import std.algorithm.searching: canFind;
    import std.algorithm.mutation: remove;
    import std.parallelism: parallel;

    // list dir contents
    string[] zfiles = path.listdir;

    // exclude files from compression entered by the user
    foreach(fi; fignore) {
        zfiles = zfiles.remove!(a => a.canFind(fi));
    }

    // zip specified files only
    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);
    
    // zip files
    foreach(file; zfiles.parallel) {
        // archive the file
        ArchiveMember member = new ArchiveMember();
        if(file.isDir) {
            member.name = file ~ dirSeparator;
        } else {
            member.name = file;
            member.expandedData(readFileData(file));
        }

        member.compressionMethod = CompressionMethod.deflate;
        zip.addMember(member);

        // verbose output
        if(verbose) {
            writef("Compressed: %s\n", file);
        }
    }

    if(zip.totalEntries > 0) {
        write(filename, zip.build());
    }

    // verbose output
    if(verbose) {
        writef("\nINFO: %s files compressed.", zip.totalEntries);
    }

    writef("\n");
}

/* reads from a file and returns the data as ubyte[]
    in:
        const string filename
    out:
        ubyte[]
*/
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

/* lists all files in a directory
    in:
        const string path
    out:
        string[]
*/

string[] listdir(const string path = null) {
    import std.algorithm.iteration: map;
    import std.array: array;
    import std.file: dirEntries, SpanMode, getcwd;
    import std.path: baseName;

    return dirEntries(((path is null) ? (getcwd) : (path)), SpanMode.breadth)
        .map!(a => a.name)
        .array;
}

/* splits a string into multiple strings given a seperator
    in:
        const string str => string
        const string sep => seperator
    out:
        string[]
*/
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
