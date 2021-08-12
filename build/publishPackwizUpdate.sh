#!/bin/bash

SCRIPT_DIR="$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)"

cd "$SCRIPT_DIR/.."
git subtree push --prefix pack-meta origin gh-pages