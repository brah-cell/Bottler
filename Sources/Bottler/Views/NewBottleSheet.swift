import SwiftUI

struct NewBottleSheet: View {
    @EnvironmentObject var bottleManager: BottleManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedInstallation: WineInstallation?
    @State private var architecture: Architecture = .win64
    @State private var windowsVersion: WindowsVersion = .win10
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("New Bottle", systemImage: "wineglass.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.wine)

            if bottleManager.wineInstallations.isEmpty {
                WineSetupView(onFinished: {
                    bottleManager.refreshWineInstallations()
                    selectedInstallation = bottleManager.wineInstallations.first
                })
                .card()
            } else {
                Form {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    Picker("Wine Version", selection: $selectedInstallation) {
                        ForEach(bottleManager.wineInstallations) { install in
                            Text(install.label).tag(Optional(install))
                        }
                    }

                    Picker("Architecture", selection: $architecture) {
                        ForEach(Architecture.allCases) { arch in
                            Text(arch.displayName).tag(arch)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Windows Version", selection: $windowsVersion) {
                        ForEach(WindowsVersion.allCases) { version in
                            Text(version.displayName).tag(version)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.callout)
                }

                if isCreating {
                    ProgressView("Creating prefix…")
                }

                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .disabled(isCreating)
                    Button("Create") {
                        createBottle()
                    }
                    .buttonStyle(.wineProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedInstallation == nil || isCreating)
                }
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            bottleManager.refreshWineInstallations()
            selectedInstallation = bottleManager.wineInstallations.first
        }
    }

    private func createBottle() {
        guard let installation = selectedInstallation else { return }
        isCreating = true
        errorMessage = nil
        Task {
            do {
                _ = try await bottleManager.createBottle(
                    name: name,
                    wineInstallation: installation,
                    architecture: architecture,
                    windowsVersion: windowsVersion
                )
                isCreating = false
                dismiss()
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
