module zippo;

void compress(const(string) zipName = "ZIP_FILE", const(string) path = "", const(string[]) files = null) {
    import std.zip;
    import std.file: write;

    ArchiveMember member = new ArchiveMember();
    member.name = path;
    member.expandedData(cast(ubyte[])(readFileData(path)));
    member.compressionMethod = CompressionMethod.deflate;

	ZipArchive zip = new ZipArchive();
	zip.addMember(member);

	void[] compressed_data = zip.build();
	write((zipName ~ ".zip"), compressed_data);
}

/+ compresses all files in a specified directory into a single zip file,
if the directory is not specified, uses the current working directory
    in:
        string zipName = "ZIP_FILE"
        string path = ""
+/
void compressAll(const(string) zipName = "ZIP_FILE", const(string) path = "") {
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

string[string] splitArg(const(string) arg) {
    import std.algorithm: findSplit;

    auto s = findSplit(arg, "=");
    return [s[0]: s[2]];
}

/************************** PRIVATE **************************/

private {
    /+ compresses all files in the current working directory into a single zip file
        in:
            string zipName = "ZIP_FILE"
    +/
    void compressAllCWD(const(string) zipName = "ZIP_FILE") {
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

        void[] compressed_data = zip.build();
        write((zipName ~ ".zip"), compressed_data);
    }

    /+ reads from a file and return the data as void
        in:
            string path
        out:
            void[]
    +/
    void[] readFileData(const(string) path) {
        import std.stdio: File;
        import std.conv: to;

        void[] data;
        File file = File(path, "r"); 
        scope(exit) { file.close(); }

        while(!file.eof) {
            data ~= cast(void[])(file.readln);
        }

        return data;
    }

    /+ lists all files in a directory
        in:
            string path
        out:
            string[]
    +/
    string[] listdir(const(string) path) {
        import std.algorithm;
        import std.array;
        import std.file;
        import std.path;

        return std.file.dirEntries(path, SpanMode.shallow)
            .filter!(a => a.isFile)
            .map!(a => std.path.baseName(a.name))
            .array;
    }

}