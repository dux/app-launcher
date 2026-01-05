# Justfile for Dux App Launcher

# Default target - install to ~/Applications and run
default: install-local

# Build the app (dev mode - to bin/)
build:
    swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher

# Install to ~/Applications and run
install-local: build
    mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
    mkdir -p bin/DuxAppLauncher.app/Contents/Resources
    cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/DuxAppLauncher.app/Contents/
    cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
    rm bin/DuxAppLauncher
    rm -rf ~/Applications/DuxAppLauncher.app
    cp -R bin/DuxAppLauncher.app ~/Applications/DuxAppLauncher.app
    echo "✓ Installed to ~/Applications/DuxAppLauncher.app"
    echo "Launching..."
    open -g ~/Applications/DuxAppLauncher.app

# Run the app from ~/Applications
run:
    echo "Launching ~/Applications/DuxAppLauncher.app..."
    open -g ~/Applications/DuxAppLauncher.app

# Install to /Applications
install: build
    mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
    mkdir -p bin/DuxAppLauncher.app/Contents/Resources
    cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
    cp app/Info.plist bin/DuxAppLauncher.app/Contents/
    cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
    rm bin/DuxAppLauncher
    rm -rf /Applications/DuxAppLauncher.app
    cp -R bin/DuxAppLauncher.app /Applications/DuxAppLauncher.app

# Clean build artifacts
clean:
    rm -rf bin/DuxAppLauncher
    rm -rf bin/DuxAppLauncher.app
    rm -rf ~/Applications/DuxAppLauncher.app
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
release: install-local
    mkdir -p release
    cp -R ~/Applications/DuxAppLauncher.app release/
    echo "✓ Release built in release/"

# List recipes
list:
    @just --list