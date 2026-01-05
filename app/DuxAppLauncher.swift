import Cocoa
import SwiftUI
import ServiceManagement
import Carbon.HIToolbox

extension Notification.Name {
    static let focusSearchField = Notification.Name("focusSearchField")
}

@main
struct DuxAppLauncher: App {
    static let MAIN_FOLDER = (NSHomeDirectory() as NSString).appendingPathComponent(".dux-app-launcher")
    static let HISTORY_FILE = (MAIN_FOLDER as NSString).appendingPathComponent(".history")
    static let OPTIONS_FILE = (MAIN_FOLDER as NSString).appendingPathComponent(".options.yaml")
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("Dux Launcher", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
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
        • Cmd+Shift+Space: Toggle launcher
        • Type: Search apps/scripts
        • ↑/↓: Navigate
        • Enter: Launch
        • Esc: Hide window
        
        Sources:
        • /Applications
        • /System/Applications
        • ~/Applications
        • ~/.dux-launcher/*.sh
        
        App runs in background. Quit via DuxAppLauncher menu.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var hotKeyRef: EventHotKeyRef?

    func applicationWillFinishLaunching(_ notification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let currentPID = ProcessInfo.processInfo.processIdentifier

        if runningApps.contains(where: { $0.bundleIdentifier == "com.example.DuxAppLauncher" && $0.processIdentifier != currentPID }) {
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.prohibited)
        
        // Register global hotkey: Cmd+Shift+Space
        registerHotKey()

        DispatchQueue.main.async {
            if let win = NSApplication.shared.windows.first {
                self.window = win
                win.center()
                win.orderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .focusSearchField, object: nil)
                }
            }
        }
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
        // Cmd+Shift+Space hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x4458_4C43), id: 1) // "DXLC"
        var hotKeyRef: EventHotKeyRef?
        
        // kVK_Space = 49, cmdKey = 256 (0x100), shiftKey = 512 (0x200)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            self.hotKeyRef = hotKeyRef
        }
        
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    AppDelegate.toggleWindow()
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
    
    static func toggleWindow() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .focusSearchField, object: nil)
            }
        }
    }
}

struct AppInfo {
    let name: String
    let path: String
    let icon: NSImage?
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var history: [AppInfo] = []
    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool
    @State private var appCount = 0
    @State private var scriptCount = 0
    @State private var launchAtLogin = false
    @State private var includeSystemPreferences = false
    
    let fileManager = FileManager.default
    
    var displayApps: [AppInfo] {
        if searchText.isEmpty && !history.isEmpty {
            return Array(history.prefix(5))
        }
        if searchText.isEmpty {
            return Array(apps.prefix(200))
        }
        return apps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText)
        }.prefix(200).map { $0 }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 0) {
                TextField("Search \(appCount) apps & \(scriptCount) scripts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .font(.system(size: 14))
                    .background(Color(nsColor: .textBackgroundColor))
                    .focused($isFocused)
                    .onAppear {
                        createMainFolder()
                        let prefs = loadOptions()
                        loadApps(prefs)
                        loadHistory()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        selectedIndex = 0
                        if newValue.isEmpty {
                            loadHistory()
                        }
                    }
                
                if displayApps.isEmpty {
                    Text("No apps found")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(0..<displayApps.count, id: \.self) { index in
                        HStack {
                            if let icon = displayApps[index].icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 48, height: 48)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 48, height: 48)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayApps[index].name)
                                    .font(.system(size: 13))
                                Text(displayApps[index].path.hasPrefix(NSHomeDirectory()) ? displayApps[index].path.replacingOccurrences(of: NSHomeDirectory(), with: "~") : displayApps[index].path)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 2)
                        .padding(.leading, 3)
                        .listRowSeparator(.hidden)
                        .background(
                            Group {
                                if index == selectedIndex {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor.opacity(0.2))
                                }
                            }
                        )
                        .onTapGesture {
                            selectedIndex = index
                        }
                        .onAppear {
                            if index == 0 {
                                selectedIndex = 0
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(0)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 8)
                
                HStack {
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: launchAtLogin) { _, newValue in
                            toggleLaunchAtLogin(newValue)
                        }
                    Text("Launch at login")
                }
                
                HStack {
                    Toggle("", isOn: $includeSystemPreferences)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: includeSystemPreferences) { _, newValue in
                            saveOptions()
                            loadApps()
                        }
                    Text("Include System Settings panes")
                }
                
                Spacer()
                
                Text("Last modified: \(getAppModifiedTime())")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding()
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(1)
        }
        .onAppear {
            checkLoginStatus()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
        .onKeyPress(.downArrow) {
            if selectedTab == 0 && selectedIndex < displayApps.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if selectedTab == 0 && selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            if selectedTab == 0 && selectedIndex < displayApps.count {
                launchApp(displayApps[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.escape) {
            NSApplication.shared.windows.first?.orderOut(nil)
            return .handled
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
            isFocused = true
        }
    }
    
    func checkLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    func toggleLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
                launchAtLogin = !enabled
            }
        }
    }
    
    func createMainFolder() {
        if !fileManager.fileExists(atPath: DuxAppLauncher.MAIN_FOLDER) {
            try? fileManager.createDirectory(atPath: DuxAppLauncher.MAIN_FOLDER, withIntermediateDirectories: true)
        }
    }
    
    func loadOptions() -> Bool {
        guard fileManager.fileExists(atPath: DuxAppLauncher.OPTIONS_FILE),
              let data = fileManager.contents(atPath: DuxAppLauncher.OPTIONS_FILE),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }
        
        var result = false
        for line in content.components(separatedBy: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                if parts[0] == "include_system_preferences" {
                    result = parts[1] == "true"
                    includeSystemPreferences = result
                }
            }
        }
        return result
    }
    
    func saveOptions() {
        let content = "include_system_preferences: \(includeSystemPreferences)"
        try? content.write(toFile: DuxAppLauncher.OPTIONS_FILE, atomically: true, encoding: .utf8)
    }
    
    func loadApps(_ includePrefs: Bool? = nil) {
        var allApps: [AppInfo] = []
        var appCountTemp = 0
        var scriptCountTemp = 0
        
        let shouldIncludePrefs = includePrefs ?? includeSystemPreferences
        
        let appPaths = [
            "/Applications",
            "/System/Applications",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
        ]
        
        for appPath in appPaths {
            if let contents = try? fileManager.contentsOfDirectory(atPath: appPath) {
                let folderApps = contents.compactMap { fileName -> AppInfo? in
                    if fileName.hasSuffix(".app") {
                        appCountTemp += 1
                        let fullPath = "\(appPath)/\(fileName)"
                        if let appName = fileName.dropLast(4).description as String? {
                            let icon = getAppIcon(for: fullPath)
                            return AppInfo(name: appName, path: fullPath, icon: icon)
                        }
                    }
                    return nil
                }
                allApps.append(contentsOf: folderApps)
            }
        }
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: DuxAppLauncher.MAIN_FOLDER) {
            let shellApps = contents.compactMap { fileName -> AppInfo? in
                if fileName.hasSuffix(".sh") {
                    scriptCountTemp += 1
                    let fullPath = "\(DuxAppLauncher.MAIN_FOLDER)/\(fileName)"
                    let appName = fileName.replacingOccurrences(of: ".sh", with: "")
                    return AppInfo(name: appName, path: fullPath, icon: nil)
                }
                return nil
            }
            allApps.append(contentsOf: shellApps)
        }
        
        // Add System Preferences panes if enabled
        if shouldIncludePrefs {
            let prefPanesPath = "/System/Library/PreferencePanes"
            if let contents = try? fileManager.contentsOfDirectory(atPath: prefPanesPath) {
                let prefPanes = contents.compactMap { fileName -> AppInfo? in
                    if fileName.hasSuffix(".prefPane") {
                        appCountTemp += 1
                        let fullPath = "\(prefPanesPath)/\(fileName)"
                        let appName = fileName.replacingOccurrences(of: ".prefPane", with: "")
                        let icon = getAppIcon(for: fullPath)
                        return AppInfo(name: appName, path: fullPath, icon: icon)
                    }
                    return nil
                }
                allApps.append(contentsOf: prefPanes)
            }
        }
        
        apps = allApps.sorted { $0.name < $1.name }
        appCount = appCountTemp
        scriptCount = scriptCountTemp
    }
    
    func loadHistory() {
        guard fileManager.fileExists(atPath: DuxAppLauncher.HISTORY_FILE),
              let data = fileManager.contents(atPath: DuxAppLauncher.HISTORY_FILE),
              let historyPaths = String(data: data, encoding: .utf8)?.components(separatedBy: "\n").filter({ !$0.isEmpty }) else {
            return
        }
        
        history = historyPaths.compactMap { path in
            let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            let icon = getAppIcon(for: path)
            return AppInfo(name: name, path: path, icon: icon)
        }
    }
    
    func saveHistory(_ app: AppInfo) {
        var currentHistory = history.map { $0.path }.filter { $0 != app.path }
        currentHistory.insert(app.path, at: 0)
        currentHistory = Array(currentHistory.prefix(4))
        
        let historyString = currentHistory.joined(separator: "\n")
        try? historyString.write(toFile: DuxAppLauncher.HISTORY_FILE, atomically: true, encoding: .utf8)
    }
    
    func getAppIcon(for path: String) -> NSImage? {
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    func getAppModifiedTime() -> String {
        let appPath = Bundle.main.bundlePath
        guard let attrs = try? fileManager.attributesOfItem(atPath: appPath),
              let modDate = attrs[.modificationDate] as? Date else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modDate)
    }
    
    func launchApp(_ app: AppInfo) {
        saveHistory(app)
        
        if app.path.hasSuffix(".sh") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [app.path]
            try? process.run()
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        }
        
        NSApplication.shared.windows.first?.orderOut(nil)
    }
}
