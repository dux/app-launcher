import Cocoa
import SwiftUI

// MARK: - Notifications
extension Notification.Name {
    static let focusSearchField = Notification.Name("focusSearchField")
    static let reloadApps = Notification.Name("reloadApps")
    static let switchTabLeft = Notification.Name("switchTabLeft")
    static let switchTabRight = Notification.Name("switchTabRight")
    static let toggleMenuBarIcon = Notification.Name("toggleMenuBarIcon")
    static let searchNavigateDown = Notification.Name("searchNavigateDown")
    static let searchNavigateUp = Notification.Name("searchNavigateUp")
    static let searchLaunchSelected = Notification.Name("searchLaunchSelected")
    static let scriptsInputFocused = Notification.Name("scriptsInputFocused")
    static let scriptsInputUnfocused = Notification.Name("scriptsInputUnfocused")
}

// MARK: - Constants
struct AppConstants {
    static let MAIN_FOLDER = (NSHomeDirectory() as NSString).appendingPathComponent(".dux-app-launcher")
    static let HISTORY_FILE = (MAIN_FOLDER as NSString).appendingPathComponent("history.txt")
    static let OPTIONS_FILE = (MAIN_FOLDER as NSString).appendingPathComponent("options.yaml")
}

// MARK: - Models
struct AppInfo {
    let name: String
    let path: String
    let icon: NSImage?
}

struct AppOptions {
    var includeSystemPreferences: Bool
    var showMenuBarIcon: Bool
    var includeSystemCommands: Bool
}

// MARK: - Shared Views
struct AppItemRow: View {
    let app: AppInfo
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 56, height: 56)
            } else {
                Image(systemName: "terminal")
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 18))
                Text(app.path.hasPrefix(NSHomeDirectory()) ? app.path.replacingOccurrences(of: NSHomeDirectory(), with: "~") : app.path)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.leading, 3)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.2))
                }
            }
        )
        .contextMenu {
            Button("Copy Path") {
                AppUtils.copyToClipboard(app.path)
            }
            Button("Open") {
                AppUtils.openInFinder(app.path)
            }
            Button(app.path.hasSuffix(".app") ? "Open app package" : "Open Folder") {
                AppUtils.openFolder(app.path)
            }
        }
    }
}

// MARK: - Shared Utilities
struct AppUtils {
    static let fileManager = FileManager.default
    
    static func createMainFolder() {
        if !fileManager.fileExists(atPath: AppConstants.MAIN_FOLDER) {
            try? fileManager.createDirectory(atPath: AppConstants.MAIN_FOLDER, withIntermediateDirectories: true)
        }
    }
    
    static func getAppIcon(for path: String) -> NSImage? {
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    static func loadOptions() -> AppOptions {
        guard fileManager.fileExists(atPath: AppConstants.OPTIONS_FILE),
              let data = fileManager.contents(atPath: AppConstants.OPTIONS_FILE),
              let content = String(data: data, encoding: .utf8) else {
            return AppOptions(includeSystemPreferences: false, showMenuBarIcon: true, includeSystemCommands: false)
        }
        
        var options = AppOptions(includeSystemPreferences: false, showMenuBarIcon: true, includeSystemCommands: false)
        for line in content.components(separatedBy: "\n") {
            let parts = line.split(separator: ":", maxSplits:1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                if parts[0] == "include_system_preferences" {
                    options.includeSystemPreferences = parts[1] == "true"
                }
                if parts[0] == "show_menu_bar_icon" {
                    options.showMenuBarIcon = parts[1] == "true"
                }
                if parts[0] == "include_system_commands" {
                    options.includeSystemCommands = parts[1] == "true"
                }
            }
        }
        return options
    }
    
    static func saveOptions(_ options: AppOptions) {
        let content = """
        include_system_preferences: \(options.includeSystemPreferences)
        show_menu_bar_icon: \(options.showMenuBarIcon)
        include_system_commands: \(options.includeSystemCommands)
        """
        try? content.write(toFile: AppConstants.OPTIONS_FILE, atomically: true, encoding: .utf8)
    }
    
    static func loadApps(includeSystemPreferences: Bool, includeSystemCommands: Bool) -> (apps: [AppInfo], appCount: Int, scriptCount: Int) {
        var allApps: [AppInfo] = []
        var appCountTemp = 0
        var scriptCountTemp = 0
        
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
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: AppConstants.MAIN_FOLDER) {
            let shellApps = contents.compactMap { fileName -> AppInfo? in
                if fileName.hasSuffix(".sh") {
                    scriptCountTemp += 1
                    let fullPath = "\(AppConstants.MAIN_FOLDER)/\(fileName)"
                    let appName = fileName.replacingOccurrences(of: ".sh", with: "")
                    return AppInfo(name: appName, path: fullPath, icon: nil)
                }
                return nil
            }
            allApps.append(contentsOf: shellApps)
        }
        
        // Add System Preferences panes if enabled
        if includeSystemPreferences {
            let prefPanesPath = "/System/Library/PreferencePanes"
            if let contents = try? fileManager.contentsOfDirectory(atPath: prefPanesPath) {
                let prefPanes = contents.compactMap { fileName -> AppInfo? in
                    if fileName.hasSuffix(".prefPane") {
                        appCountTemp += 1
                        let fullPath = "\(prefPanesPath)/\(fileName)"
                        let appName = fileName.replacingOccurrences(of: ".prefPane", with: "")
                        let icon = getPrefPaneIcon(for: appName)
                        return AppInfo(name: appName, path: fullPath, icon: icon)
                    }
                    return nil
                }
                allApps.append(contentsOf: prefPanes)
            }
        }
        
        // Add System Commands if enabled
        if includeSystemCommands {
            allApps.append(contentsOf: getSystemCommands())
        }
        
        return (allApps.sorted { $0.name < $1.name }, appCountTemp, scriptCountTemp)
    }
    
