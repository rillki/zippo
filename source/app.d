import zippo;
import std.zip;
import std.file: write;

import std.stdio;
import std.algorithm;

void main() {
	/* ArchiveMember file1 = new ArchiveMember();
    file1.name = "source/test.txt";
    file1.expandedData(cast(ubyte[])(readFileData("source/test.txt")));
    file1.compressionMethod = CompressionMethod.deflate;

	ZipArchive zip = new ZipArchive();
	zip.addMember(file1);

	void[] compressed_data = zip.build();
	write("test.zip", compressed_data); */
	compressAll;
}
