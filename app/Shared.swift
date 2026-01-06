import Cocoa
import SwiftUI

// MARK: - Notifications
extension Notification.Name {
    static let focusSearchField = Notification.Name("focusSearchField")
    static let reloadApps = Notification.Name("reloadApps")
    static let switchTab = Notification.Name("switchTab")
    static let toggleMenuBarIcon = Notification.Name("toggleMenuBarIcon")
}

// MARK: - Constants
struct AppConstants {
    static let MAIN_FOLDER = (NSHomeDirectory() as NSString).appendingPathComponent(".dux-app-launcher")
    static let HISTORY_FILE = (MAIN_FOLDER as NSString).appendingPathComponent(".history")
    static let OPTIONS_FILE = (MAIN_FOLDER as NSString).appendingPathComponent(".options.yaml")
}

// MARK: - Models
struct AppInfo {
    let name: String
    let path: String
    let icon: NSImage?
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
    
    static func loadOptions() -> (includeSystemPreferences: Bool, showMenuBarIcon: Bool) {
        guard fileManager.fileExists(atPath: AppConstants.OPTIONS_FILE),
              let data = fileManager.contents(atPath: AppConstants.OPTIONS_FILE),
              let content = String(data: data, encoding: .utf8) else {
            return (false, true)
        }
        
        var includeSystemPreferences = false
        var showMenuBarIcon = true
        for line in content.components(separatedBy: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                if parts[0] == "include_system_preferences" {
                    includeSystemPreferences = parts[1] == "true"
                }
                if parts[0] == "show_menu_bar_icon" {
                    showMenuBarIcon = parts[1] == "true"
                }
            }
        }
        return (includeSystemPreferences, showMenuBarIcon)
    }
    
    static func saveOptions(includeSystemPreferences: Bool, showMenuBarIcon: Bool) {
        let content = """
        include_system_preferences: \(includeSystemPreferences)
        show_menu_bar_icon: \(showMenuBarIcon)
        """
        try? content.write(toFile: AppConstants.OPTIONS_FILE, atomically: true, encoding: .utf8)
    }
    
    static func loadApps(includeSystemPreferences: Bool) -> (apps: [AppInfo], appCount: Int, scriptCount: Int) {
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
    
    static func loadHistory() -> [AppInfo] {
        guard fileManager.fileExists(atPath: AppConstants.HISTORY_FILE),
              let data = fileManager.contents(atPath: AppConstants.HISTORY_FILE),
              let historyPaths = String(data: data, encoding: .utf8)?.components(separatedBy: "\n").filter({ !$0.isEmpty }) else {
            return []
        }
        
        return historyPaths.compactMap { path in
            let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
            let icon = getAppIcon(for: path)
            return AppInfo(name: name, path: path, icon: icon)
        }
    }
    
    static func saveHistory(_ app: AppInfo, currentHistory: [AppInfo]) {
        var newHistory = currentHistory.map { $0.path }.filter { $0 != app.path }
        newHistory.insert(app.path, at: 0)
        newHistory = Array(newHistory.prefix(4))
        
        let historyString = newHistory.joined(separator: "\n")
        try? historyString.write(toFile: AppConstants.HISTORY_FILE, atomically: true, encoding: .utf8)
    }
    
    static func launchApp(_ app: AppInfo, history: [AppInfo], onComplete: @escaping () -> Void) {
        saveHistory(app, currentHistory: history)
        
        if app.path.hasSuffix(".sh") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [app.path]
            try? process.run()
        } else if app.path.hasSuffix(".prefPane") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-b", "com.apple.systempreferences", app.path]
            try? process.run()
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        }
        
        NSApplication.shared.windows.first?.orderOut(nil)
        onComplete()
    }
}
