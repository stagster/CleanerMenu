#!/bin/bash
set -e
echo "Compiling CleanerMenu..."
swiftc -o CleanerMenu CleanerMenu.swift -framework Cocoa
echo "Creating .app bundle..."
rm -rf CleanerMenu.app
mkdir -p CleanerMenu.app/Contents/MacOS CleanerMenu.app/Contents/Resources
mv CleanerMenu CleanerMenu.app/Contents/MacOS/
cp icon.icns CleanerMenu.app/Contents/Resources/
cp Info.plist CleanerMenu.app/Contents/
echo "Signing..."
codesign --force --deep --sign "$(security find-identity -v -p basic | grep 'Apple Development' | head -1 | awk '{print $2}')" CleanerMenu.app 2>/dev/null || echo "No cert found, skipping sign"
echo "Done → CleanerMenu.app"
