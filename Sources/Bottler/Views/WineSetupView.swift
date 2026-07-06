import SwiftUI

/// Shown whenever no Wine installation is detected — either as the app's
/// empty state, or inside the New Bottle sheet. Offers to install Wine +
/// winetricks automatically via Homebrew, streaming progress, instead of
/// sending the user to Terminal.
struct WineSetupView: View {
    @EnvironmentObject var bottleManager: BottleManager
    var onFinished: () -> Void = {}

    @State private var isInstalling = false
    @State private var errorMessage: String?
    @State private var showingLog = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wineglass.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.wine)

            Text("Let's set up Wine")
                .font(.title2.weight(.semibold))

            Text(bodyText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout)
            }

            if isInstalling {
                VStack(spacing: 10) {
                    ProgressView()
                    Button("Show Progress Log") { showingLog = true }
                        .font(.callout)
                }
            } else if WineSetupManager.isHomebrewInstalled {
                Button("Install Wine Automatically") {
                    installWine()
                }
                .buttonStyle(.wineProminent)
            } else {
                VStack(spacing: 10) {
                    Button("Install Homebrew First") {
                        openHomebrewInstall()
                    }
                    .buttonStyle(.wineProminent)
                    Text("Homebrew needs your password in Terminal, so we can't fully automate this step. Once it finishes, come back and click Refresh.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                    Button("Refresh") {
                        bottleManager.refreshWineInstallations()
                        if !bottleManager.wineInstallations.isEmpty { onFinished() }
                    }
                }
            }
        }
        .padding(32)
        .sheet(isPresented: $showingLog) {
            VStack(alignment: .leading) {
                Text("Installing Wine").font(.title2.weight(.semibold)).padding([.top, .horizontal])
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

    private var bodyText: String {
        if WineSetupManager.isHomebrewInstalled {
            return "Bottler didn't find Wine on this Mac. Click below and it'll install Wine and winetricks for you via Homebrew — no Terminal required."
        } else {
            return "Bottler needs Wine, which is installed via Homebrew. Homebrew isn't on this Mac yet, so let's install that first."
        }
    }

    private func installWine() {
        isInstalling = true
        errorMessage = nil
        showingLog = true
        LogStore.shared.clear()
        Task {
            do {
                try await WineSetupManager.installWineAndWinetricks { line in
                    Task { @MainActor in LogStore.shared.append(line) }
                }
                bottleManager.refreshWineInstallations()
                isInstalling = false
                if !bottleManager.wineInstallations.isEmpty {
                    onFinished()
                }
            } catch {
                errorMessage = error.localizedDescription
                isInstalling = false
            }
        }
    }

    private func openHomebrewInstall() {
        do {
            try WineSetupManager.openTerminalForHomebrewInstall()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