    static func getPrefPaneIcon(for name: String) -> NSImage? {
        // Map preference pane names to SF Symbols
        let iconMap: [String: String] = [
            "Accounts": "person.crop.circle",
            "Appearance": "paintbrush",
            "AppleIDPrefPane": "apple.logo",
            "Battery": "battery.100",
            "Bluetooth": "bluetooth",
            "ClassKitPreferencePane": "graduationcap",
            "ClassroomSettings": "person.3",
            "DateAndTime": "calendar.badge.clock",
            "DesktopScreenEffectsPref": "photo.on.rectangle",
            "DigiHubDiscs": "opticaldisc",
            "Displays": "display",
            "Dock": "dock.rectangle",
            "EnergySaver": "bolt.circle",
            "EnergySaverPref": "bolt.circle",
            "Expose": "rectangle.3.group",
            "Extensions": "puzzlepiece.extension",
            "FamilySharingPrefPane": "person.2",
            "InternetAccounts": "globe",
            "Keyboard": "keyboard",
            "Localization": "globe",
            "Mouse": "magicmouse",
            "Network": "wifi",
            "Notifications": "bell",
            "Passwords": "key",
            "PrintAndFax": "printer",
            "PrintAndScan": "printer",
            "Profiles": "person.text.rectangle",
            "ScreenTime": "hourglass",
            "Security": "lock.shield",
            "SharingPref": "shareplay",
            "SoftwareUpdate": "arrow.triangle.2.circlepath",
            "Sound": "speaker.wave.3",
            "Speech": "waveform",
            "Spotlight": "magnifyingglass",
            "StartupDisk": "internaldrive",
            "TimeMachine": "clock.arrow.circlepath",
            "TouchID": "touchid",
            "Trackpad": "trackpad",
            "UniversalAccessPref": "accessibility",
            "Wallet": "wallet.pass"
        ]
        
        let symbolName = iconMap[name] ?? "gearshape"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: name) {
            image.size = NSSize(width: 32, height: 32)
            // Create a colored version
            let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            return image.withSymbolConfiguration(config)
        }
        return nil
    }
    
    private static func readHistoryPaths() -> [String] {
        guard fileManager.fileExists(atPath: AppConstants.HISTORY_FILE),
              let data = fileManager.contents(atPath: AppConstants.HISTORY_FILE),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }
        let paths = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        return Array(paths.prefix(50))
    }
    
    private static func appInfo(for path: String, systemCommands: [AppInfo]) -> AppInfo? {
        if path.hasPrefix("system:"),
           let command = systemCommands.first(where: { $0.path == path }) {
            return command
        }
        
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }
        
        var name = (path as NSString).lastPathComponent
        let icon: NSImage?
        
        if path.hasSuffix(".prefPane") {
            name = name.replacingOccurrences(of: ".prefPane", with: "")
            icon = getPrefPaneIcon(for: name)
        } else if path.hasSuffix(".sh") {
            name = name.replacingOccurrences(of: ".sh", with: "")
            icon = nil
        } else {
            name = name.replacingOccurrences(of: ".app", with: "")
            icon = getAppIcon(for: path)
        }
        
        return AppInfo(name: name, path: path, icon: icon)
    }
    
    static func loadHistory() -> [AppInfo] {
        let historyPaths = readHistoryPaths()
        guard !historyPaths.isEmpty else {
            return []
        }
        
        let systemCommands = getSystemCommands()
        var seen = Set<String>()
        var recents: [AppInfo] = []
        
        for path in historyPaths {
            if seen.contains(path) {
                continue
            }
            seen.insert(path)
            if let info = appInfo(for: path, systemCommands: systemCommands) {
                recents.append(info)
            }
            if recents.count == 5 {
                break
            }
        }
        
        return recents
    }
    
    static func loadHistoryMetadata() -> (order: [String: Int], frequencies: [String: Int]) {
        let historyPaths = readHistoryPaths()
        var order: [String: Int] = [:]
        var frequencies: [String: Int] = [:]
        
        for (index, path) in historyPaths.enumerated() {
            frequencies[path, default: 0] += 1
            if order[path] == nil {
                order[path] = index
            }
        }
        
        return (order, frequencies)
    }
    
    static func saveHistory(_ app: AppInfo) {
        createMainFolder()
        var newHistory = readHistoryPaths()
        newHistory.insert(app.path, at: 0)
        if newHistory.count > 50 {
            newHistory = Array(newHistory.prefix(50))
        }
        
        let historyString = newHistory.joined(separator: "\n")
        try? historyString.write(toFile: AppConstants.HISTORY_FILE, atomically: true, encoding: .utf8)
    }
    
    static func launchApp(_ app: AppInfo, onComplete: @escaping () -> Void) {
        saveHistory(app)
        
        let hideWork = {
            NSApplication.shared.windows.first?.orderOut(nil)
            NSApp.hide(nil)
        }
        hideWork()
        
        DispatchQueue.global(qos: .userInitiated).async {
            if app.path.hasPrefix("system:") {
                executeSystemCommand(app.path)
            } else if app.path.hasSuffix(".sh") {
                runProcess("/bin/bash", [app.path])
            } else if app.path.hasSuffix(".prefPane") {
                runProcess("/usr/bin/open", ["-b", "com.apple.systempreferences", app.path])
            } else {
                NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
            }
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }
    
    static func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    static func openInFinder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        
        if path.hasSuffix(".app") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    static func openFolder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        
        if path.hasSuffix(".app") {
            let contentsPath = "\(path)/Contents"
            let script = """
            tell application "Finder"
                open folder POSIX file "\(contentsPath)"
            end tell
            """
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        } else {
            let folderUrl = url.deletingLastPathComponent()
            NSWorkspace.shared.open(folderUrl)
        }
    }
    
    static func getSystemCommands() -> [AppInfo] {
        return [
            AppInfo(name: "Sleep", path: "system:sleep", icon: createSystemCommandIcon("moon.zzz.fill")),
            AppInfo(name: "Lock Screen", path: "system:lock", icon: createSystemCommandIcon("lock")),
            AppInfo(name: "Restart", path: "system:restart", icon: createSystemCommandIcon("arrow.clockwise")),
            AppInfo(name: "Shutdown", path: "system:shutdown", icon: createSystemCommandIcon("power"))
        ]
    }
    
    static func runProcess(_ executable: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        try? process.run()
    }
    
    static func runAppleScript(_ script: String) {
        runProcess("/usr/bin/osascript", ["-e", script])
    }
    
    static func executeSystemCommand(_ path: String) {
        switch path {
        case "system:sleep":
            // Put display to sleep using pmset
            runProcess("/usr/bin/pmset", ["displaysleepnow"])
        case "system:lock":
            runAppleScript("tell application \"System Events\" to keystroke \"q\" using {command down, control down}")
        case "system:restart":
            runAppleScript("tell application \"System Events\" to restart")
        case "system:shutdown":
            runAppleScript("tell application \"System Events\" to shut down")
        default:
            break
        }
    }
    
    static func createSystemCommandIcon(_ symbolName: String) -> NSImage? {
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: symbolName) {
            let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            return image.withSymbolConfiguration(config)
        }
        return nil
    }
}
