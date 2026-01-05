# Justfile for Dux Launcher

# Default target - build and run
default: run

# Build the app
build:
    swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher

# Run the app (builds first)
run: build
    mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
    mkdir -p bin/DuxAppLauncher.app/Contents/Resources
    cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/DuxAppLauncher.app/Contents/
    cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
    rm bin/DuxAppLauncher
    open bin/DuxAppLauncher.app

# Install to /Applications
install: build
    mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
    mkdir -p bin/DuxAppLauncher.app/Contents/Resources
    cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/DuxAppLauncher.app/Contents/
    cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
    rm bin/DuxAppLauncher
    rm -rf /Applications/Dux\ Launcher.app
    cp -R bin/DuxAppLauncher.app "/Applications/Dux Launcher.app"

# Clean build artifacts
clean:
    rm -rf bin/DuxAppLauncher
    rm -rf bin/DuxAppLauncher.app
    rm -rf .build

# Watch and rebuild on file changes
watch:
    #!/usr/bin/env bash
    while inotifywait -e modify app/DuxAppLauncher.swift 2>/dev/null || fswatch -1 app/DuxAppLauncher.swift; do
        just build
    done

# Show help
help:
    @just --list

# Run tests
test:
    @echo "No tests configured yet"

# Create release
release: clean build
    mkdir -p release
    cp -R bin/DuxAppLauncher.app release/
    @echo "Release built in release/"

# List recipes
list:
    @just --list