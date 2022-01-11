#!/usr/bin/env bash
#   ---------------------------------------------------
#   File          : build-linux.sh
#   Authors       : ccmywish <ccmywish@qq.com>
#   Created on    : <2022-1-11>
#   Last modified : <2022-1-11>
#
#   Build cr on Linux via Bash
#   ---------------------------------------------------

echo "Building for Linux x64"
shards build 
echo ""

# echo ";1.0.0;" | sed -e 's/;*$//' -e 's/^;//'    # 1.0.0

version=$(awk '/CRYPTIC_VERSION = / {print $3}' src/cr.cr) # "1.0.0";
version="${version##\"}"    # retain tail
version="${version%%\"}"   # retain head

echo "cr version: $version "

binname="./bin/cr-${version}-amd64-unknown-linux"

if [[ -f $binname ]]; then 
    rm $binname
fi

mv ./bin/cr $binname
echo "Generate Linux binary in ./bin"
