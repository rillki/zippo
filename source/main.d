module main;

import std.file: write;
import std.stdio: writeln;
import std.algorithm: findSplit, canFind;

import zippo;

void main(string[] args) {
	immutable string help = "\n/******* Zippo: a command line ZIP utility *******/\n\n" ~
							"1) name=\"zipName\"\t\tZIP file name\n\t\t\t\t[default: ZIP_FILE is used]\n\n" ~
							"2) path=\"path\"\t\t\tspecify the directory\n\t\t\t\t[default: cwd is used]\n\n" ~
							"3) file=\"filename\"\t\tspecify a single file to convert to a ZIP\n\t\t\t\t[default: compresses all files in specified directory]\n\n" ~
							"4) file=\"file1|file2\"\t\tuse the \"|\" bar to add multiple files\n\n" ~
							"5) zip=y/n\t\t\ty - zip, n - unzip\n\t\t\t\t[default: y]\n\n" ~
							"6) all\t\t\t\tuse the defaults\n";

	// display help manual
	if(args.length < 2 || args[1] == "-h") {
		writeln(help);
		return;
	}

	// get command line arguments
	string[string] info;
	for(size_t i = 1; i < args.length; i++) {
		auto s = findSplit(args[i], "=");
		info[s[0]] = s[2];
	}

	// UNFINISHED.... REDO....
	// ADD: uncompress multiple zip files
	// ADD: compress all, but exclude some files (?)
	if(("zip" in info) !is null) {
		if(info["zip"] == "n") {
			// if ZIP file name is not specified, assign the defaults
			if(("name" in info) is null) {
				info["name"] = Defaults.ZIPNAME ~ ".zip";
			}

			// if path is not specified, assign the defaults
			if(("path" in info) is null) {
				info["path"] = Defaults.PATH;
			}

			writeln("unzipping....");
			uncompress(info["name"], info["path"]);
			return;
		}
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
