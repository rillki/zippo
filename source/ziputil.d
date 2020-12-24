module ziputil;

// std.zip functionality that is used
import std.zip: ZipArchive, ArchiveMember, CompressionMethod;

enum Defaults {
    Name = "ZIP_FILE",
    Path = "",
    Zip = "y",
}

/++ unzips the zip file
    in:
        const(string) zipName = Defaults.Name
        const(string) path = Defaults.Path
+/
void decompress(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path) {
    import std.file: read, write;
    import std.algorithm: canFind;

    immutable(string) fpath = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);
    immutable(string) fzipName = (zipName.canFind(".zip")) ? (zipName) : (zipName ~ ".zip");

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(fpath ~ fzipName));

    // iterate over all zip members
    foreach (name, am; zip.directory) {
        // decompress the archive member
        write(name, cast(void[])(zip.expand(am)));
    }
}

/++ lists zip file contents
    in:
        const(string) zipName = Defaults.Name
        const(string) path = Defaults.Path
+/
void listZipContents(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path) {
    import std.stdio: writefln;
    import std.file: read;
    import std.algorithm: canFind;

    immutable(string) fpath = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);
    immutable(string) fzipName = (zipName.canFind(".zip")) ? (zipName) : (zipName ~ ".zip");

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(fpath ~ fzipName));

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
        string[] files = null
+/
void compress(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path, const(string[]) files = null) in {
    assert((files !is null), "Error: specify which files to compress!");
} do {
    import std.file: write;

    immutable(string) fpath = (path != "" && path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive();
    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(cast(ubyte[])(readFileData(fpath ~ file)));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    void[] compressed_data = zip.build();
    write((zipName ~ ".zip"), compressed_data);
}

/++ compresses all files in a specified directory into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = Defaults.Name
        string path = Defaults.Path
+/
void compressAll(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path) {
    import std.file: write, getcwd;

    if(path == "") {
        compressAllCWD(zipName);
        return;
    }

    immutable(string[]) files = cast(immutable(string[]))(listdir(path));
    immutable(string) fpath = (path[$-1] != '/') ? (path ~ "/") : (path);

    ZipArchive zip = new ZipArchive();
    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(cast(ubyte[])(readFileData(fpath ~ file)));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    void[] compressed_data = zip.build();
    write((zipName ~ ".zip"), compressed_data);
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

/++ compresses all files in the current working directory into a single zip file
    in:
        const(string) zipName = Defaults.Name
+/
void compressAllCWD(const(string) zipName = Defaults.Name) {
    import std.file: write, getcwd;

    immutable(string[]) files = cast(immutable(string[]))(listdir(getcwd()));
    
    ZipArchive zip = new ZipArchive();
    foreach(file; files) {
        ArchiveMember member = new ArchiveMember();
        member.name = file;
        member.expandedData(cast(ubyte[])(readFileData(file)));
        member.compressionMethod = CompressionMethod.deflate;

        zip.addMember(member);
    }

    /* OLD:
    void[] compressed_data = zip.build();
    write((zipName ~ ".zip"), compressed_data);*/
    write((zipName ~ ".zip"), zip.build());
}

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