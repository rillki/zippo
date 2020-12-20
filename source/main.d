module main;

import std.file: write;
import std.stdio: writeln;
import std.algorithm: findSplit, canFind;

import zippo;

void main(string[] args) {
	if(args.length < 2) {
		writeln("ERROR! Check the instructions: ./zippo -h");
		return;
	}

	immutable string help = "\n/******* Zippo: a command line ZIP utility *******/\n\n" ~
							"name=\"zipName\"\t\t\tZIP file name\n[default: ZIP_FILE is used]\n\n" ~
							"path=\"path\"\t\t\tspecify the directory\n[default: cwd is used]\n\n" ~
							"file=\"filename\"\t\t\tspecify a single file to convert to a ZIP\n[default: compresses all files in specified directory]\n\n" ~
							"file=\"file1|file2\"\t\tuse the \"|\" bar to add multiple files\n" ~
							"all\t\t\t\tuse the defaults\n";

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

	//auto s = info["file"].multipleSplit("|");
	//s.writeln;
	//return;

	// notify the user that the process has begun
	writeln("---------- OPERATION STARTED! ----------");

	// if the defaults are chosen, compress all files in the current directory and save to ZIP_FILE.zip
	if(("all" in info) !is null) {
		compressAll;
	} else {
		// if ZIP file name is not specified, assign the defaults
		if(("name" in info) is null) {
			info["name"] = Defaults.ZIPNAME;
		}

		// if path is not specified, assign the defaults
		if(("path" in info) is null) {
			info["path"] = Defaults.PATH;
		}

		// if files are not specified, then compress all files in a directory
		if(("file" in info) is null) {
			compressAll(info["name"], info["path"]);
		} else {
			compress(info["name"], info["path"], info["file"].multipleSplit("|"));
		}
	}

	// notify when the user when the process is done
	writeln("-------- OPERATION SUCCESSFULL! --------");
}
