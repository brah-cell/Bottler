import SwiftUI

/// Shown whenever no Wine installation is detected — either as the app's
/// empty state, or inside the New Bottle sheet. One button runs the entire
/// setup (Homebrew, Rosetta if needed, Wine, winetricks) as a single
/// Terminal session, then this view polls automatically in the background
/// so the person doesn't have to remember to come back and click Refresh.
struct WineSetupView: View {
    @EnvironmentObject var bottleManager: BottleManager
    var onFinished: () -> Void = {}

    @State private var hasStartedSetup = false
    @State private var errorMessage: String?
    @State private var pollTask: Task<Void, Never>?

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
                .frame(maxWidth: 440)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }

            if hasStartedSetup {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Waiting for setup to finish in Terminal…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("I finished — Check Now") {
                        checkNow()
                    }
                    .font(.callout)
                }
            } else {
                Button("Set Up Wine Automatically") {
                    startSetup()
                }
                .buttonStyle(.wineProminent)
            }
        }
        .padding(32)
        .onDisappear {
            pollTask?.cancel()
        }
    }

    private var bodyText: String {
        if hasStartedSetup {
            return "A Terminal window has opened and is installing everything Bottler needs. If it asks for your Mac password, type it in and press Return — you won't see characters appear as you type, that's normal."
        } else {
            return "Bottler didn't find Wine on this Mac. Click below and it'll open a Terminal window that installs Homebrew (if needed), Wine, and winetricks for you automatically, prompting for your password only if required."
        }
    }

    private func startSetup() {
        errorMessage = nil
        Task {
            do {
                try await WineSetupManager.runSetupInTerminal()
                hasStartedSetup = true
                beginPolling()
            } catch {
                errorMessage = "\(error.localizedDescription) If macOS showed a permission prompt for Terminal, make sure to click Allow, then try again."
            }
        }
    }

    /// Polls every few seconds for Wine to appear, so the person doesn't
    /// have to remember to come back and click a Refresh button manually.
    private func beginPolling() {
        pollTask?.cancel()
        pollTask = Task {
            for _ in 0..<200 { // roughly 10 minutes at 3s intervals, then give up quietly
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                bottleManager.refreshWineInstallations()
                if !bottleManager.wineInstallations.isEmpty {
                    onFinished()
                    return
                }
            }
        }
    }

    private func checkNow() {
        bottleManager.refreshWineInstallations()
        if !bottleManager.wineInstallations.isEmpty {
            onFinished()
        }
    }
}
