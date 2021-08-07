#!/bin/bash

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)"

# Check for dependencies

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

# Clear download cache
# rm -rf "$SCRIPT_DIR/dl"

# git clone https://github.com/Kytech/CreateTogether.git "$SCRIPT_DIR/dl/basePack"
cd "$SCRIPT_DIR/dl/basePack"

# Remove files and directories not used in the modpack
rm -rf .git/ .github/ automation/ changelogs/ server_files/ .gitattributes .gitignore .prettierrc *.sh *.bat *.jar *.md
rm -rf packmenu/

# Get list of folders in base modpack
basePack_dirList="$(find . -maxdepth 1 ! -path . -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a basePack_dirs <<< "$basePack_dirList"

cd "$SCRIPT_DIR/../dist"

# Get modpack directories in dist folder
repoPack_dirList="$(find . -maxdepth 1 ! -path . -type d | sed 's|^\./||')"
IFS=$'\n' read -d '' -a repoPack_dirs <<< "$repoPack_dirList"

# Remove directories that are no longer in base pack
for dir in "${repoPack_dirs[@]}"; do
    if [[ ! " ${basePack_dirs[@]} " =~ " ${dir} " ]]; then
        rm -rf "$dir"
    fi
done

# packwiz curseforge import "$SCRIPT_DIR/dl/basePack"
