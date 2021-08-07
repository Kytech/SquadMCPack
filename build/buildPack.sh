#!/bin/bash

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

script_dir="$(dirname "${BASH_SOURCE[0]}")"

rm -rf "$script_dir/dl"

git clone https://github.com/Kytech/CreateTogether.git "$script_dir/dl/basePack"
cd "$script_dir/dl/basePack"

rm -rf .git/ .github/ automation/ changelogs/ server_files/ .gitattributes .gitignore .prettierrc *.sh *.bat *.jar *.md