import SwiftUI
import Cocoa

// Notifications for keyboard navigation from parent
extension Notification.Name {
    static let searchNavigateDown = Notification.Name("searchNavigateDown")
    static let searchNavigateUp = Notification.Name("searchNavigateUp")
    static let searchLaunchSelected = Notification.Name("searchLaunchSelected")
}

struct SearchPanel: View {
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var history: [AppInfo] = []
    @State private var selectedIndex = 0
    @State private var appCount = 0
    @State private var scriptCount = 0
    @State private var includeSystemPreferences = false
    @FocusState private var isFocused: Bool
    
    var onSettingsLoaded: ((Bool) -> Void)?
    var onAppsReloaded: (() -> Void)?
    
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
        VStack(spacing: 0) {
            TextField("Search \(appCount) apps & \(scriptCount) scripts...", text: $searchText)
                .textFieldStyle(.plain)
                .padding(12)
                .font(.system(size: 14))
                .background(Color(nsColor: .textBackgroundColor))
                .focused($isFocused)
                .onAppear {
                    AppUtils.createMainFolder()
                    let prefs = AppUtils.loadOptions()
                    includeSystemPreferences = prefs.includeSystemPreferences
                    onSettingsLoaded?(prefs.includeSystemPreferences)
                    reloadApps(prefs.includeSystemPreferences)
                    history = AppUtils.loadHistory()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
                .onChange(of: searchText) { _, newValue in
                    selectedIndex = 0
                    if newValue.isEmpty {
                        history = AppUtils.loadHistory()
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
                        launchSelectedApp()
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
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
            isFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchNavigateDown)) { _ in
            if selectedIndex < displayApps.count - 1 {
                selectedIndex += 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchNavigateUp)) { _ in
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchLaunchSelected)) { _ in
            launchSelectedApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadApps)) { _ in
            // Re-read options since settings may have changed
            let prefs = AppUtils.loadOptions()
            includeSystemPreferences = prefs.includeSystemPreferences
            reloadApps(prefs.includeSystemPreferences)
        }
    }
    
    func reloadApps(_ includePrefs: Bool? = nil) {
        let shouldIncludePrefs = includePrefs ?? includeSystemPreferences
        let result = AppUtils.loadApps(includeSystemPreferences: shouldIncludePrefs)
        apps = result.apps
        appCount = result.appCount
        scriptCount = result.scriptCount
        onAppsReloaded?()
    }
    
    func launchSelectedApp() {
        guard selectedIndex < displayApps.count else { return }
        let app = displayApps[selectedIndex]
        AppUtils.launchApp(app, history: history) {
            searchText = ""
        }
    }
}
