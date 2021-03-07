module ziputil;

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

/++ unzips the zip file (or the specified files only contained in a zip)
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void decompress(string zipName = Defaults.Name, string path = Defaults.Path, string[] files = null) {
    import std.stdio: writefln;
    import std.file: read, write;
    import std.algorithm: canFind;

    path = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);
    zipName = (zipName.canFind(".zip")) ? (zipName) : (zipName ~ ".zip");

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(path ~ zipName));
    if(files is null) { // if true, unzip all files
        // iterate over all zip members
        foreach(file, data; zip.directory) {
            // decompress all archive members
            write(file, zip.expand(data));
        }
    } else { // else unzip only the selected files
        foreach(file; files) {
            if((file in zip.directory) is null) {
                writefln("Error: %s does not exist!", file);
                continue;
            }
            
            // decompress the selected files
            write(file, zip.expand(zip.directory[file]));
        }
    }
}

/++ lists zip file contents
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void listZipContents(string zipName = Defaults.Name, string path = Defaults.Path) {
    import std.stdio: writef, readln;
    //import std.string: strip;
    import std.file: read;
    import std.algorithm: canFind;

    path = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);
    zipName = (zipName.canFind(".zip")) ? (zipName) : (zipName ~ ".zip");

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(path ~ zipName));
    
    // print number of files in a zip file and
    // then ask the user whether to print the contents of the zip or not
    writef("The zip contains %s files. Show them all? (y/n): ", zip.directory.length);
    char c = (readln())[0];

    if(c == 'y') {
	// iterate over all zip members
	writef("%10s\t%s\n", "Size", "Name");
	foreach(file, data; zip.directory) {
	    // print some data about each member
	    writef("%10s\t%s\n", data.expandedSize, file);
	}
    }
}

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

/++ splits a string into multiple strings given a seperator
    in:
        const(string) str = ""
        const(string) path = ""
    out:
        string[]
+/
string[] multipleSplit(const(string) str = "", const(string) sep = "") in {
    assert((str != ""), "Error: string is empty, nothing to split!");
    assert((str != ""), "Error: seperator string is empty");
} do {
    import std.algorithm: findSplit, canFind;

    static string[] s;
    if(str.canFind(sep)) {
        auto temp = findSplit(str, sep);
        s ~= temp[0];

        multipleSplit(temp[2], sep);
    } else {
        s ~= str;
    }

    return s;
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

/++ reads from a file and returns the data as ubyte[]
    in:
        const(string) filename
    out:
        ubyte[]
+/
ubyte[] readFileData(const(string) filename) {
    import std.stdio: File;
    import std.conv: to;

    File file = File(filename, "r"); 
    scope(exit) { file.close(); }
    
    ubyte[] data;
    while(!file.eof) {
        data ~= file.readln;
    }

    return data;
}

/++ lists all files in a directory
    in:
        const(string) path
    out:
        string[]
+/
string[] listdir(const(string) path) {
    import std.algorithm;
    import std.array;
    import std.file;
    import std.path;

    return std.file.dirEntries(((path == "") ? (getcwd) : (path)), SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => std.path.baseName(a.name))
        .array;
}
