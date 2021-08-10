# SquadMCPack

This modpack builds off of the [CreateTogether](https://github.com/NillerMedDild/CreateTogether) modpack to further tweak and expand on it for the use of a personal server. This repository works in conjunction with a fork of the create together modpack.

To download and use the pack, skip down to the downloading section.

This repository mostly consists of a build script that applies modifications to a [fork of the CreateTogether modpack.](https://github.com/Kytech/CreateTogether) Modifications to the original CreateTogether pack are managed in both this repository and the fork of CreateTogether. The fork of CreateTogether manages edits to existing CreateTogether mod configs, while additions and removal of mods and files from CreateTogether are managed in this repo.

The [fork](https://github.com/Kytech/CreateTogether) of the CreateTogether modpack is what is referred to as the base pack for this project. The base pack is a fork of the original to allow an easier workflow for pulling in updates from the original pack while preserving modifications to configs in the original pack mods.

## Downlaoding

TODO: Fill out this section
## Building and Modifying the Pack

Building of this pack is handled via a series of configuration files and a build script. This script takes the base pack, applies modifications, and exports a new modpack with the configured changes.

The build script is located in `build/`. It has a dependency of packwiz, dos2unix, and curl. These utilities need to be available in your PATH environment variable. If you run the script without the dependencies installed, you will be prompted with information as to where to obtain these tools based on your OS.

This script should have the needed UNIX permissions set to be executable. For Windows, this script can be executed
through Git Bash.

Files in the `pack-meta/` directory and the `build/dl` directory are managed by the build script and should not be manually edited. Any changes to any files made by the build script should be committed to Git if the changes are to be permanent.

### Building the Pack

Execute the `build/buildPack.sh` script with the `-h` or `--help` flags to see usage information:

```
$ ./buildPack.sh -h
Usage: buildPack.sh [OPTIONS]

This script builds/re-builds the modified version of the base modpack based on the contents of
the mods.include, basepack.exclude, and basepack_mods.exclude files while also importing the
contents of the root of the repo into the minecraft instance folder of the resulting pack.

Options:
  -h, --help              Display this help message
  -u, --update-basepack   Pull in the latest version of the base modpack and refresh the base
                          pack import with the latest .exclude file contents. This flag should be
                          specified whenever any .exclude file is updated or when removing mods.
```

To build the pack from a fresh clone of this repo, simply execute the `buildPack.sh` script. The built pack will
be placed in the `build/out` directory.

### Modifying the Pack

Modifying the pack is done primarily by adding files to folders in the root of this repository, which will be copied
to the resulting modpack, and by editing the .exclude and .include files.

#### Adding Mods and other Files

For Mods: Add a new line to the `mods.include` file containing the curse project/file download link for the mod you wish to add.

For Files to Add to the Instance/.minecraft folder of the pack: Create a folder in the root of the repository and add the needed files. The name of this folder will be the name in the .minecraft/instance folder. If the folder already exists, files will be added to the existing directory. The pack will not build if the file already exists in the base pack. In that case, you should edit the file directly in the [base pack repository](https://github.com/Kytech/CreateTogether) and follow the directions below for updating the base pack for those specific files.

For both types of additions, run the `buildPack.sh` script after making these modifications to apply them to the pack. If this is a permanent update to the pack, commit any changed files.

#### Removing Mods form mods.include

This is as straightforward as deleting the line in the file for the corresponding mod. After removing from `mods.include`, you should re-run the build script with the `-u` flag as follows:

```
buildPack.sh -u
```

#### Updating and Adjusting the Base Pack

By default, when rebuilding the modpack, the latest version of the base/upstream pack, is not pulled by default, instead relying on the cached copy if it exists. Whenever an update/modification has been made to the base/upstream pack, you must re-run the build script with the `-u` flag. Additionally, the `-u` flag must be specified when updating any `.exclude` files. The command script is executed as follows:

```
buildPack.sh -u
```

This will pull in the latest changes from the base pack and apply any new base pack exclusions (detailed below).

To exclude files and mods from the base pack, edit the `basepack_mods.exclude` and `basepack.exclude` files, using the format detailed in the comments of those files. The `basepack_mods.exclude` file defines mods from the base pack to remove, while the `basepack.exclude` file defines files from the base modpack to remove (files that would be placed in the root of the modpack instance). When rebuilding the pack after modifying one of these files, be sure to include the `-u` flag when running the build script as described above.