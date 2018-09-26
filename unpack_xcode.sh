#!/bin/sh
#
# Copyright 2011 Shinichiro Hamaji. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of  conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials
#      provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY Shinichiro Hamaji ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Shinichiro Hamaji OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Usage:
#
#   %./unpack_xcode.sh xcode_3.2.6_and_ios_sdk_4.3__final.dmg
#
# The above commandline will put CLI tools in the dmg package into
# ./xcode_3.2.6_and_ios_sdk_4.3__final/root .
#
# This script was inspired by this document:
# http://devs.openttd.org/~truebrain/compile-farm/apple-darwin9.txt

set -e

dmg=$1
dir=`basename $dmg .dmg`

HFS=5.hfs
if echo $dmg | grep xcode_5.0; then
  # Tested with xcode_5.0.1_command_line_tools
  PKGS="MacOSX10_9_SDK CLTools_Executables"
  XCODE=xcode_5.0
  PKG_DIR="Command Line Developer Tools/Packages"
  HFS=3.hfs
elif echo $dmg | grep xcode_4.4; then
  # Tested with xcode_4.4.1_command_line_tools
  PKGS="DevSDK DeveloperToolsCLI clang llvm-gcc4.2"
  XCODE=xcode_4.4
  PKG_DIR="Command Line Tools*/Packages"
  HFS=3.hfs
elif echo $dmg | grep xcode_4.3; then
  # Tested with xcode_4.3.3_command_line_tools
  PKGS="DevSDK DeveloperToolsCLI clang llvm-gcc4.2"
  XCODE=xcode_4.3
  PKG_DIR="Command Line Tools*/Packages"
elif echo $dmg | grep xcode_4.1; then
  PKGS="MacOSX10.6 gcc4.2 llvm-gcc4.2 DeveloperToolsCLI clang"
  XCODE=xcode_4.1
  PKG_DIR="Applications/Install Xcode.app/Contents/Resources/Packages"
elif echo $dmg | grep xcode_3; then
  PKGS="MacOSX10.6 gcc4.2 gcc4.0 llvm-gcc4.2 DeveloperToolsCLI clang"
  XCODE=xcode_3
  PKG_DIR="*/Packages"
elif echo $dmg | grep xcode_4.; then
  # Tested with xcode_4.6.2_command_line_tools
  # Tested with xcode_4.5.2_command_line_tools
  PKGS="DevSDK DeveloperToolsCLI"
  XCODE=xcode_4.6
  PKG_DIR="Command Line Tools*/Packages"
  HFS=3.hfs
else
  PKGS="MacOSX10.6 gcc4.2 llvm-gcc4.2 DeveloperToolsCLI clang"
  XCODE=xcode_4.0
  PKG_DIR="*/Packages"
fi

rm -fr $dir
mkdir $dir
cd $dir

7z x $dmg
7z x $HFS

if [ $XCODE = "xcode_4.1" ]; then
  7z x -y "Install Xcode/InstallXcode.pkg"
  7z x -y InstallXcode.pkg/Payload
fi

for pkg in $PKGS; do
  7z x -y "$PKG_DIR/$pkg.pkg"
  7z x -y Payload
  mkdir -p $pkg
  cd $pkg
  cpio -i < ../Payload~
  cd ..
  rm -f Payload*
done

rm -fr root
mkdir root
for pkg in $PKGS; do
  if [ $pkg = "MacOSX10.6" ]; then
    cp -R $pkg/SDKs/*/* root
  else
    cd $pkg || continue
    if [ $pkg = "CLTools_Executables" ]; then
      mv Library Library-
      mv Library-/Developer/CommandLineTools/* .
      rm -fr Library-
    fi
    tar -c * | tar -xC ../root
    cd ..
  fi
done

ln -sf "../../System/Library/Frameworks root/Library/Frameworks"
cd root/usr/lib
ln -s system/* .

echo "The package was unpacked into $dir/root"
