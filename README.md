# Dux App Launcher

A simple Mac app launcher with Spotlight-like interface and history tracking.

## Project Structure

```
.
├── app/
│   └── DuxAppLauncher.swift    # Source code
├── bin/
│   ├── DuxAppLauncher          # Compiled binary
│   └── DuxAppLauncher.app      # App bundle
├── .gitignore
├── README.md
└── run.sh                      # Build and run script
```

## Building and Running

### Using Make (Recommended)
```bash
make              # Install to ~/Applications and run (default)
make build        # Build only (to bin/)
make run          # Run from ~/Applications
make install-local # Install to ~/Applications
make install      # Install to /Applications
make clean        # Clean build artifacts
make help         # Show all commands
```

### Using Just (requires `brew install just`)
```bash
just              # Install to ~/Applications and run (default)
just build        # Build only (to bin/)
just run          # Run from ~/Applications
just install-local # Install to ~/Applications
just install      # Install to /Applications
just clean        # Clean build artifacts
just help         # Show all commands
```

### Using run.sh (Legacy)
```bash
./run.sh
```

### Manual build
```bash
swiftc -parse-as-library app/DuxAppLauncher.swift -o bin/DuxAppLauncher
mkdir -p bin/DuxAppLauncher.app/Contents/MacOS
mkdir -p bin/DuxAppLauncher.app/Contents/Resources
cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
cp app/Info.plist bin/DuxAppLauncher.app/Contents/
cp Icon.icns bin/DuxAppLauncher.app/Contents/Resources/AppIcon.icns
rm bin/DuxAppLauncher
cp -R bin/DuxAppLauncher.app ~/Applications/DuxAppLauncher.app
```

## Features

- Search apps from `/Applications`, `/System/Applications`, and `~/Applications`
- Search shell scripts in `~/.dux-app-launcher/`
- Autocomplete as you type
- Keyboard navigation (↑↓ to navigate, Enter to launch, Esc to hide)
- Global hotkey: **Cmd+Shift+Space** to toggle launcher
- Runs in background (use DuxAppLauncher → Quit to exit)
- Shows app icons
- Tracks launch history in `~/.dux-app-launcher/.history`
- Displays up to 5 recently used apps when launching

### Note
Cmd+Shift+Space may conflict with other apps. If needed, you can modify the hotkey in `app/DuxAppLauncher.swift`.