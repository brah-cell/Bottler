import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject var bottleManager: BottleManager
    let bottle: Bottle

    @State private var windowsVersion: WindowsVersion
    @State private var isApplying = false
    @State private var errorMessage: String?

    init(bottle: Bottle) {
        self.bottle = bottle
        _windowsVersion = State(initialValue: bottle.windowsVersion)
    }

    var body: some View {
        Form {
            Section("Windows Version") {
                Picker("Reported Version", selection: $windowsVersion) {
                    ForEach(WindowsVersion.allCases) { version in
                        Text(version.displayName).tag(version)
                    }
                }
                Button("Apply") { apply() }
                    .disabled(isApplying || windowsVersion == bottle.windowsVersion)
            }

            Section("Info") {
                Text("Per-app overrides (virtual desktop, environment variables, launch arguments) are configured from the Applications tab, on each app individually.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if isApplying {
                ProgressView()
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }

    private func apply() {
        isApplying = true
        errorMessage = nil
        Task {
            do {
                try await WineProcessManager.setWindowsVersion(windowsVersion, for: bottle)
                var updated = bottle
                updated.windowsVersion = windowsVersion
                bottleManager.update(updated)
            } catch {
                errorMessage = error.localizedDescription
            }
            isApplying = false
        }
    }
}
