#!/bin/bash

echo "Building Dux Launcher..."
swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher

if [ $? -eq 0 ]; then
    echo "Build successful! Creating app bundle..."
    mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
    mkdir -p bin/DuxAppLauncher.app/Contents/Resources
    cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/DuxAppLauncher.app/Contents/
    cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
    rm bin/DuxAppLauncher
    echo "Running Dux Launcher..."
    open bin/DuxAppLauncher.app
else
    echo "Build failed!"
fi