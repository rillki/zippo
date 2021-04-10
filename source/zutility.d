module zutility;

// std.zip functionality that is used
import std.zip: ZipArchive, ArchiveMember, CompressionMethod;

/++ default configuration
+/
enum Defaults {
    Name = "ZIP_FILE",
    Path = "",
    Zip = "y",
    Ignore = "none"
}

/* lists zip file contents
    in:
        string filename => path to the *.zip including the zip file itself
*/
void listZipContents(const(string) filename) {
    import std.stdio: writef, readln;
    import std.file: exists, read;
    
    // check if file exists
    if(!filename.exists) {
        writef("\n%s%s%s\n\n", "# error: Zip file <", filename, "> does not exist!");
        return;
    }

    // read zip file into memory
    ZipArchive zip = new ZipArchive(read(filename));
    
    // print the number of files in a zip file
    // ask the user whether to print the contents of the zip or not
    writef("\n<%s> contains %s files. Show them all? (y/n): ", filename, zip.directory.length);
    //const(char) c = (readln())[0];

    if((readln()[0]) == 'y') {
	// iterate over all zip members
	writef("%10s\t%s\n", "Size", "Name");
	foreach(file, data; zip.directory) {
	    // print some info about each member
	    writef("%10s\t%s\n", data.expandedSize, file);
	}
    } else {
	writef("%s\n", "# error: Canceled...");
    }

    writef("\n");
}

/* unzips the zip file (or the specified files only contained in a zip)
    in:
	string filename => path to the *.zip including the zip file itself
        string[] files	=> files to unzip, if none are specified, unzips all
*/
void decompress(const string filename, const string[] files = null, const bool verbose = false) {
    import std.stdio: writef;
    import std.file: isDir, exists, read, write, mkdirRecurse;
    import std.algorithm: canFind;
    
    // check if file exists
    if(!filename.exists) {
        writef("\n%s%s%s\n\n", "# error: Zip file <", filename, "> does not exist!");
        return;
    }

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(filename));
   
    // create the directory structure as in the zip file
    foreach(file, data; zip.directory) {
        if(file[$-1] == '/') {
	   mkdirRecurse(file);
        }
    }

    // unzip all files
    if(files is null) {
	foreach(file, data; zip.directory) {
	    // skip empty directories
	    if(file[$-1] == '/') { continue; }
	
	    // decompress the archive member
	    file.write(zip.expand(data));    
	    
	    // verbose output
	    if(verbose) {
		writef("Unzipped: %s\n", file);
	    }
	}
    } else { // unzip specified files only
	foreach(findFile; files) {
	    foreach(file, data; zip.directory) {
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
        writef("\n%s%s%s\n\n", "# error: File <", filename, "> does not exist!");
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
string[] listdir(const string path) {
    import std.algorithm;
    import std.array;
    import std.file;
    import std.path;

    return std.file.dirEntries(((path == "") ? (getcwd) : (path)), SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => std.path.baseName(a.name))
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




/***************OLD STUFF**********************/


/++ compresses given files in a specified directory into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
        const(string[]) files = null
+/
void compress(string zipName = Defaults.Name, string path = Defaults.Path, const(string[]) files = null) in {
    assert((files !is null), "Error: specify which files to compress!");
} do {
    import std.stdio: writefln;
    import std.file: write, exists;

    path = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);

    foreach(file; files) {
        if(!exists(path ~ file)) {
            writefln("Error: %s does not exist!", file);
            continue;
        }

        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(path ~ file));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    if(zip.totalEntries > 0) {
        write((zipName ~ ".zip"), zip.build());
    }
}

/++ compresses all files in a specified directory into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void compressAll(string zipName = Defaults.Name, string path = Defaults.Path) {
    import std.file: write, getcwd;

    string[] files = (listdir((path == "") ? (getcwd) : (path)));
    path = (path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);

    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(path ~ file));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    write((zipName ~ ".zip"), zip.build());
}

/++ compresses all files in a directory excluding the selected files, if provided, into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
        string[] ignorefiles = null
+/
void ignoreAndCompress(string zipName = Defaults.Name, string path = Defaults.Path, string[] ignorefiles = null) {
    import std.file: write, getcwd;
    import std.algorithm: remove;
    import std.stdio: writeln;

    string[] files = listdir((path == "") ? (getcwd) : (path));
    foreach(file; files) {
        foreach(ignorefile; ignorefiles) {
            if(file == ignorefile) {
                files = files.remove!(a => (a == ignorefile));
		ignorefiles = ignorefiles.remove!(a => (a == ignorefile));
	    }
        }
    }
    path = (path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive(); 
    zip.isZip64(true);

    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(path ~ file));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    write((zipName ~ ".zip"), zip.build());
}

/++ compresses all files in the current working directory into a single zip file
    in:
        const(string) zipName = Defaults.Name
+/
void compressAllCWD(const(string) zipName = Defaults.Name) {
    import std.file: write, getcwd;

    immutable(string[]) files = cast(immutable(string[]))(listdir(getcwd()));
    
    ZipArchive zip = new ZipArchive(); zip.isZip64(true);
    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(readFileData(file));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    write((zipName ~ ".zip"), zip.build());
}

