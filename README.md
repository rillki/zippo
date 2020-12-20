# zippo
### Command line ZIP utility

Zip and unzip files in just a few seconds using your terminal or the command line. No need to click or select anything! 

## Usage:

The full command looks like this:
```D
./zippo name="ZIP_FILE" path="/Desktop/media/files" file="file1|file2|...|fileX"
```

The shortest command using the defaults:
```D
./zippo all
```

A few things to keep in mind [DEFAULT CONFIGURATION]:
1. If `name` is not specified, then `ZIP_FILE` is used by default
2. If `path` is not specified, then the current working directory is used by default
3. If no `file` is specified, then it will compress all files in the directory

To use the default configuration: 
```D
./zippo all
```

To check out the full list of available commands:
```D
./zippo -h
```
