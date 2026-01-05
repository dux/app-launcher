# Justfile for Dux Launcher

# Default target - build and run
default: run

# Build the app
build:
    swiftc -parse-as-library app/AppLauncher.swift -o bin/AppLauncher

# Run the app (builds first)
run: build
    mkdir -p bin/AppLauncher.app/Contents/MacOS
    cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/AppLauncher.app/Contents/
    open bin/AppLauncher.app

# Install to /Applications
install: build
    mkdir -p bin/AppLauncher.app/Contents/MacOS
    cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/AppLauncher.app/Contents/
    rm -rf /Applications/Dux\ Launcher.app
    cp -R bin/AppLauncher.app "/Applications/Dux Launcher.app"

# Clean build artifacts
clean:
    rm -rf bin/AppLauncher
    rm -rf bin/AppLauncher.app
    rm -rf .build

# Watch and rebuild on file changes
watch:
    #!/usr/bin/env bash
    while inotifywait -e modify app/AppLauncher.swift 2>/dev/null || fswatch -1 app/AppLauncher.swift; do
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
    cp -R bin/AppLauncher.app release/
    @echo "Release built in release/"

# List recipes
list:
    @just --list