#!/bin/bash

echo "Building Dux App Launcher..."
swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher

if [ $? -eq 0 ]; then
    echo "Build successful! Installing to ~/Applications..."
    mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
    mkdir -p bin/DuxAppLauncher.app/Contents/Resources
    cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/DuxAppLauncher.app/Contents/
    cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
    rm bin/DuxAppLauncher
    rm -rf ~/Applications/DuxAppLauncher.app
    cp -R bin/DuxAppLauncher.app ~/Applications/DuxAppLauncher.app
    echo "✓ Installed to ~/Applications/DuxAppLauncher.app"
    echo "Running Dux App Launcher..."
    open -g ~/Applications/DuxAppLauncher.app
else
    echo "Build failed!"
fi