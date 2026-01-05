import Cocoa
import SwiftUI

let MAIN_FOLDER = (NSHomeDirectory() as NSString).appendingPathComponent(".dux-launcher")
let HISTORY_FILE = (MAIN_FOLDER as NSString).appendingPathComponent(".history")

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            if let win = NSApplication.shared.windows.first {
                self.window = win
                win.center()
                win.level = .floating
                win.orderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        
        setupGlobalHotkey()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
    
    func setupGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.keyCode == 49 {
                self.toggleWindow()
            }
        }
    }
    
    func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.center()
            window.orderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            if let contentView = window.contentView,
               let hostingView = contentView.subviews.first,
               let textField = findTextField(in: hostingView) {
                window.makeFirstResponder(textField)
            }
        }
    }
    
    func findTextField(in view: NSView) -> NSView? {
        if view is NSTextField {
            return view
        }
        for subview in view.subviews {
            if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }
}

struct AppInfo {
    let name: String
    let path: String
    let icon: NSImage?
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var history: [AppInfo] = []
    @State private var selectedIndex = 0
    @State private var showHistory = true
    @FocusState private var isFocused: Bool
    @State private var appCount = 0
    @State private var scriptCount = 0
    
    let fileManager = FileManager.default
    
    var displayApps: [AppInfo] {
        if searchText.isEmpty {
            if showHistory && !history.isEmpty {
                return Array(history.prefix(5))
            }
            return Array(apps.prefix(200))
        }
        showHistory = false
        return apps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText)
        }.prefix(200).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(.plain)
                .padding(12)
                .font(.system(size: 14))
                .background(Color(nsColor: .textBackgroundColor))
                .focused($isFocused)
                .onAppear {
                    loadApps()
                    loadHistory()
                    createMainFolder()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
                .onChange(of: searchText) { _, _ in
                    selectedIndex = 0
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
        .navigationTitle("DuxAppLauncher - \(appCount) apps & \(scriptCount) scripts")
        .background(Color(nsColor: .windowBackgroundColor))
        .onKeyPress(.downArrow) {
            if selectedIndex < displayApps.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            if selectedIndex < displayApps.count {
                launchApp(displayApps[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.escape) {
            NSApplication.shared.windows.first?.orderOut(nil)
            return .handled
        }
    }
    
    func createMainFolder() {
        if !fileManager.fileExists(atPath: MAIN_FOLDER) {
            try? fileManager.createDirectory(atPath: MAIN_FOLDER, withIntermediateDirectories: true)
        }
    }
    
    func loadApps() {
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
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: MAIN_FOLDER) {
            let shellApps = contents.compactMap { fileName -> AppInfo? in
                if fileName.hasSuffix(".sh") {
                    scriptCountTemp += 1
                    let fullPath = "\(MAIN_FOLDER)/\(fileName)"
                    let appName = fileName.replacingOccurrences(of: ".sh", with: "")
                    return AppInfo(name: appName, path: fullPath, icon: nil)
                }
                return nil
            }
            allApps.append(contentsOf: shellApps)
        }
        
        apps = allApps.sorted { $0.name < $1.name }
        appCount = appCountTemp
        scriptCount = scriptCountTemp
    }
    
    func loadHistory() {
        guard fileManager.fileExists(atPath: HISTORY_FILE),
              let data = fileManager.contents(atPath: HISTORY_FILE),
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
        try? historyString.write(toFile: HISTORY_FILE, atomically: true, encoding: .utf8)
    }
    
    func getAppIcon(for path: String) -> NSImage? {
        return NSWorkspace.shared.icon(forFile: path)
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

@main
struct AppLauncher: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
        .commands {
            CommandMenu("DuxAppLauncher") {
                Button(action: showAbout) {
                    Text("About")
                }
                Divider()
                Button(action: quitApp) {
                    Text("Quit")
                }
                .keyboardShortcut("Q")
            }
        }
    }
    
    func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DuxAppLauncher"
        alert.informativeText = "Made by Dino Reic\n\nhttps://github.com/dux/dux-app-launcher\n\nToggle with Cmd+Space"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}