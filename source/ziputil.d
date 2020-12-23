module ziputil;

enum Defaults {
    Name = "ZIP_FILE",
    Path = "",
    Zip = "y",
}

/*void decompress(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path) {
    import std.zip;
    import std.file: read, write;

    immutable(string) fpath = (path == "" || path[$-1] != '/') ? (path ~ "/") : (path);
    //immutable(string) fzipName = (zipName[$-3] != ".") ? () : ();

    // read a zip file into memory
    ZipArchive zip = new ZipArchive(read(fpath ~ zipName));

    // iterate over all zip members
    foreach (name, am; zip.directory) {
        // decompress the archive member
        write(name, cast(void[])(zip.expand(am)));
    }
}*/

/++ compresses given files in a specified directory into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = "ZIP_FILE"
        string path = ""
        string[] files
+/
void compress(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path, const(string[]) files = null) {
    import std.zip;
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
        string zipName = "ZIP_FILE"
        string path = ""
+/
void compressAll(const(string) zipName = Defaults.Name, const(string) path = Defaults.Path) {
    import std.zip;
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
        const(string) zipName = "ZIP_FILE"
+/
void compressAllCWD(const(string) zipName = Defaults.Name) {
    import std.zip;
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