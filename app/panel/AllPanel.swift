import SwiftUI

struct AllPanel: View {
    @State private var apps: [AppInfo] = []
    @State private var selectedIndex = 0
    @State private var selectedLetter: Character? = nil
    @State private var selectedMode: String = "all"
    @FocusState private var focusedLetter: String?
    @State private var appCount = 0
    @State private var scriptCount = 0
    @State private var includeSystemPreferences = false
    @State private var includeSystemCommands = false

    var displayApps: [AppInfo] {
        if selectedMode == "latest" {
            return sortByLatest(apps)
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
                .help("List all apps")

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
                .help("Sort apps by installed time")

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

            if displayApps.isEmpty {
                Text("No apps found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(0..<displayApps.count, id: \.self) { index in
                        AppItemRow(app: displayApps[index], isSelected: index == selectedIndex, showDate: selectedMode == "latest")
                            .listRowSeparator(.hidden)
                            .id(index)
                            .contentShape(Rectangle())
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
                    .onChange(of: selectedIndex) { newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                    .onChange(of: selectedLetter) { _ in
                        withAnimation {
                            proxy.scrollTo(0, anchor: .top)
                        }
                    }
                }
            }
        }
        .onAppear {
            AppUtils.createMainFolder()
            let opts = AppUtils.loadOptions()
            includeSystemPreferences = opts.includeSystemPreferences
            includeSystemCommands = opts.includeSystemCommands
            reloadApps(opts.includeSystemPreferences, opts.includeSystemCommands)
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
        AppUtils.launchApp(app) {}
    }
}
