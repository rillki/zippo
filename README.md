# Zippo
### Command line ZIP utility

Zip and unzip files in just a few seconds using your terminal or the command line. No need to click or select anything! 

## Building the Zippo Utility:
Make sure you have a `dmd` compiler and `make` installed on your system. Then `git clone` the zippo repository and `cd` to `/zippo/source/`. 
Finally, type: 
```
make
```

Or you can type out the entire command:
```D
dmd -of=zippo main.d zippo.d ziputil.d
```

Replace `dmd` with the D compiler you have installed on your system.

## Usage:

The full command looks like this:
```D
./zippo zip=y name="ZIP_FILE" path="/Desktop/media/files" file="file1|file2|...|fileX" exclude=none
```

The shortest command using the default configuration:
```D
./zippo all
```

When a value for the command is not specified, the default value is used. For example, if `path` is not provided, then the current working directory is used.

To check out the full list of available commands:
```D
./zippo -h
```

## The Zippo Wiki page
Read more on the [wiki](https://github.com/rillk500/zippo/wiki) page.



