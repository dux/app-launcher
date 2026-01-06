import SwiftUI
import ServiceManagement
import Cocoa

struct SettingsPanel: View {
    @Binding var launchAtLogin: Bool
    @Binding var includeSystemPreferences: Bool
    @Binding var includeSystemCommands: Bool
    @Binding var showMenuBarIcon: Bool
    var onSettingsChanged: () -> Void
    
    @State private var options = AppUtils.loadOptions()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 8)
            
            HStack {
                Image(systemName: "play.circle")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(newValue)
                    }
                Text("Launch at login")
            }
            
            HStack {
                Image(systemName: "menubar.rectangle")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Toggle("", isOn: $showMenuBarIcon)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: showMenuBarIcon) { _, _ in
                        options.showMenuBarIcon = showMenuBarIcon
                        AppUtils.saveOptions(options)
                        NotificationCenter.default.post(name: .toggleMenuBarIcon, object: showMenuBarIcon)
                    }
                Text("Show menu bar icon")
            }
            
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Toggle("", isOn: $includeSystemPreferences)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: includeSystemPreferences) { _, _ in
                        options.includeSystemPreferences = includeSystemPreferences
                        AppUtils.saveOptions(options)
                        onSettingsChanged()
                    }
                Text("Include System Settings panes")
            }
            
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Toggle("", isOn: $includeSystemCommands)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: includeSystemCommands) { _, _ in
                        options.includeSystemCommands = includeSystemCommands
                        AppUtils.saveOptions(options)
                        onSettingsChanged()
                    }
                Text("Include System Commands")
            }
            
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                Button(action: {
                    openAppFolder()
                }) {
                    Text("Open app folder")
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Keyboard shortcut section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Keyboard Shortcuts")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                HStack(spacing: 4) {
                    Text("Cmd + Space")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    Text("or")
                        .foregroundColor(.secondary)
                    Text("Shift + Cmd + Space")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                .font(.system(size: 12))
                
                Text("Use Shift+Cmd+Space if Spotlight uses Cmd+Space")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("To disable Spotlight: System Settings → Keyboard → Shortcuts → Spotlight")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Last modified: \(getAppModifiedTime())")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            let opts = AppUtils.loadOptions()
            includeSystemPreferences = opts.includeSystemPreferences
            showMenuBarIcon = opts.showMenuBarIcon
            includeSystemCommands = opts.includeSystemCommands
            options = opts
            checkLoginStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkLoginStatus()
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
    
    func getAppModifiedTime() -> String {
        let appPath = Bundle.main.bundlePath
        guard let attrs = try? AppUtils.fileManager.attributesOfItem(atPath: appPath),
              let modDate = attrs[.modificationDate] as? Date else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modDate)
    }
    
    func openAppFolder() {
        let folderUrl = URL(fileURLWithPath: AppConstants.MAIN_FOLDER)
        NSWorkspace.shared.open(folderUrl)
    }
}
