# Makefile for Dux App Launcher

.PHONY: default build run install install-local clean help release

# Default target - install to ~/Applications and run
default: install-local
	@pkill -x DuxAppLauncher || true
	@sleep 0.5
	@open ~/Applications/DuxAppLauncher.app

# Build the app (dev mode - to bin/)
build:
	@echo "Building Dux App Launcher..."
	@swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher
	@echo "✓ Build complete"

# Install to ~/Applications and run
install-local: build
	@echo "Installing to ~/Applications..."
	@mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
	@mkdir -p bin/DuxAppLauncher.app/Contents/Resources
	@cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/DuxAppLauncher.app/Contents/
	@cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
	@rm bin/DuxAppLauncher
	@rm -rf ~/Applications/DuxAppLauncher.app
	@cp -R bin/DuxAppLauncher.app ~/Applications/DuxAppLauncher.app
	@echo "✓ Installed to ~/Applications/DuxAppLauncher.app"
	@echo "Launching..."
	@open -g ~/Applications/DuxAppLauncher.app

# Run the app from ~/Applications
run:
	@echo "Launching ~/Applications/DuxAppLauncher.app..."
	@open -g ~/Applications/DuxAppLauncher.app

# Install to /Applications
install: build
	@echo "Installing to /Applications..."
	@mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
	@mkdir -p bin/DuxAppLauncher.app/Contents/Resources
	@cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
	@cp app/Info.plist bin/DuxAppLauncher.app/Contents/
	@cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
	@rm bin/DuxAppLauncher
	@rm -rf /Applications/DuxAppLauncher.app
	@cp -R bin/DuxAppLauncher.app /Applications/DuxAppLauncher.app
	@echo "✓ Installed to /Applications/DuxAppLauncher.app"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf bin/DuxAppLauncher
	@rm -rf bin/DuxAppLauncher.app
	@rm -rf ~/Applications/DuxAppLauncher.app
	@rm -rf .build
	@echo "✓ Clean complete"

# Show help
help:
	@echo "Dux App Launcher - Available targets:"
	@echo "  make           - Install to ~/Applications and run (default)"
	@echo "  make build     - Build only (to bin/)"
	@echo "  make run       - Run from ~/Applications"
	@echo "  make install-local - Install to ~/Applications"
	@echo "  make install   - Install to /Applications"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make help      - Show this help"

# Create release
release: install-local
	@echo "Creating release..."
	@mkdir -p release
	@cp -R ~/Applications/DuxAppLauncher.app release/
	@echo "✓ Release built in release/"