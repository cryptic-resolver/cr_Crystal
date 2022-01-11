#!/usr/bin/env bash
#   ---------------------------------------------------
#   File          : build-linux.sh
#   Authors       : ccmywish <ccmywish@qq.com>
#   Created on    : <2022-1-11>
#   Last modified : <2022-1-12>
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

# Can't use $version in ''
# awk '{sub("cr_ver=\"1.0.0\"","cr_ver=\"3.0.0\"")} 1' install/i-template.sh > install/i.sh

ruby << EOF
    a = File.read("./install/i-template.sh"); 
    a.sub!("cr_ver=\"1.0.0\"","cr_ver=\"${version}\"");
    File.write("./install/i.sh",a);
EOF

echo "Generate i.sh in install/"
echo
