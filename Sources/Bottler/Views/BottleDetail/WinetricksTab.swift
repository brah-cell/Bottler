import SwiftUI

struct WinetricksTab: View {
    @EnvironmentObject var bottleManager: BottleManager
    let bottle: Bottle

    @State private var selectedVerbs: Set<String> = []
    @State private var customVerb: String = ""
    @State private var showingLog = false
    @State private var errorMessage: String?
    @State private var isRunning = false

    private var groupedPresets: [String: [WinetricksPreset]] {
        Dictionary(grouping: WinetricksManager.presets, by: \.category)
    }

    private var winetricksPath: String? {
        bottleManager.wineInstallations.first(where: { $0.binaryPath == bottle.wineBinaryPath })?.winetricksPath
            ?? WineDetector.firstAvailableWinetricks()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if winetricksPath == nil {
                Text("winetricks not found. Install it via `brew install winetricks`.")
                    .foregroundStyle(.secondary)
                    .padding()
            }

            Form {
                ForEach(groupedPresets.keys.sorted(), id: \.self) { category in
                    Section(category) {
                        ForEach(groupedPresets[category] ?? []) { preset in
                            Toggle(preset.label, isOn: Binding(
                                get: { selectedVerbs.contains(preset.verb) },
                                set: { isOn in
                                    if isOn { selectedVerbs.insert(preset.verb) }
                                    else { selectedVerbs.remove(preset.verb) }
                                }
                            ))
                        }
                    }
                }

                Section("Custom Verb") {
                    HStack {
                        TextField("e.g. steam", text: $customVerb)
                        Button("Add") {
                            guard !customVerb.isEmpty else { return }
                            selectedVerbs.insert(customVerb)
                            customVerb = ""
                        }
                    }
                }
            }
            .formStyle(.grouped)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).padding(.horizontal)
            }

            HStack {
                Text("\(selectedVerbs.count) selected")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Show Log") { showingLog = true }
                Button {
                    runSelected()
                } label: {
                    if isRunning {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Run")
                    }
                }
                .buttonStyle(.wineProminent)
                .disabled(selectedVerbs.isEmpty || winetricksPath == nil || isRunning)
            }
            .padding()
        }
        .sheet(isPresented: $showingLog) {
            VStack(alignment: .leading) {
                Text("Winetricks Log").font(.title2.weight(.semibold)).padding([.top, .horizontal])
                LogConsoleView()
                HStack {
                    Spacer()
                    Button("Close") { showingLog = false }
                }
                .padding()
            }
            .frame(width: 640, height: 420)
        }
    }

    private func runSelected() {
        guard let winetricksPath else { return }
        isRunning = true
        errorMessage = nil
        showingLog = true
        LogStore.shared.clear()
        Task {
            do {
                try await WinetricksManager.run(
                    verbs: Array(selectedVerbs),
                    in: bottle,
                    winetricksPath: winetricksPath
                ) { line in
                    Task { @MainActor in LogStore.shared.append(line) }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }
}
