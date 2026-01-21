import SwiftUI

struct AllPanel: View {
    @ObservedObject private var appStore = AppStore.shared
    @State private var selectedIndex = 0
    @State private var selectedLetter: Character? = nil
    @State private var selectedMode: String = "all"
    @FocusState private var focusedLetter: String?

    var isActive: Bool = false

    private var apps: [AppInfo] {
        appStore.appsWithoutScripts
    }

    var displayApps: [AppInfo] {
        if selectedMode == "latest" {
            return sortByLatest(apps)
        } else if selectedMode == "user" {
            let userApps = apps.filter { !$0.path.hasPrefix("/System/") }
            if let letter = selectedLetter {
                return userApps.filter { $0.name.first?.uppercased() == String(letter) }
            }
            return userApps
        } else if selectedMode == "system" {
            return appStore.systemPanels
        } else if let letter = selectedLetter {
            return apps.filter { $0.name.first?.uppercased() == String(letter) }
        }
        return apps
    }

    func sortByLatest(_ apps: [AppInfo]) -> [AppInfo] {
        return apps.sorted { $0.creationDate > $1.creationDate }
    }

    var availableLetters: [Character] {
        let letters = Set(apps.compactMap { $0.name.first?.uppercased().first })
        return letters.sorted()
    }

    var allFilterOptions: [String] {
        var options = ["all", "latest", "user"]
        if appStore.includeSystemPreferences {
            options.append("system")
        }
        return options + availableLetters.map { String($0) }
    }

    var currentFilterIndex: Int {
        if selectedMode == "all" { return 0 }
        if selectedMode == "latest" { return 1 }
        if selectedMode == "user" { return 2 }
        let letterOffset = appStore.includeSystemPreferences ? 4 : 3
        if selectedMode == "system" { return 3 }
        if let letter = selectedLetter, let idx = availableLetters.firstIndex(of: letter) {
            return letterOffset + idx
        }
        return 0
    }

    var infoText: String {
        if selectedMode == "latest" {
            return "Showing \(displayApps.count) apps (latest first)"
        } else if selectedMode == "user" {
            if let letter = selectedLetter {
                return "Showing \(displayApps.count) user apps starting with \(letter)"
            }
            return "Showing \(displayApps.count) user apps"
        } else if selectedMode == "system" {
            return "Showing \(displayApps.count) system panels"
        } else if let letter = selectedLetter {
            return "Showing \(displayApps.count) apps starting with \(letter)"
        }
        return "Showing all \(displayApps.count) apps"
    }

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 35), spacing: 8)
            ], spacing: 8) {
                Button(action: {
                    selectedLetter = nil
                    selectedMode = "all"
                    selectedIndex = 0
                    focusedLetter = "all"
                }) {
                    Text("≡")
                        .font(.system(size: 14, weight: selectedLetter == nil && selectedMode == "all" ? .bold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedLetter == nil && selectedMode == "all" ? Color.accentColor.opacity(0.3) : Color.clear)
                        )
                        .foregroundColor(selectedLetter == nil && selectedMode == "all" ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .focused($focusedLetter, equals: "all")

                Button(action: {
                    selectedLetter = nil
                    selectedMode = "latest"
                    selectedIndex = 0
                    focusedLetter = "latest"
                }) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: selectedMode == "latest" ? .bold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedMode == "latest" ? Color.accentColor.opacity(0.3) : Color.clear)
                        )
                        .foregroundColor(selectedMode == "latest" ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .focused($focusedLetter, equals: "latest")

                Button(action: {
                    selectedLetter = nil
                    selectedMode = "user"
                    selectedIndex = 0
                    focusedLetter = "user"
                }) {
                    Image(systemName: "person")
                        .font(.system(size: 10, weight: selectedMode == "user" ? .bold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedMode == "user" ? Color.accentColor.opacity(0.3) : Color.clear)
                        )
                        .foregroundColor(selectedMode == "user" ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .focused($focusedLetter, equals: "user")

                if appStore.includeSystemPreferences {
                    Button(action: {
                        selectedLetter = nil
                        selectedMode = "system"
                        selectedIndex = 0
                        focusedLetter = "system"
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10, weight: selectedMode == "system" ? .bold : .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedMode == "system" ? Color.accentColor.opacity(0.3) : Color.clear)
                            )
                            .foregroundColor(selectedMode == "system" ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedLetter, equals: "system")
                }

                ForEach(availableLetters, id: \.self) { letter in
                    Button(action: {
                        selectedLetter = letter
                        selectedMode = "letter"
                        selectedIndex = 0
                        focusedLetter = String(letter)
                    }) {
                        Text(String(letter))
                            .font(.system(size: 12, weight: selectedLetter == letter ? .bold : .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedLetter == letter ? Color.accentColor.opacity(0.3) : Color.clear)
                            )
                            .foregroundColor(selectedLetter == letter ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedLetter, equals: String(letter))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxHeight: 80)

            VStack(spacing: 0) {
                Text(infoText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                if displayApps.isEmpty {
                    Text("No apps found")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        AppListView(apps: displayApps, selectedIndex: $selectedIndex, onActivate: AppUtils.activateApp, showDate: selectedMode == "latest")
                            .onChange(of: selectedLetter) { _ in
                                withAnimation {
                                    proxy.scrollTo(0, anchor: .top)
                                }
                            }
                    }
                }
            }
        }
        .onAppear {
            AppUtils.createMainFolder()
            resetToTop()
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
            resetToTop()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabSwitched)) { _ in
            resetToTop()
        }
        .onChange(of: displayApps.count) { newCount in
            if selectedIndex >= newCount {
                selectedIndex = max(0, newCount - 1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateLeft)) { _ in
            if isActive {
                let newIndex = max(0, currentFilterIndex - 1)
                selectFilter(at: newIndex)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateRight)) { _ in
            if isActive {
                let newIndex = min(allFilterOptions.count - 1, currentFilterIndex + 1)
                selectFilter(at: newIndex)
            }
        }
    }

    func selectFilter(at index: Int) {
        guard index >= 0 && index < allFilterOptions.count else { return }
        let option = allFilterOptions[index]
        selectedIndex = 0

        switch option {
        case "all":
            selectedLetter = nil
            selectedMode = "all"
            focusedLetter = "all"
        case "latest":
            selectedLetter = nil
            selectedMode = "latest"
            focusedLetter = "latest"
        case "user":
            selectedLetter = nil
            selectedMode = "user"
            focusedLetter = "user"
        case "system":
            selectedLetter = nil
            selectedMode = "system"
            focusedLetter = "system"
        default:
            if let letter = option.first {
                selectedLetter = letter
                selectedMode = "letter"
                focusedLetter = option
            }
        }
    }

    func resetToTop() {
        selectedIndex = 0
        selectedLetter = nil
        selectedMode = "all"
    }

    func activateSelectedApp() {
        guard selectedIndex >= 0, selectedIndex < displayApps.count else { return }
        let app = displayApps[selectedIndex]
        AppUtils.activateApp(app)
    }
}
