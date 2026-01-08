# Dux App Launcher

Spotlight-like app launcher for macOS.

## Install

```bash
make
```

or [Install binary](https://github.com/dux/app-launcher/releases) from GitHub releases

## Usage

| Shortcut | Action |
|----------|--------|
| `Cmd+Space` or `Cmd+Shift+Space` | Toggle launcher |
| `Arrow keys` | Navigate list / Switch tabs |
| `Enter` | Launch selected |
| `Esc` | Hide window |

## Features

### Search & Ranking
- Instant search across `/Applications`, `/System/Applications`, and `~/Applications`, plus optional System Settings panes and custom scripts.
- Smart ranking that prioritizes items whose names start with your query, then falls back to launch frequency (tracked via `history.txt`) and recency, so the things you use most bubble to the top.
- Empty queries show the last 5 launches pulled from a rolling history of the most recent 50 items.

### Keyboard & Windowing
- Global toggles on `Cmd+Space` and `Shift+Cmd+Space`, with arrow-key navigation, Return-to-launch, and Escape-to-hide.
- Tabbed interface (Search / Settings / Scripts) with left/right arrow switching and automatic search-field focus.
- Optional menu bar icon for quick access, plus a minimalist, semi-transparent window that stays centered and hides chrome.

### System Integration
- Toggle inclusion of macOS System Settings panes and curated system commands (Sleep, Lock Screen, Restart, Shutdown).
- One-click options for showing a menu bar icon and launching at login (via `SMAppService`).
- Context menus on search results to copy paths, open apps, reveal packages, or jump straight to Finder.

### Settings Panel
- Launch at login toggle backed by `SMAppService.mainApp`.
- Menu bar icon switch that live-toggles the status-item.
- Include System Settings panes & System Commands switches (trigger immediate reloads).
- Shortcut cheatsheet for `Cmd+Space` / `Shift+Cmd+Space` and quick link to disable Spotlight.
- “Open app folder” button that reveals `~/.dux-app-launcher` in Finder.

### Custom Scripts
- Built-in script editor with name + command fields, run/save/delete actions, and automatic executable permissions.
- Scripts live in `~/.dux-app-launcher/*.sh` and are searchable alongside apps.
- Programmatic refresh notifications keep search results in sync whenever scripts change.

### Configuration & Persistence
- All preferences live in `~/.dux-app-launcher/options.yaml`; launch history is stored in `~/.dux-app-launcher/history.txt`.
- History is refreshed after every launch so rankings immediately reflect your usage.
- Settings panel surfaces launch-at-login status, menu bar toggle, system pane/command options, shortcut reminders, and quick access to the app support folder.

## Scripts

Create custom launchers in `~/.dux-app-launcher/*.sh` or use the Scripts tab.

## Config

`~/.dux-app-launcher/options.yaml`

## Build

| Command | Description |
|---------|-------------|
| `make` | Build, install, run |
| `make build` | Build only |
| `make clean` | Remove artifacts |
| `make install` | Install to /Applications |
