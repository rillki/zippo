module zutility;

// std.zip functionality that is used
import std.zip: ZipArchive, ArchiveMember, CompressionMethod;

/* lists zip file contents
    in:
        const string filename => path to the *.zip including the zip file itself
*/
void listZipContents(const string filename = null) {
    import std.stdio: writef, readln;
    import std.file: exists, read;
    
    // check if file exists
    if(!filename.exists) {
        writef("\n%s%s%s\n\n", "# ==> error: Zip file <", filename, "> does not exist!");
        return;
    }

    // read zip file into memory
    ZipArchive zip = new ZipArchive(read(filename));
    
    // print the number of files in a zip file
    // ask the user whether to print the contents of the zip or not
    writef("\n<%s> contains %s files. Show them all? (y/n): ", filename, zip.directory.length);

    if((readln()[0]) == 'y') { 
        // iterate over all zip members
        writef("%10s\t%s\n", "Size", "Name");
        foreach(file, data; zip.directory) {
            // print some info about each member
            writef("%10s\t%s\n", data.expandedSize, file);
        }
    } else {
        writef("%s\n", "# ==> error: Canceled...");
    }

    writef("\n");
}

/* unzips the zip file (or the specified files only contained in a zip)
    in:
	   const string filename    => path to the *.zip including the zip file itself
       const string[] files     => files to unzip, if none are specified, unzips all
       const string[] fignore   => files to exclude from decompression
       const bool verbose       => verbose output
*/
void decompress(const string filename = null, const string[] files = null, const string[] fignore = null, const bool verbose = false) {
    import std.stdio: writef;
    import std.file: isDir, exists, read, write, mkdirRecurse;
    import std.algorithm.searching: canFind;
    import std.algorithm.iteration: each;
    import std.algorithm.mutation: remove;
    import std.path: dirSeparator;
    import std.conv: to;
    
    // check if file exists
    if(!filename.exists) {
        writef("\n%s%s%s\n\n", "# ==> error: Zip file <", filename, "> does not exist!");
        return;
    }

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(filename));
   
    // create the directory structure as in the zip file
    foreach(file, data; zip.directory) {
        if(file[$-1] == dirSeparator.to!char) {
            mkdirRecurse(file);
        }
    }

    // unzip all files
    if(files is null) {
        if(fignore is null) { // unzip all files
	        foreach(file, data; zip.directory) {
	            // skip empty directories
	            if(file[$-1] == dirSeparator.to!char) { continue; }
	
	            // decompress the archive member
	            file.write(zip.expand(data));    
	    
	            // verbose output
	            if(verbose) {
                    writef("Unzipped: %s\n", file);
	            }
            }
        } else { // unzip all files except for files that should be ignored
            string[] findFiles = zip.directory.keys.dup;
            foreach(fi; fignore) {
                findFiles = findFiles.remove!(a => a.canFind(fi));
            }

            foreach(file, data; zip.directory) {
	            // skip empty directories
                if(file[$-1] == dirSeparator.to!char) { continue; }
                
                foreach(findFile; findFiles) {
                    if(file == findFile) {
                        // decompress the archive member
        		        file.write(zip.expand(data));
        		    
        		        // verbose output
        		        if(verbose) {
        			        writef("Unzipped: %s\n", file);
        		        }

                        break;
                    }
                }
            }
        }
    } else { // unzip specified files only
        foreach(file, data; zip.directory) {
            // skip empty directories
            if(file[$-1] == dirSeparator.to!char) { continue; }
            
            foreach(findFile; files) {
                if(file.canFind(findFile)) {
                    // decompress the archive member
        		    file.write(zip.expand(data));
        		    
        		    // verbose output
        		    if(verbose) {
        			    writef("Unzipped: %s\n", file);
        		    }

                    break;
                }
            }
        }
    }
    
    writef("\n");
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
    import std.file: write, exists, getcwd;
    import std.path: dirSeparator;
    
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
        // zip specified files only
        ZipArchive zip = new ZipArchive(); 
        zip.isZip64(true);

        foreach(file; files) {
            if(!exists(path ~ file)) {
                writef("# ==> error: %s does not exist!\n", file);
                continue;
            }

            // archive the file
            ArchiveMember member = new ArchiveMember();
            member.name = file;
            member.expandedData(readFileData(path ~ file));
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
    import std.array: array;
    import std.algorithm.iteration: filter;

    // list dir contents
    string[] files = path.listdir.filter!(f => !f.isDir).array;

    // create zip archive
    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);

    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(file));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);

        // verbose output
        if(verbose) {
            writef("Compressed: %s\n", file);
        }
    }

    write(filename, zip.build());
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
    import std.array: array;
    import std.algorithm.iteration: filter;
    import std.algorithm.searching: canFind;
    import std.algorithm.mutation: remove;

    // list dir contents
    string[] files = path.listdir.filter!(f => !f.isDir).array;

    // exclude files from compression entered by the user
    foreach(fi; fignore) {
        files = files.remove!(a => a.canFind(fi));
    }

    // zip specified files only
    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);

    foreach(file; files) {
        // archive the file
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(file));
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
        writef("%s%s%s\n", "# ==> error: File <", filename, "> does not exist!");
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
    import std.algorithm.iteration: map, filter;
    import std.array: array;
    import std.file: dirEntries, isFile, SpanMode, getcwd;
    import std.path: baseName;

    return dirEntries(((path is null) ? (getcwd) : (path)), SpanMode.breadth)
        .filter!(f => f.isFile)
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
