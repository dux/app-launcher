import SwiftUI
import ServiceManagement
import Cocoa

struct SettingsPanel: View {
    @Binding var launchAtLogin: Bool
    @Binding var includeSystemPreferences: Bool
    @Binding var showMenuBarIcon: Bool
    var onSettingsChanged: () -> Void
    
    let fileManager = FileManager.default
    
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
                    .onChange(of: showMenuBarIcon) { _, newValue in
                        AppUtils.saveOptions(includeSystemPreferences: includeSystemPreferences, showMenuBarIcon: newValue)
                        NotificationCenter.default.post(name: .toggleMenuBarIcon, object: newValue)
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
                    .onChange(of: includeSystemPreferences) { _, newValue in
                        AppUtils.saveOptions(includeSystemPreferences: newValue, showMenuBarIcon: showMenuBarIcon)
                        onSettingsChanged()
                    }
                Text("Include System Settings panes")
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
        guard let attrs = try? fileManager.attributesOfItem(atPath: appPath),
              let modDate = attrs[.modificationDate] as? Date else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modDate)
    }
}
