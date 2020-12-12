module zippo;

void[] readFileData(string path) {
    import std.stdio: File;
    import std.conv: to;

	void[] data;

	File file = File(path, "r");
	while(!file.eof) {
		data ~= cast(void[])(file.readln);
	}

	return data;
}

void compress(string path, string zipName = "ZIP_FILE") {
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

void compressAll(string zipName = "ZIP_FILE") {
    import std.zip;
    import std.file: write, getcwd;

    ZipArchive zip = new ZipArchive();
    string[] files = listdir(getcwd());

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

string[] listdir(string pathname) {
    import std.algorithm;
    import std.array;
    import std.file;
    import std.path;

    return std.file.dirEntries(pathname, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => std.path.baseName(a.name))
        .array;
}
