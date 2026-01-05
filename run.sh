#!/bin/bash

echo "Building Dux Launcher..."
swiftc -parse-as-library app/AppLauncher.swift -o bin/AppLauncher

if [ $? -eq 0 ]; then
    echo "Build successful! Creating app bundle..."
    mkdir -p bin/AppLauncher.app/Contents/MacOS
    cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
    echo "Running Dux Launcher..."
    open bin/AppLauncher.app
else
    echo "Build failed!"
fi