import Cocoa
import SwiftUI
import Carbon.HIToolbox

@main
struct DuxAppLauncher: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Dux Launcher", id: "main") {
            ContentView()
                .frame(minWidth: 840, minHeight: 480)
        }
        .defaultSize(width: 840, height: 480)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Dux Launcher") {
                    showAbout()
                }
            }
        }
    }

    func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DuxAppLauncher"
        alert.informativeText = """
        Made by Dino Reic
        https://github.com/dux/dux-app-launcher

        Usage:
        • Cmd+Space / Cmd+Shift+Space: Toggle launcher
        • Type: Search apps/scripts
        • ←/→: Switch tabs (Search/Settings/Scripts)
        • ↑/↓: Navigate list
        • Enter: Launch selected
        • Esc: Hide window

        Features:
        • Fast app search across Applications folders
        • Recent apps history (last 5)
        • Optional System Settings panes
        • Optional System Commands (Sleep, Lock, Restart, Shutdown)
        • Custom shell scripts support
        • Semi-transparent window
        • Optional menu bar icon

        Sources:
        • /Applications
        • /System/Applications
        • ~/Applications
        • ~/.dux-app-launcher/*.sh
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?
    var hotKeyRef: EventHotKeyRef?
    var hotKeyRef2: EventHotKeyRef?
    var tabMonitor: Any?
    var isScriptsInputFocused = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let currentPID = ProcessInfo.processInfo.processIdentifier

        if let existingApp = runningApps.first(where: { $0.bundleIdentifier == "com.example.DuxAppLauncher" && $0.processIdentifier != currentPID }) {
            existingApp.activate()
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        // Setup menu bar icon based on saved preference
        let options = AppUtils.loadOptions()
        if options.showMenuBarIcon {
            setupStatusItem()
        }

        // Listen for menu bar icon toggle
        NotificationCenter.default.addObserver(forName: .toggleMenuBarIcon, object: nil, queue: .main) { [weak self] notification in
            if let show = notification.object as? Bool {
                if show {
                    self?.setupStatusItem()
                } else {
                    self?.removeStatusItem()
                }
            }
        }

        // Listen for scripts input focus changes
        NotificationCenter.default.addObserver(forName: .scriptsInputFocused, object: nil, queue: .main) { [weak self] _ in
            self?.isScriptsInputFocused = true
        }
        NotificationCenter.default.addObserver(forName: .scriptsInputUnfocused, object: nil, queue: .main) { [weak self] _ in
            self?.isScriptsInputFocused = false
        }

        // Register global hotkey: Cmd+Space
        registerHotKey()

        // Add local event monitor for arrow keys and Escape
        tabMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Left arrow = keyCode 123
            if event.keyCode == 123 {
                if !(self?.isScriptsInputFocused ?? false) {
                    NotificationCenter.default.post(name: .switchTabLeft, object: nil)
                    return nil // Consume the event
                }
            }
            // Right arrow = keyCode 124
            if event.keyCode == 124 {
                if !(self?.isScriptsInputFocused ?? false) {
                    NotificationCenter.default.post(name: .switchTabRight, object: nil)
                    return nil // Consume the event
                }
            }
            // Down arrow = keyCode 125
            if event.keyCode == 125 {
                if !(self?.isScriptsInputFocused ?? false) {
                    NotificationCenter.default.post(name: .searchNavigateDown, object: nil)
                    return nil // Consume the event
                }
            }
            // Up arrow = keyCode 126
            if event.keyCode == 126 {
                if !(self?.isScriptsInputFocused ?? false) {
                    NotificationCenter.default.post(name: .searchNavigateUp, object: nil)
                    return nil // Consume the event
                }
            }
            // Return key = keyCode 36
            if event.keyCode == 36 {
                if !(self?.isScriptsInputFocused ?? false) {
                    NotificationCenter.default.post(name: .searchLaunchSelected, object: nil)
                    return nil // Consume the event
                }
            }
            // Escape key = keyCode 53
            if event.keyCode == 53 {
                AppDelegate.hideWindow()
                return nil // Consume the event
            }
            return event
        }

        DispatchQueue.main.async {
            if let win = NSApplication.shared.windows.first {
                self.window = win

                // Set window transparency
                // win.alphaValue = 0.96
                // win.isOpaque = true

                // Hide traffic light buttons (close, minimize, zoom)
                // win.standardWindowButton(.closeButton)?.isHidden = true
                win.standardWindowButton(.miniaturizeButton)?.isHidden = true
                win.standardWindowButton(.zoomButton)?.isHidden = true

                win.center()
                win.orderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .focusSearchField, object: nil)
                }
            }
        }
    }

    func setupStatusItem() {
        if statusItem != nil { return } // Already set up
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = createMenuBarIcon()
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    func createMenuBarIcon() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        let font = NSFont.systemFont(ofSize: 6.5, weight: .bold)
        let color = NSColor.labelColor
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        // Draw 3x3 matrix: DUX / APP / LNC (uppercase, tight)
        let letters = [
            ["D", "U", "X"],
            ["A", "P", "P"],
            ["L", "N", "C"]
        ]

        let cellSize = size / 3
        for (row, rowLetters) in letters.enumerated() {
            for (col, letter) in rowLetters.enumerated() {
                let rect = NSRect(
                    x: CGFloat(col) * cellSize - 0.5,
                    y: size - CGFloat(row + 1) * cellSize,
                    width: cellSize,
                    height: cellSize
                )
                letter.draw(in: rect, withAttributes: attrs)
            }
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc func statusItemClicked() {
        AppDelegate.showWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .focusSearchField, object: nil)
            }
        }
        return true
    }

    func registerHotKey() {
        // Use Carbon API for reliable global hotkey (no Accessibility permission needed)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install handler (shared for both hotkeys)
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            AppDelegate.showWindow()
            return noErr
        }, 1, &eventType, nil, nil)

        // Register Cmd+Space
        let hotKeyID1 = EventHotKeyID(signature: OSType(0x444C4348), id: 1) // "DLCH"
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey),
            hotKeyID1,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        // Register Shift+Cmd+Space (fallback if Spotlight uses Cmd+Space)
        let hotKeyID2 = EventHotKeyID(signature: OSType(0x444C4348), id: 2)
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | shiftKey),
            hotKeyID2,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef2
        )
    }

    static func showWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .focusSearchField, object: nil)
        }
    }

    static func hideWindow() {
        NSApplication.shared.windows.first?.orderOut(nil)
        NSApp.hide(nil)
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var launchAtLogin = false
    @State private var includeSystemPreferences = false
    @State private var includeSystemCommands = false
    @State private var showMenuBarIcon = true

    var body: some View {
        TabView(selection: $selectedTab) {
            SearchPanel(
                onSettingsLoaded: { prefs in
                    includeSystemPreferences = prefs
                    showMenuBarIcon = AppUtils.loadOptions().showMenuBarIcon
                }
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(0)

            SettingsPanel(
                launchAtLogin: $launchAtLogin,
                includeSystemPreferences: $includeSystemPreferences,
                includeSystemCommands: $includeSystemCommands,
                showMenuBarIcon: $showMenuBarIcon,
                onSettingsChanged: {
                    NotificationCenter.default.post(name: .reloadApps, object: nil)
                }
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(1)

            ScriptsPanel(onScriptsChanged: {
                NotificationCenter.default.post(name: .reloadApps, object: nil)
            })
            .tabItem {
                Label("Scripts", systemImage: "terminal")
            }
            .tag(2)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    NotificationCenter.default.post(name: .reloadApps, object: nil)
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh app list")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .help("Quit Dux Launcher")
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .focusSearchField, object: nil)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchTabLeft)) { _ in
            selectedTab = selectedTab > 0 ? selectedTab - 1 : 2
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchTabRight)) { _ in
            selectedTab = (selectedTab + 1) % 3
        }
    }
}
