import SwiftUI
import AppKit

struct OverviewTab: View {
    @EnvironmentObject var bottleManager: BottleManager
    let bottle: Bottle

    @State private var errorMessage: String?
    @State private var isBusy = false
    @State private var showingDeleteConfirm = false
    @State private var showingDuplicateSheet = false
    @State private var duplicateName = ""

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: bottle.name)
                LabeledContent("Prefix Path", value: bottle.prefixPath)
                LabeledContent("Architecture", value: bottle.architecture.displayName)
                LabeledContent("Windows Version", value: bottle.windowsVersion.displayName)
                LabeledContent("Wine Binary", value: bottle.wineBinaryPath)
                LabeledContent("Created", value: bottle.dateCreated.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Actions") {
                Button("Open Winecfg…") { run { try WineProcessManager.openWinecfg(for: bottle) } }
                Button("Open C: Drive in Finder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: bottle.driveCPath))
                }
                Button("Open Explorer (in-bottle)…") { run { try WineProcessManager.openExplorer(for: bottle) } }
                Button("Open Wine Console…") { run { try WineProcessManager.openConsole(for: bottle) } }
                Button("Kill Wine Processes") {
                    runAsync { try await WineProcessManager.killProcesses(for: bottle) }
                }
                Button("Duplicate Bottle…") { duplicateName = bottle.name + " Copy"; showingDuplicateSheet = true }
            }

            Section("Danger Zone") {
                Button("Delete Bottle…", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }

            if isBusy {
                ProgressView()
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Delete “\(bottle.name)”? This permanently removes the prefix and all installed apps.",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                do { try bottleManager.delete(bottle) } catch { errorMessage = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingDuplicateSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Duplicate Bottle").font(.title2.weight(.semibold))
                TextField("New name", text: $duplicateName)
                HStack {
                    Spacer()
                    Button("Cancel") { showingDuplicateSheet = false }
                    Button("Duplicate") {
                        do {
                            try bottleManager.duplicate(bottle, newName: duplicateName)
                            showingDuplicateSheet = false
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .buttonStyle(.wineProminent)
                }
            }
            .padding(24)
            .frame(width: 360)
        }
    }

    private func run(_ action: @escaping () throws -> Void) {
        do { try action() } catch { errorMessage = error.localizedDescription }
    }

    private func runAsync(_ action: @escaping () async throws -> Void) {
        isBusy = true
        errorMessage = nil
        Task {
            do {
                try await action()
            } catch {
                errorMessage = error.localizedDescription
            }
            isBusy = false
        }
    }
}
