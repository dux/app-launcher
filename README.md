# Dux Launcher

A simple Mac app launcher with Spotlight-like interface and history tracking.

## Project Structure

```
.
├── app/
│   └── AppLauncher.swift    # Source code
├── bin/
│   ├── AppLauncher          # Compiled binary
│   └── AppLauncher.app      # App bundle
├── .gitignore
├── README.md
└── run.sh                   # Build and run script
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
swiftc -parse-as-library app/AppLauncher.swift -o bin/AppLauncher
mkdir -p bin/AppLauncher.app/Contents/MacOS
cp bin/AppLauncher bin/AppLauncher.app/Contents/MacOS/
cp app/Info.plist bin/AppLauncher.app/Contents/
open bin/AppLauncher.app
```

## Features

- Search apps from `/Applications` folder
- Autocomplete as you type
- Keyboard navigation (↑↓ to navigate, Enter to launch, Esc to quit)
- Shows app icons
- Tracks launch history in `~/.dux-launcher/.history`
- Displays up to 5 recently used apps when launching