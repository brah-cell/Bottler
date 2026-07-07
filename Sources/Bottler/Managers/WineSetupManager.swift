import Foundation

/// Handles the "we need Wine but it isn't installed yet" flow: detecting
/// Homebrew, and driving `brew install --cask wine-stable` /
/// `brew install winetricks` so the user never has to open Terminal
/// themselves for a standard setup.
enum WineSetupManager {

    private static let candidateBrewPaths = [
        "/opt/homebrew/bin/brew",   // Apple Silicon
        "/usr/local/bin/brew",      // Intel
    ]

    static var brewPath: String? {
        candidateBrewPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    static var isHomebrewInstalled: Bool { brewPath != nil }

    /// The official Homebrew install command, for when we can't run it
    /// ourselves (it needs an interactive sudo password prompt).
    static let homebrewInstallCommand =
        #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    /// Opens Terminal.app with the Homebrew install command pre-filled,
    /// since it requires an interactive password prompt we can't automate.
    /// Uses osascript to send Terminal an Apple Event — macOS will show a
    /// one-time "Bottler wants access to control Terminal" permission
    /// prompt the first time this runs (see NSAppleEventsUsageDescription
    /// in Info.plist). We await the result so a denied/failed automation
    /// surfaces as a real error instead of silently doing nothing.
    static func openTerminalForHomebrewInstall() async throws {
        let script = "tell application \"Terminal\" to do script \"\(homebrewInstallCommand)\""
        var output = ""
        try await Shell.run("/usr/bin/osascript", arguments: ["-e", script]) { line in
            output += line + "\n"
        }
        _ = output // available for debugging if needed
    }

    /// Installs Wine (via the `wine-stable` cask) and winetricks using the
    /// detected Homebrew, streaming progress line-by-line.
    static func installWineAndWinetricks(onOutput: @escaping (String) -> Void) async throws {
        guard let brew = brewPath else {
            throw SetupError.homebrewNotFound
        }

        onOutput("==> Installing Wine (this can take a few minutes)…")
        try await Shell.run(brew, arguments: ["install", "--cask", "wine-stable"], onOutput: onOutput)

        onOutput("==> Installing winetricks…")
        try await Shell.run(brew, arguments: ["install", "winetricks"], onOutput: onOutput)

        onOutput("==> Done.")
    }

    enum SetupError: Error, LocalizedError {
        case homebrewNotFound

        var errorDescription: String? {
            switch self {
            case .homebrewNotFound:
                return "Homebrew isn't installed. Install it first, then try again."
            }
        }
    }
}
