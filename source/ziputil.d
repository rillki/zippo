module ziputil;

// std.zip functionality that is used
import std.zip: ZipArchive, ArchiveMember, CompressionMethod;

enum Defaults {
    Name = "ZIP_FILE",
    Path = "",
    Zip = "y",
}

/++ unzips the zip file (or the specified files only contained in a zip)
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void decompress(string zipName = Defaults.Name, string path = Defaults.Path, string[] files = null) {
    import std.file: read, write;
    import std.algorithm: canFind;

    path = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);
    zipName = (zipName.canFind(".zip")) ? (zipName) : (zipName ~ ".zip");

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(path ~ zipName));
    if(files is null) { // if true, unzip all files
        // iterate over all zip members
        foreach(name, data; zip.directory) {
            // decompress the archive member
            write(name, cast(void[])(zip.expand(data)));
        }
    } else { // else unzip only the selected files
        foreach(file; files) {
            write(file, cast(void[])(zip.expand(zip.directory[file])));
        }
    }
}

/++ lists zip file contents
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void listZipContents(string zipName = Defaults.Name, string path = Defaults.Path) {
    import std.stdio: writefln;
    import std.file: read;
    import std.algorithm: canFind;

    path = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);
    zipName = (zipName.canFind(".zip")) ? (zipName) : (zipName ~ ".zip");

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(path ~ zipName));

    // iterate over all zip members
    writefln("%10s\t%s", "Size", "Name");
    foreach(name, data; zip.directory) {
        // print some data about each member
        writefln("%10s\t%s", data.expandedSize, name);
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
    import std.file: write;

    path = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive();
    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(cast(ubyte[])(readFileData(path ~ file)));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    write((zipName ~ ".zip"), zip.build());
}

/++ compresses all files in a specified directory into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void compressAll(string zipName = Defaults.Name, string path = Defaults.Path) {
    import std.file: write, getcwd;

    immutable(string[]) files = cast(immutable(string[]))(listdir((path == "") ? (getcwd) : (path)));
    path = (path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive();
    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(cast(ubyte[])(readFileData(path ~ file)));
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
    assert((str != ""), "Error: string is empty!");
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

///++ compresses all files in the current working directory into a single zip file
//    in:
//        const(string) zipName = Defaults.Name
//+/
//void compressAllCWD(const(string) zipName = Defaults.Name) {
//    import std.file: write, getcwd;

//    immutable(string[]) files = cast(immutable(string[]))(listdir(getcwd()));
    
//    ZipArchive zip = new ZipArchive();
//    foreach(file; files) {
//        ArchiveMember member = new ArchiveMember();
//        member.name = file;
//        member.expandedData(cast(ubyte[])(readFileData(file)));
//        member.compressionMethod = CompressionMethod.deflate;

//        zip.addMember(member);
//    }

//    write((zipName ~ ".zip"), zip.build());
//}

/++ reads from a file and return the data as void
    in:
        const(string) filename
    out:
        void[]
+/
void[] readFileData(const(string) filename) {
    import std.stdio: File;
    import std.conv: to;

    File file = File(filename, "r"); 
    scope(exit) { file.close(); }
    
    void[] data;
    while(!file.eof) {
        data ~= cast(void[])(file.readln);
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