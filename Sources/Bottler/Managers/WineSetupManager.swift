import Foundation

/// Handles the "we need Wine but it isn't installed yet" flow.
///
/// Everything runs as ONE combined script inside a single Terminal window,
/// rather than as separate headless background steps. This matters because
/// several sub-steps genuinely require `sudo` with a real interactive
/// terminal (Homebrew's own installer, and the `gstreamer-runtime`
/// dependency that `wine-stable` pulls in) — running them invisibly via
/// a background Process silently fails with "sudo: a terminal is required
/// to read the password," even though nothing looks wrong to the app.
/// Terminal.app always has a real tty, so routing everything through it
/// sidesteps that whole class of failure.
///
/// The script is fully idempotent and self-detecting: it's safe to run
/// again if partially completed, and it works whether Homebrew is already
/// installed or not, without Bottler needing to know in advance.
enum WineSetupManager {

    private static let candidateBrewPaths = [
        "/opt/homebrew/bin/brew",   // Apple Silicon
        "/usr/local/bin/brew",      // Intel
    ]

    static var brewPath: String? {
        candidateBrewPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    static var isHomebrewInstalled: Bool { brewPath != nil }

    /// The full setup script, run as a single Terminal session:
    /// 1. Installs Homebrew if it isn't already present.
    /// 2. Loads Homebrew into this shell session's PATH (needed right after
    ///    a fresh install, before a new login shell would normally pick it up).
    /// 3. Installs Rosetta 2 if running on Apple Silicon and it's missing
    ///    (wine-stable is an Intel build and requires it).
    /// 4. Installs Wine and winetricks.
    /// Each install step tolerates already being done (no `set -e`), so
    /// re-running this after a partial/interrupted previous attempt is safe.
    static var combinedSetupScript: String {
        """
        if ! command -v brew >/dev/null 2>&1; then echo 'Installing Homebrew...'; /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; fi; eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"; if [ "$(uname -m)" = "arm64" ] && ! arch -x86_64 /usr/bin/true 2>/dev/null; then echo 'Installing Rosetta 2 (required to run Wine on Apple Silicon)...'; softwareupdate --install-rosetta --agree-to-license; fi; echo 'Installing Wine (this can take a few minutes)...'; brew install --cask wine-stable || (echo 'wine-stable unavailable, trying the wine-crossover tap instead...'; brew tap gcenx/wine && brew install --cask --no-quarantine gcenx/wine/wine-crossover); echo 'Installing winetricks...'; brew install winetricks; echo ''; echo 'Bottler setup finished! You can close this window and go back to Bottler.'
        """
    }

    /// Opens Terminal.app and runs the combined setup script inside it.
    /// Uses osascript to send Terminal an Apple Event — macOS shows a
    /// one-time "Bottler wants access to control Terminal" permission
    /// prompt the first time this runs (see NSAppleEventsUsageDescription
    /// in Info.plist). We await the result so a denied/failed automation
    /// surfaces as a real error instead of silently doing nothing.
    static func runSetupInTerminal() async throws {
        // The script itself contains double quotes (from $(...) substitutions),
        // which must be escaped before embedding it inside the AppleScript
        // string literal below — otherwise the generated AppleScript is
        // malformed and fails immediately, before Terminal even opens.
        let escapedScript = combinedSetupScript
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"Terminal\" to do script \"\(escapedScript)\""

        var output = ""
        do {
            try await Shell.run("/usr/bin/osascript", arguments: ["-e", script]) { line in
                output += line + "\n"
            }
        } catch {
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            throw SetupError.terminalAutomationFailed(detail.isEmpty ? error.localizedDescription : detail)
        }
    }

    enum SetupError: Error, LocalizedError {
        case terminalAutomationFailed(String)

        var errorDescription: String? {
            switch self {
            case .terminalAutomationFailed(let detail):
                return "Couldn't open Terminal: \(detail)"
            }
        }
    }
}
