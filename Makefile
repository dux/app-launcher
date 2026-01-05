# Makefile for Dux Launcher

.PHONY: default build run install clean help release

# Default target - build and run
default: run

# Build the app
build:
	@echo "Building Dux Launcher..."
	@swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher
	@echo "✓ Build complete"

# Run the app (builds first)
run: build
	@echo "Creating app bundle..."
	@mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
	@mkdir -p bin/DuxAppLauncher.app/Contents/Resources
	@cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/DuxAppLauncher.app/Contents/
	@cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
	@rm bin/DuxAppLauncher
	@echo "Launching..."
	@open -g bin/DuxAppLauncher.app

# Install to /Applications
install: build
	@echo "Installing to /Applications..."
	@mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
	@mkdir -p bin/DuxAppLauncher.app/Contents/Resources
	@cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/DuxAppLauncher.app/Contents/
	@cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
	@rm bin/DuxAppLauncher
	@rm -rf /Applications/Dux\ Launcher.app
	@cp -R bin/DuxAppLauncher.app "/Applications/Dux Launcher.app"
	@echo "✓ Installed to /Applications/Dux Launcher.app"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf bin/DuxAppLauncher
	@rm -rf bin/DuxAppLauncher.app
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
	@mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
	@mkdir -p bin/DuxAppLauncher.app/Contents/Resources
	@cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/DuxAppLauncher.app/Contents/
	@cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
	@rm bin/DuxAppLauncher
	@cp -R bin/DuxAppLauncher.app release/
	@echo "✓ Release built in release/"