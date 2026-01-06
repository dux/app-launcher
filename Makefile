# Makefile for Dux App Launcher

.PHONY: default build run install install-local clean help release

APP_NAME = Dux App Launcher

# Default target - install to ~/Applications and run
default: install-local
	@pkill -x "Dux App Launcher" || true
	@sleep 0.5
	@open ~/Applications/"$(APP_NAME).app"

# Build the app (dev mode - to bin/)
build:
	@echo "Building $(APP_NAME)..."
	@swiftc -parse-as-library app/DuxAppLauncher.swift app/Shared.swift app/panel/SearchPanel.swift app/panel/SettingsPanel.swift app/panel/ScriptsPanel.swift -o "bin/$(APP_NAME)"
	@echo "✓ Build complete"

# Install to ~/Applications and run
install-local: build
	@echo "Installing to ~/Applications..."
	@mkdir -p "bin/$(APP_NAME).app/Contents/MacOS"
	@mkdir -p "bin/$(APP_NAME).app/Contents/Resources"
	@cp "bin/$(APP_NAME)" "bin/$(APP_NAME).app/Contents/MacOS/"
	@cp app/Info.plist "bin/$(APP_NAME).app/Contents/"
	@cp Icon.icns "bin/$(APP_NAME).app/Contents/Resources/AppIcon.icns"
	@rm "bin/$(APP_NAME)"
	@rm -rf ~/Applications/"$(APP_NAME).app"
	@cp -R "bin/$(APP_NAME).app" ~/Applications/"$(APP_NAME).app"
	@echo "✓ Installed to ~/Applications/$(APP_NAME).app"
	@echo "Launching..."
	@open -g ~/Applications/"$(APP_NAME).app"

# Run the app from ~/Applications
run:
	@echo "Launching ~/Applications/$(APP_NAME).app..."
	@open -g ~/Applications/"$(APP_NAME).app"

# Install to /Applications
install: build
	@echo "Installing to /Applications..."
	@mkdir -p "bin/$(APP_NAME).app/Contents/MacOS"
	@mkdir -p "bin/$(APP_NAME).app/Contents/Resources"
	@cp "bin/$(APP_NAME)" "bin/$(APP_NAME).app/Contents/MacOS/"
	@cp app/Info.plist "bin/$(APP_NAME).app/Contents/"
	@cp Icon.icns "bin/$(APP_NAME).app/Contents/Resources/AppIcon.icns"
	@rm "bin/$(APP_NAME)"
	@rm -rf /Applications/"$(APP_NAME).app"
	@cp -R "bin/$(APP_NAME).app" /Applications/"$(APP_NAME).app"
	@echo "✓ Installed to /Applications/$(APP_NAME).app"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf "bin/$(APP_NAME)"
	@rm -rf "bin/$(APP_NAME).app"
	@rm -rf ~/Applications/"$(APP_NAME).app"
	@rm -rf .build
	@echo "✓ Clean complete"

# Show help
help:
	@echo "$(APP_NAME) - Available targets:"
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
	@cp -R ~/Applications/"$(APP_NAME).app" release/
	@echo "✓ Release built in release/"
