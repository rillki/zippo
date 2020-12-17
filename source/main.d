import zippo;
import std.zip;
import std.file: write;

import std.stdio;
import std.algorithm;

void main(string[] args) {
	if(args.length < 2) {
		writeln("ERROR! Check the instructions: ./zippo -h");
		return;
	}

	immutable string help = "\n/******* Zippo: a command line ZIP utility *******/\n\n" ~
							"name=\"zipName\"\t\t\tZIP file name\n[default: ZIP_FILE is used]\n\n" ~
							"path=\"path\"\t\t\tspecify the directory\n[default: cwd is used]\n\n" ~
							"file=\"filename\"\t\t\tspecify a single file to convert to a ZIP\n[default: compresses all files in specified directory]\n\n" ~
							"files=\"filename1|...|filenameX\"\tuse the \"|\" bar to add multiple files\n" ~
							"all\t\t\tuse the defaults\n";

	// display help manual
	if(args[1] == "-h") {
		writeln(help);
		return;
	}

	// get command line arguments
	string[string] info;
	for(size_t i = 1; i < args.length; i++) {
		auto s = findSplit(args[i], "=");
		info[s[0]] = s[2];
	}

	if(("all" in info) is null) {
		// if ZIP file name is not specified, assign the defaults
		if(("name" in info) is null) {
			info["name"] = "ZIP_FILE";
		}

		// if path is not specified, assign the defaults
		if(("path" in info) is null) {
			info["path"] = "";
		}

		// if files are not specified, then compress all files in a directory
		if(("file" in info) is null) {
			compressAll(info["name"], info["path"]);
			return;
		}
	}

	// compress all files using the default configuration
	compressAll();
}
