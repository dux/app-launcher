# Makefile for Dux App Launcher

.PHONY: default build run install install-local clean help release gh-bin

APP_NAME = Dux App Launcher
GH_RELEASE_TAG ?= dux-launcher-latest
GH_RELEASE_TITLE ?= $(APP_NAME) Latest Build

# Default target - install to ~/Applications and run
default: install-local
	@pkill -x "Dux App Launcher" || true
	@sleep 0.5
	@open ~/Applications/"$(APP_NAME).app"

# Build the app (dev mode - to bin/)
build:
	@echo "Building $(APP_NAME)..."
	@mkdir -p bin
	@swiftc -parse-as-library app/DuxAppLauncher.swift app/Shared.swift app/panel/SearchPanel.swift app/panel/SettingsPanel.swift app/panel/ScriptsPanel.swift -o "bin/$(APP_NAME)"
	@echo "✓ Build complete"
	@rm -rf "bin/$(APP_NAME).app"
	@mkdir -p "bin/$(APP_NAME).app/Contents/MacOS"
	@mkdir -p "bin/$(APP_NAME).app/Contents/Resources"
	@cp "bin/$(APP_NAME)" "bin/$(APP_NAME).app/Contents/MacOS/"
	@cp app/Info.plist "bin/$(APP_NAME).app/Contents/"
	@cp Icon.icns "bin/$(APP_NAME).app/Contents/Resources/AppIcon.icns"
	@rm "bin/$(APP_NAME)"
	@echo "✓ App bundle ready at bin/$(APP_NAME).app"
	@rm -f "bin/$(APP_NAME).zip"
	@ditto -c -k --sequesterRsrc --keepParent "bin/$(APP_NAME).app" "bin/$(APP_NAME).zip"
	@echo "✓ Zip archive ready at bin/$(APP_NAME).zip"

# Install to ~/Applications and run
install-local: build
	@echo "Installing to ~/Applications..."
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
	@rm -rf /Applications/"$(APP_NAME).app"
	@cp -R "bin/$(APP_NAME).app" /Applications/"$(APP_NAME).app"
	@echo "✓ Installed to /Applications/$(APP_NAME).app"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf "bin/$(APP_NAME)"
	@rm -rf "bin/$(APP_NAME).app"
	@rm -rf "bin/$(APP_NAME).zip"
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
	@echo "  make release   - Build zip into release/"
	@echo "  make gh-bin    - Publish zip to GitHub release"
	@echo "  make help      - Show this help"

# Create release zip
release: build
	@echo "Creating release zip..."
	@mkdir -p release
	@rm -f release/"$(APP_NAME).zip"
	@cp -R "bin/$(APP_NAME).app" release/
	@ditto -c -k --sequesterRsrc --keepParent release/"$(APP_NAME).app" release/"$(APP_NAME).zip"
	@rm -rf release/"$(APP_NAME).app"
	@echo "✓ Release zip built at release/$(APP_NAME).zip"

# Upload latest binary to GitHub release
gh-bin: release
	@echo "Publishing $(APP_NAME) to GitHub release $(GH_RELEASE_TAG)..."
	@gh release view $(GH_RELEASE_TAG) >/dev/null 2>&1 && gh release delete $(GH_RELEASE_TAG) -y || true
	@gh release create $(GH_RELEASE_TAG) release/"$(APP_NAME).zip" -t "$(GH_RELEASE_TITLE)" -n "Latest automated build" --latest
	@echo "✓ GitHub release $(GH_RELEASE_TAG) updated"
