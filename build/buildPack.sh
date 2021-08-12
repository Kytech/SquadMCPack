#!/bin/bash

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)"
COMMENT_REGEX='^#'
ABSOLUTE_PATH_REGEX="^[\"']?/"

dependency_check() {
    if ! which dos2unix > /dev/null; then
        >&2 echo "Error: dos2unix not found."
        >&2 echo "Either install the dos2unix utility, or, if on Windows, ensure you are"
        >&2 echo "using the latest version of git for Windows (which should include dos2unix)."
        exit 1
    fi

    if ! which packwiz > /dev/null; then
        >&2 echo "Error: packwiz not found."
        >&2 echo "Packwiz can be downloaded from https://github.com/comp500/packwiz"
        exit 1
    fi

    if ! which curl > /dev/null; then
        >&2 echo "Error: curl not found."
        >&2 echo "Curl can be installed via a package mamager or downloaded from https://curl.se/"
        >&2 echo "On Windows, curl is shipped with the OS by default since Windows 10 version 1803"
        >&2 echo "(build 17063 or newer). Older Windows versions should download/install curl manually."
        exit 1
    fi
}

fetch_base_pack() {
    if [ -d "$SCRIPT_DIR/dl/basePack" ]; then
        echo "Clearing base pack download cache..."
        rm -rf "$SCRIPT_DIR/dl/basePack"
    fi

    echo "Cleaning workspace and pack meta..."
    pushd "$SCRIPT_DIR/../pack-meta" > /dev/null
    find .  -maxdepth 1 -type f -name "*.toml" -exec rm "{}" \;
    find . -maxdepth 1 ! -path . -type d -exec rm -rf "{}" \;
    popd > /dev/null

    echo "Pulling down latest version of base pack..."
    git clone https://github.com/Kytech/CreateTogether.git "$SCRIPT_DIR/dl/basePack"
    echo "Successfully pulled down latest version of base pack!"

    pushd "$SCRIPT_DIR/dl/basePack" > /dev/null

    # Remove files and directories excluded from base modpack
    echo "Removing files from base pack specified in basepack.exclude..."
    base_pack_exclude=(".git/" ".github/")
    IFS=$'\n' read -d '' -a basepack_exclude_file < "$SCRIPT_DIR/../basepack.exclude"
    base_pack_exclude+=("${basepack_exclude_file[@]}")
    for file in "${base_pack_exclude[@]}"; do
        if [ ! -z "$file" ] && [[ ! "$file" =~ $COMMENT_REGEX ]]; then
            # Strip off any preceding single slashes to avoid deleting something important by accident (like root)
            if [[ "$file" =~ $ABSOLUTE_PATH_REGEX ]]; then
                file="$(echo "$file" | sed -E "s|([\"'])?/(.*)(\"')?|\1\2\3|")"
            fi
            # Disallow double-dot parent directory specifier to avoid this file from impacting anything above
            # the base pack directory tree
            if [[ "$(dirname "$file")" =~ ".." ]]; then
                >&2 echo "ERROR: Syntax Error in basepack.exclude"
                >&2 echo "Use of '..' in a path in basepack.exclude is not permitted."
                exit 1
            fi
            rm -rf $file
            echo "Removed $file from base pack."
        fi
    done
    echo "Removal of files from base pack complete!"

    cd "$SCRIPT_DIR/../pack-meta"

    # Import base pack with packwiz
    echo "Importing base pack..."
    packwiz curseforge import "$SCRIPT_DIR/dl/basePack"
    echo "Import of base pack complete!"

    # Remove excluded mods
    echo "Removing mods from base pack specified in basepack_mods.exclude..."
    IFS=$'\n' read -d '' -a basepack_mod_exclude < "$SCRIPT_DIR/../basepack_mods.exclude"
    for mod in "${basepack_mod_exclude[@]}"; do
        if [ ! -z "$mod" ] && [[ ! "$mod" =~ $COMMENT_REGEX ]]; then
            packwiz remove "$mod"
        fi
    done
    echo "Removal of mods from base pack complete!"

    popd > /dev/null
}

display_usage() {
    >&2 echo "Usage: $0 [OPTIONS]"
    >&2 echo ""
    >&2 echo "This script builds/re-builds the modified version of the base modpack based on the contents of"
    >&2 echo "the mods.include, basepack.exclude, and basepack_mods.exclude files while also importing the"
    >&2 echo "contents of the root of the repo into the minecraft instance folder of the resulting pack."
    >&2 echo ""
    >&2 echo "Options:"
    >&2 echo "  -h, --help              Display this help message"
    >&2 echo "  -u, --update-basepack   Pull in the latest version of the base modpack and refresh the pack"
    >&2 echo "                          with the latest mod include/exclude file contents. This flag should be"
    >&2 echo "                          specified whenever any .exclude file is updated or when removing mods"
    >&2 echo "                          from the mods.include file."
}

dependency_check

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    display_usage    
    exit 0
fi

valid_opts=("-h" "--help" "-u" "--update-basepack")
if [ ! $# == 0 ] && [[ ! " ${valid_opts[@]} " =~ " $1 " ]]; then
    display_usage
    exit 2
fi

if [ ! -d "$SCRIPT_DIR/dl/basePack" ] || [ "$1" == "-u" ] || [ "$1" == "--update-basepack" ]; then
    fetch_base_pack
fi

# Get list of folders and files that need to be in the modpack
echo "Enumerating files to add to modpack..."
cd "$SCRIPT_DIR/dl/basePack"
modpack_files=()
modpack_dir_list="$(find . -maxdepth 1 ! -path . -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a modpack_dirs <<< "$modpack_dir_list"
for dir in "${modpack_dirs[@]}"; do
    modpack_dir_files_list="$(find "$dir" -type f)"
    IFS=$'\n' read -d '' -a modpack_dir_files <<< "$modpack_dir_files_list"
    modpack_files+=("${modpack_dir_files[@]}")
done
cd "$SCRIPT_DIR/.."
additional_pack_dirs_list="$(find . -maxdepth 1 ! -path . ! -path ./.git ! -path ./build ! -path ./pack-meta  -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a additional_pack_dirs <<< "$additional_pack_dirs_list"
modpack_dirs+=("${additional_pack_dirs[@]}")
for dir in "${additional_pack_dirs[@]}"; do
    modpack_dir_files_list="$(find "$dir" -type f)"
    IFS=$'\n' read -d '' -a modpack_additional_dir_files <<< "$modpack_dir_files_list"
    modpack_files+=("${modpack_additional_dir_files[@]}")
done
echo "Enumeration complete!"

cd "$SCRIPT_DIR/../pack-meta"

echo "Removing files and folders that are no longer included in the pack..."

# Get names of modpack directories in pack-meta folder, excluding the packwiz managed mods folder
pack_meta_dir_list="$(find . -maxdepth 1 ! -path . ! -path ./mods -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a pack_meta_dirs <<< "$pack_meta_dir_list"

# Remove files and directories that are no longer in base pack or repo root
for dir in "${pack_meta_dirs[@]}"; do
    if [[ ! " ${modpack_dirs[@]} " =~ " ${dir} " ]]; then
        rm -rf "$dir"
        echo "Removed folder: $dir"
    else
        meta_files_list="$(find "$dir" -type f)"
        IFS=$'\n' read -d '' -a meta_files <<< "$meta_files_list"
        for file in "${meta_files[@]}"; do
            if [[ ! " ${modpack_files[@]} " =~ " $file " ]]; then
                rm "$file"
                echo "Removed file: $file"
            fi
        done
    fi
done

echo "Removal of old files complete!"

cd "$SCRIPT_DIR/.."

# Normalize file line endings in this repo to lf
# Copy normalized files to modpack
echo "Adding and normalizing files to the pack..."
for dir_to_merge in "${additional_pack_dirs[@]}"; do
    # Check to make sure files do not exist before copying
    files_to_copy_list="$(find "$dir_to_merge" -type f)"
    IFS=$'\n' read -d '' -a files_to_copy <<< "$files_to_copy_list"
    for file in "${files_to_copy[@]}"; do
        echo "Checking for conflicts for $file..."
        if [ -f "$SCRIPT_DIR/dl/basePack/$file" ]; then
            >&2 echo "Error: Conflicting files. $file already exists in the base modpack."
            >&2 echo "If you need to modify this file, modify it in the base pack and rebuild with the -u flag"
            >&2 echo "after committing and pushing to base pack repo. Remove the file from this repo after"
            >&2 echo "addressing this error."
            exit 1
        fi
        echo "No conflicts found for $file!"
    done

    echo "Adding and normalizing files from $dir_to_merge..."
    find "./$dir_to_merge" -type f -exec dos2unix "{}" \;
    cp -R "./$dir_to_merge" ./pack-meta/
    echo "Successfully added files from $dir_to_merge to the pack!"
done

cd "$SCRIPT_DIR/../pack-meta"

mod_install_err="false"

# Add mods from mod imports file
echo "Adding mods from mods.include..."
IFS=$'\n' read -d '' -a mod_imports < "$SCRIPT_DIR/../mods.include"
for mod in "${mod_imports[@]}"; do
    if [ ! -z "$mod" ] && [[ ! "$mod" =~ $COMMENT_REGEX ]]; then
        if ! packwiz curseforge install $mod; then
            >&2 echo "ERROR: Unable to install mod: $mod"
            >&2 echo "Try specifying the project/mod ID or a file ID instead."
            >&2 echo "If you need a specific version, you can also try the direct download URL if not already attempted."
            mod_install_err="true"
        fi
    fi
done

if [ "$mod_install_err" == "true" ]; then
    echo "Errors occurred when adding mods from mods.include. Not all mods were successfully added."
else
    echo "Successfully added all mods from mods.include!"
fi

# Refresh pack index to add new files
echo "Update/rebuild modpack metadata..."
packwiz refresh
echo "Pack metadata refresh complete!"

# Build curseforge pack
echo "Building curseforge formatted modpack..."
if [ ! -d "$SCRIPT_DIR/out" ]; then mkdir "$SCRIPT_DIR/out"; fi
packwiz curseforge export
mv CreateTogether.zip "$SCRIPT_DIR/out/SquadMCPack-Client-Curse.zip"
echo "Finished building curseforge modpack!"

# TODO: Generate MultiMC export in build folder

# Run details message
if [ "$mod_install_err" == "true" ]; then
    >&2 echo $'\nWARN: Unable to install all mods from mods.include file. Check the above output for details.\n'
    echo "The modpack build has completed with errors. Not all specified mods were included in the pack."
else
    echo $'\nThe modpack build has completed successfully!\n'
fi

echo "If any changes to this pack are intended to be commited to the modpack repository to be made permanent,"
echo "please ensure all modified files are committed. This is required as this script has made modifications"
echo "to files that must be committed to the repository to ensure proper modpack builds on other machines."
