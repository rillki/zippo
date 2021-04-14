# Zippo

### Command line ZIP utility

Zip and unzip files in just a few seconds using your terminal or the command line. No need to click or select anything! 

## Building the Zippo Utility:
Check if you have `dmd`, `gdc` or `ldc` compiler installed on your system, and `make` (optional). Then: 
```
git clone https://github.com/rillki/zippo
``` 
```
cd zippo
```
Finally, type: 
```
make
```

Or you can type out the entire command:
```D
dmd -of=zippo source/*
```

Replace `dmd` with the D compiler you have installed on your system. It will produce an executable `zippo`, add it to your `PATH` on your system.

## Usage:

Compressing a file:
```D
zippo zip --name=myzipfile.zip --path=/Desktop/media/mymovie.mp4
```
`--name` is optional, it will automatically pick up the name.

Decompressing a file:
```D
zippo unzip myzipfile.zip
```

Listing file contents:
```D
zippo list myzipfile.zip
```

When a value for the command is not specified, the default value is used. For example, if `path` is not provided, then the current working directory is used.

To check out the full list of available commands:
```D
zippo help
```

## The Zippo Wiki page
Read more on the [wiki](https://github.com/rillk500/zippo/wiki) page.



