import SwiftUI
import Cocoa

struct ScriptsPanel: View {
    @State private var scripts: [String] = []
    @State private var selectedScript: String? = nil
    @State private var scriptName = ""
    @State private var scriptCommand = ""
    
    var onScriptsChanged: () -> Void
    
    let fileManager = FileManager.default
    
    var body: some View {
        HStack(spacing: 0) {
            // Script list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Scripts")
                        .font(.system(size: 14, weight: .bold))
                    Text("(\(scripts.count))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 4)
                
                if scripts.isEmpty {
                    Text("No scripts found")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(scripts, id: \.self, selection: $selectedScript) { script in
                        Text(script)
                            .font(.system(size: 12))
                    }
                    .listStyle(.plain)
                    .frame(minWidth: 120)
                }
                
                Button("New") {
                    scriptName = ""
                    scriptCommand = ""
                    selectedScript = nil
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(width: 160)
            
            Divider()
            
            // Script editor
            VStack(alignment: .leading, spacing: 12) {
                Text("Script Editor")
                    .font(.system(size: 14, weight: .bold))
                
                HStack {
                    Text("Name:")
                        .frame(width: 60, alignment: .leading)
                    TextField("script name", text: $scriptName)
                        .textFieldStyle(.roundedBorder)
                    Text(".sh")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Command:")
                    TextEditor(text: $scriptCommand)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.3))
                }
                
                HStack {
                    Button("Save") {
                        saveScript()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(scriptName.isEmpty || scriptCommand.isEmpty)
                    
                    if selectedScript != nil {
                        Button("Run") {
                            runScript()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Delete") {
                            deleteScript()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadScripts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loadScripts()
        }
        .onChange(of: selectedScript) { _, newValue in
            if let script = newValue {
                loadScript(script)
            }
        }
    }
    
    func loadScripts() {
        // Ensure folder exists
        AppUtils.createMainFolder()
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: AppConstants.MAIN_FOLDER) {
            scripts = contents.filter { $0.hasSuffix(".sh") }
                .map { $0.replacingOccurrences(of: ".sh", with: "") }
                .sorted()
        } else {
            scripts = []
        }
    }
    
    func loadScript(_ name: String) {
        let path = "\(AppConstants.MAIN_FOLDER)/\(name).sh"
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            scriptName = name
            scriptCommand = content
        }
    }
    
    func saveScript() {
        let path = "\(AppConstants.MAIN_FOLDER)/\(scriptName).sh"
        try? scriptCommand.write(toFile: path, atomically: true, encoding: .utf8)
        try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
        loadScripts()
        onScriptsChanged()
        selectedScript = scriptName
    }
    
    func deleteScript() {
        guard let script = selectedScript else { return }
        let path = "\(AppConstants.MAIN_FOLDER)/\(script).sh"
        try? fileManager.removeItem(atPath: path)
        scriptName = ""
        scriptCommand = ""
        selectedScript = nil
        loadScripts()
        onScriptsChanged()
    }
    
    func runScript() {
        guard let script = selectedScript else { return }
        let path = "\(AppConstants.MAIN_FOLDER)/\(script).sh"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [path]
        try? process.run()
    }
}
