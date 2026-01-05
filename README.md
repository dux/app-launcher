# Dux App Launcher

Spotlight-like app launcher for macOS.

## Install

```bash
make
```

## Usage

**Cmd+Shift+Space** - toggle launcher

- Type to search apps
- Arrow keys to navigate
- Enter to launch
- Esc to hide

## Features

- Searches `/Applications`, `/System/Applications`, `~/Applications`
- Recent apps shown on empty search
- Optional System Settings panes search
- Custom shell scripts in `~/.dux-app-launcher/*.sh`
- Built-in script editor (Scripts tab)

## Config

Settings stored in `~/.dux-app-launcher/.options.yaml`

## Build

```bash
make              # build, install, run
make build        # build only
make clean        # remove build artifacts
```
