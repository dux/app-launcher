import SwiftUI
import Cocoa

struct SearchPanel: View {
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var history: [AppInfo] = []
    @State private var historyOrder: [String: Int] = [:]
    @State private var historyFrequencies: [String: Int] = [:]
    @State private var selectedIndex = 0
    @State private var appCount = 0
    @State private var scriptCount = 0
    @State private var includeSystemPreferences = false
    @State private var includeSystemCommands = false
    @FocusState private var isFocused: Bool

    var onSettingsLoaded: ((Bool) -> Void)?
    @Binding var selectedAppPath: String?

    var displayApps: [AppInfo] {
        if searchText.isEmpty {
            if !history.isEmpty {
                return Array(history.prefix(5))
            }
            return Array(apps.prefix(200))
        }
        let filtered = apps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText)
        }
        return Array(sortApps(filtered, query: searchText).prefix(200))
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search \(appCount) apps & \(scriptCount) scripts...", text: $searchText)
                .textFieldStyle(.plain)
                .padding(20)
                .font(.system(size: 20))
                .background(Color(nsColor: .textBackgroundColor))
                .focused($isFocused)
                .onAppear {
                    AppUtils.createMainFolder()
                    let opts = AppUtils.loadOptions()
                    includeSystemPreferences = opts.includeSystemPreferences
                    includeSystemCommands = opts.includeSystemCommands
                    onSettingsLoaded?(opts.includeSystemPreferences)
                    reloadApps(opts.includeSystemPreferences, opts.includeSystemCommands)
                    refreshHistory()
                    if !displayApps.isEmpty {
                        selectedAppPath = displayApps[0].path
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
                .onChange(of: searchText) { newValue in
                    selectedIndex = 0
                    if newValue.isEmpty {
                        refreshHistory()
                    }
                    if !displayApps.isEmpty {
                        selectedAppPath = displayApps[0].path
                    }
                }

            if displayApps.isEmpty {
                Text("No apps found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AppListView(apps: displayApps, selectedIndex: $selectedIndex, onActivate: handleAppActivation, selectedAppPath: $selectedAppPath)
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
            if isFocused {
                activateSelectedApp()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadApps)) { _ in
            // Re-read options since settings may have changed
            let opts = AppUtils.loadOptions()
            includeSystemPreferences = opts.includeSystemPreferences
            includeSystemCommands = opts.includeSystemCommands
            reloadApps(opts.includeSystemPreferences, opts.includeSystemCommands)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabSwitched)) { _ in
            selectedIndex = 0
            if !displayApps.isEmpty {
                selectedAppPath = displayApps[0].path
            }
        }
    }

    func reloadApps(_ includePrefs: Bool? = nil, _ includeCommands: Bool? = nil) {
        let shouldIncludePrefs = includePrefs ?? includeSystemPreferences
        let shouldIncludeCommands = includeCommands ?? includeSystemCommands
        let result = AppUtils.loadApps(includeSystemPreferences: shouldIncludePrefs, includeSystemCommands: shouldIncludeCommands)
        apps = result.apps
        appCount = result.appCount
        scriptCount = result.scriptCount
    }

    func activateSelectedApp() {
        guard let path = selectedAppPath,
              let app = displayApps.first(where: { $0.path == path }) else { return }
        handleAppActivation(app)
    }

    private func handleAppActivation(_ app: AppInfo) {
        AppUtils.activateApp(app)
        searchText = ""
        refreshHistory()
    }
    
    private func refreshHistory() {
        history = AppUtils.loadHistory()
        let metadata = AppUtils.loadHistoryMetadata()
        historyOrder = metadata.order
        historyFrequencies = metadata.frequencies
    }
    
    private func sortApps(_ apps: [AppInfo], query: String) -> [AppInfo] {
        let loweredQuery = query.lowercased()
        return apps.sorted { first, second in
            let firstPrefix = first.name.lowercased().hasPrefix(loweredQuery)
            let secondPrefix = second.name.lowercased().hasPrefix(loweredQuery)
            if firstPrefix != secondPrefix {
                return firstPrefix
            }
            let freq1 = historyFrequencies[first.path, default: 0]
            let freq2 = historyFrequencies[second.path, default: 0]
            if freq1 != freq2 {
                return freq1 > freq2
            }
            let order1 = historyOrder[first.path] ?? Int.max
            let order2 = historyOrder[second.path] ?? Int.max
            if order1 != order2 {
                return order1 < order2
            }
            return first.name < second.name
        }
    }
}
