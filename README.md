# Dux Launcher

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
make              # Build and run (default)
make build        # Build only
make run          # Build and run
make install      # Install to /Applications
make clean        # Clean build artifacts
make help         # Show all commands
```

### Using Just (requires `brew install just`)
```bash
just              # Build and run (default)
just build        # Build only
just run          # Build and run
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
cp bin/DuxAppLauncher bin/DuxAppLauncher.app/Contents/MacOS/
cp app/Info.plist bin/DuxAppLauncher.app/Contents/
open bin/DuxAppLauncher.app
```

## Features

- Search apps from `/Applications`, `/System/Applications`, and `~/Applications`
- Search shell scripts in `~/.dux-launcher/`
- Autocomplete as you type
- Keyboard navigation (↑↓ to navigate, Enter to launch, Esc to hide)
- Global hotkey: **Cmd+Space** to toggle launcher
- Runs in background (use DuxAppLauncher → Quit to exit)
- Shows app icons
- Tracks launch history in `~/.dux-launcher/.history`
- Displays up to 5 recently used apps when launching

### Note
Cmd+Space conflicts with macOS Spotlight. You may need to disable Spotlight's Cmd+Space shortcut in System Settings → Keyboard → Keyboard Shortcuts → Spotlight to use this hotkey.