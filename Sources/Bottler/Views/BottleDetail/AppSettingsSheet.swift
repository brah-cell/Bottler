import SwiftUI
import AppKit

struct AppSettingsSheet: View {
    @EnvironmentObject var bottleManager: BottleManager
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle
    @State var app: BottleApp
    var autoLaunchOnSave: Bool = false
    var detectionNote: String? = nil

    @State private var envKey = ""
    @State private var envValue = ""
    @State private var useVirtualDesktop = false
    @State private var desktopResolution = "1024x768"

    private var isNewApp: Bool {
        !bottle.apps.contains(where: { $0.id == app.id })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isNewApp ? "Add Application" : "Application Settings")
                .font(.title2.weight(.semibold))

            if let detectionNote {
                Label(detectionNote, systemImage: "checkmark.seal.fill")
                    .font(.callout)
                    .foregroundStyle(Theme.wine)
            }

            Form {
                TextField("Name", text: $app.name)

                LabeledContent("Executable") {
                    Text(app.executablePath.isEmpty ? "Not chosen yet" : app.executablePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }
                Button("Choose Executable…") { chooseExecutable() }

                TextField("Extra Arguments", text: $app.arguments)

                Toggle("Run in Virtual Desktop", isOn: $useVirtualDesktop)
                if useVirtualDesktop {
                    TextField("Resolution (e.g. 1024x768)", text: $desktopResolution)
                }

                Section("Environment Overrides") {
                    ForEach(Array(app.envOverrides.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key).font(.system(.body, design: .monospaced))
                            Spacer()
                            Text(app.envOverrides[key] ?? "")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Button(role: .destructive) {
                                app.envOverrides.removeValue(forKey: key)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack {
                        TextField("KEY", text: $envKey).font(.system(.body, design: .monospaced))
                        TextField("value", text: $envValue).font(.system(.body, design: .monospaced))
                        Button("Add") {
                            guard !envKey.isEmpty else { return }
                            app.envOverrides[envKey] = envValue
                            envKey = ""
                            envValue = ""
                        }
                    }
                    Text("Example: WINEDLLOVERRIDES = winmm=n,b")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button(saveButtonTitle) {
                    app.virtualDesktopResolution = useVirtualDesktop ? desktopResolution : nil
                    if isNewApp {
                        bottleManager.addApp(app, to: bottle)
                    } else {
                        bottleManager.updateApp(app, in: bottle)
                    }
                    if autoLaunchOnSave {
                        try? WineProcessManager.launch(app: app, in: bottle)
                    }
                    dismiss()
                }
                .buttonStyle(.wineProminent)
                .disabled(app.name.trimmingCharacters(in: .whitespaces).isEmpty || app.executablePath.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520, height: 560)
        .onAppear {
            if let resolution = app.virtualDesktopResolution {
                useVirtualDesktop = true
                desktopResolution = resolution
            }
        }
    }

    private var saveButtonTitle: String {
        if autoLaunchOnSave { return "Save & Launch" }
        return isNewApp ? "Add" : "Save"
    }

    private func chooseExecutable() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: bottle.driveCPath)
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            app.executablePath = url.path
            if app.name.isEmpty {
                app.name = url.deletingPathExtension().lastPathComponent
            }
        }
    }
}
