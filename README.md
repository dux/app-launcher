# Dux App Launcher

Spotlight-like app launcher for macOS.

## Install

```bash
make
```

## Usage

| Shortcut | Action |
|----------|--------|
| `Cmd+Space` or `Cmd+Shift+Space` | Toggle launcher |
| `Arrow keys` | Navigate list / Switch tabs |
| `Enter` | Launch selected |
| `Esc` | Hide window |

## Features

- Fast app search across `/Applications`, `/System/Applications`, `~/Applications`
- Recent apps shown when search is empty (last 5)
- Optional System Settings panes (Keyboard, Display, etc.)
- Optional System Commands (Sleep, Lock Screen, Restart, Shutdown)
- Custom shell scripts support
- Built-in script editor
- Semi-transparent window
- Menu bar icon (optional)

## Scripts

Create custom launchers in `~/.dux-app-launcher/*.sh` or use the Scripts tab.

## Config

`~/.dux-app-launcher/.options.yaml`

## Build

| Command | Description |
|---------|-------------|
| `make` | Build, install, run |
| `make build` | Build only |
| `make clean` | Remove artifacts |
| `make install` | Install to /Applications |
