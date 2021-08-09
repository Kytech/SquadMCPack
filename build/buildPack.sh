#!/bin/bash

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)"

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
}

fetch_base_pack() {
    rm -rf "$SCRIPT_DIR/dl/basePack"

    git clone https://github.com/Kytech/CreateTogether.git "$SCRIPT_DIR/dl/basePack"

    pushd "$SCRIPT_DIR/dl/basePack" > /dev/null

    # Remove files and directories excluded from base modpack
    base_pack_exclude=(".git/" ".github/")
    IFS=$'\n' read -d '' -a basepack_exclude_file < "$SCRIPT_DIR/../basepack.exclude"
    base_pack_exclude+=("${basepack_exclude_file[@]}")
    basepack_exclude_comment_regex='^#'
    for file in "${base_pack_exclude[@]}"; do
        if [ ! -z "$file" ] && [[ ! "$file" =~ $basepack_exclude_comment_regex ]]; then
            rm -rf $file
        fi
    done

    cd "$SCRIPT_DIR/../dist"

    # Import base pack with packwiz
    packwiz curseforge import "$SCRIPT_DIR/dl/basePack"

    # TODO: Remove mods listed in an exclude file

    popd > /dev/null
}

display_usage() {
    >&2 echo "Usage: $0 [OPTIONS]"
    >&2 echo ""
    >&2 echo "Options:"
    >&2 echo "  -h, --help              Display this help message"
    >&2 echo "  -u, --update-basepack   Pull down the latest version of the base modpack and refresh the base"
    >&2 echo "                          pack with the latest basepack.exclude settings when building the pack."
    >&2 echo "                          This flag should be specified whenever any .exclude file is updated."
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

# Get list of folders that need to be in the modpack
cd "$SCRIPT_DIR/dl/basePack"
modpack_dir_list="$(find . -maxdepth 1 ! -path . -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a modpack_dirs <<< "$modpack_dir_list"
cd "$SCRIPT_DIR/.."
additional_pack_dirs_list="$(find . -maxdepth 1 ! -path . ! -path ./.git ! -path ./build ! -path ./dist  -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a additional_pack_dirs <<< "$additional_pack_dirs_list"
modpack_dirs+=("${additional_pack_dirs[@]}")

cd "$SCRIPT_DIR/../dist"

# Get names of modpack directories in dist folder
dist_dir_list="$(find . -maxdepth 1 ! -path . -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a dist_dirs <<< "$dist_dir_list"

# Remove directories that are no longer in base pack or repo root
for dir in "${dist_dirs[@]}"; do
    if [[ ! " ${modpack_dirs[@]} " =~ " ${dir} " ]]; then
        rm -rf "$dir"
    fi
done

cd "$SCRIPT_DIR/.."

# Normalize file line endings in this repo to lf
# Copy normalized files to modpack
for dir_to_merge in "${additional_pack_dirs[@]}"; do
    # Check to make sure files do not exist before copying
    files_to_copy_list="$(find ./$dir_to_merge -type f | sed 's|^\./||')"
    IFS=$'\n' read -d '' -a files_to_copy <<< "$files_to_copy_list"
    for file in "${files_to_copy[@]}"; do
        if [ -f "$SCRIPT_DIR/dl/basePack/$file" ]; then
            >&2 echo "Error: Conflicting files. $file already exists in the base modpack."
            >&2 echo "If you need to modify this file, modify it in the base pack and rebuild with the -u flag"
            >&2 echo "after committing and pushing to base pack repo. Remove the file from this repo after"
            >&2 echo "addressing this error."
            exit 1
        fi
    done

    find "./$dir_to_merge" -type f -exec dos2unix {} \;
    cp -R "./$dir_to_merge" ./dist/
done

cd "$SCRIPT_DIR/../dist"

# TODO: Test if mods folder gets wiped every time. If so, add mods from a mods.import file or something
# If they aren't, just manually add things in once.

# Refresh pack index to add new files
packwiz refresh

# TODO: Generate curseforge export in build folder

# TODO: Generate MultiMC export in build folder

# TODO: Print success message and display note to commit any changes made by this script
