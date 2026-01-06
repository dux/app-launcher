import SwiftUI
import Cocoa

struct SearchPanel: View {
    @State private var searchText = ""
    @State private var apps: [AppInfo] = []
    @State private var history: [AppInfo] = []
    @State private var selectedIndex = 0
    @State private var appCount = 0
    @State private var scriptCount = 0
    @State private var includeSystemPreferences = false
    @State private var includeSystemCommands = false
    @FocusState private var isFocused: Bool
    
    var onSettingsLoaded: ((Bool) -> Void)?
    
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
                    let opts = AppUtils.loadOptions()
                    includeSystemPreferences = opts.includeSystemPreferences
                    includeSystemCommands = opts.includeSystemCommands
                    onSettingsLoaded?(opts.includeSystemPreferences)
                    reloadApps(opts.includeSystemPreferences, opts.includeSystemCommands)
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
                ScrollViewReader { proxy in
                    List(0..<displayApps.count, id: \.self) { index in
                        AppItemRow(app: displayApps[index], isSelected: index == selectedIndex)
                            .listRowSeparator(.hidden)
                            .id(index)
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
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
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
            let opts = AppUtils.loadOptions()
            includeSystemPreferences = opts.includeSystemPreferences
            includeSystemCommands = opts.includeSystemCommands
            reloadApps(opts.includeSystemPreferences, opts.includeSystemCommands)
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
    
    func launchSelectedApp() {
        guard selectedIndex < displayApps.count else { return }
        let app = displayApps[selectedIndex]
        AppUtils.launchApp(app, history: history) {
            searchText = ""
        }
    }
}
