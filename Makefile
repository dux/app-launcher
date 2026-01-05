# Makefile for Dux Launcher

.PHONY: default build run install clean help release

# Default target - build and run
default: run

# Build the app
build:
	@echo "Building Dux Launcher..."
	@swiftc -parse-as-library app/AppLauncher.swift -o bin/AppLauncher
	@echo "✓ Build complete"

# Run the app (builds first)
run: build
	@echo "Creating app bundle..."
	@mkdir -p bin/AppLauncher.app/Contents/MacOS
	@cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/AppLauncher.app/Contents/
	@echo "Launching..."
	@open bin/AppLauncher.app

# Install to /Applications
install: build
	@echo "Installing to /Applications..."
	@mkdir -p bin/AppLauncher.app/Contents/MacOS
	@cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/AppLauncher.app/Contents/
	@rm -rf /Applications/Dux\ Launcher.app
	@cp -R bin/AppLauncher.app "/Applications/Dux Launcher.app"
	@echo "✓ Installed to /Applications/Dux Launcher.app"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf bin/AppLauncher
	@rm -rf bin/AppLauncher.app
	@rm -rf .build
	@echo "✓ Clean complete"

# Show help
help:
	@echo "Dux Launcher - Available targets:"
	@echo "  make         - Build and run (default)"
	@echo "  make build   - Build only"
	@echo "  make run     - Build and run"
	@echo "  make install - Install to /Applications"
	@echo "  make clean   - Clean build artifacts"
	@echo "  make help    - Show this help"

# Create release
release: clean build
	@echo "Creating release..."
	@mkdir -p release
	@mkdir -p bin/AppLauncher.app/Contents/MacOS
	@cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/AppLauncher.app/Contents/
	@cp -R bin/AppLauncher.app release/
	@echo "✓ Release built in release/"