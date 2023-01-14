# Zippo
Zip, unzip and list archive contents in just a few seconds using your terminal. No need to click or select anything! [Download](https://github.com/rillki/zippo/releases) the precompiled binary or build it yourself down below.

### Usage
```
zippo version 0.2.0 -- A simple command line ZIP utility.
z     zip [OPTIONS]  use -h to read more on creating a zip archive
u   unzip [OPTIONS]  use -h to read on how to extract an archive file
l    list            lists zip archive contents
v version            display current version
h    help            This help information.

EXAMPLE: zippo zip -p=assets/hello
```

### Building and Installing
#### Required
* [D compiler](https://dlang.org/download) (DMD is recommended)
* [DUB](https://dub.pm) package manager

#### Compiling
1. Clone the repository to your machine:
```
git clone https://github.com/rillki/zippo.git
```
2. Open your terminal or command line and go to `zippo` folder:
```
cd zippo
```
3. Build the binary
```
dub --build=release
```

Your will find the binary in the `bin/` folder. Add it to your `PATH` to use it freely.

### LICENSE
All code is licensed under the MIT license.


