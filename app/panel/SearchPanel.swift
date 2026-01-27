import SwiftUI
import Cocoa

struct SearchPanel: View {
    @ObservedObject private var appStore = AppStore.shared
    @State private var searchText = ""
    @State private var history: [AppInfo] = []
    @State private var historyOrder: [String: Int] = [:]
    @State private var historyFrequencies: [String: Int] = [:]
    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    var isActive: Bool = true
    var onSettingsLoaded: ((Bool) -> Void)?

    private var apps: [AppInfo] {
        appStore.apps
    }

    var displayApps: [AppInfo] {
        if searchText.isEmpty {
            if !history.isEmpty {
                return Array(history.prefix(10))
            }
            return Array(apps.prefix(200))
        }
        let filtered = apps.filter { app in
            app.name.lowercased().contains(searchText.lowercased())
        }
        return Array(sortApps(filtered, query: searchText).prefix(200))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                TextField("Search \(appStore.appCount) apps, \(appStore.scriptCount) scripts\(appStore.panelCount > 0 ? ", \(appStore.panelCount) panels" : "")...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20))
                    .focused($isFocused)
            }
            .padding(20)
            .background(Color(nsColor: .textBackgroundColor))
            .onAppear {
                AppUtils.createMainFolder()
                let opts = AppUtils.loadOptions()
                onSettingsLoaded?(opts.includeSystemPreferences)
                refreshHistory()
                selectedIndex = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .onChange(of: searchText) { newValue in
                selectedIndex = 0
                if newValue.isEmpty {
                    refreshHistory()
                }
            }

            if displayApps.isEmpty {
                Text("No apps found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AppListView(apps: displayApps, selectedIndex: $selectedIndex, onActivate: handleAppActivation)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
            isFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchNavigateDown)) { _ in
            if isActive && selectedIndex < displayApps.count - 1 {
                selectedIndex += 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchNavigateUp)) { _ in
            if isActive && selectedIndex > 0 {
                selectedIndex -= 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .searchLaunchSelected)) { _ in
            if isActive {
                activateSelectedApp()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadApps)) { _ in
            appStore.reload()
            selectedIndex = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabSwitched)) { _ in
            selectedIndex = 0
        }
        .onChange(of: displayApps.count) { newCount in
            if selectedIndex >= newCount {
                selectedIndex = max(0, newCount - 1)
            }
        }
    }

    func activateSelectedApp() {
        guard selectedIndex >= 0, selectedIndex < displayApps.count else { return }
        let app = displayApps[selectedIndex]
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
