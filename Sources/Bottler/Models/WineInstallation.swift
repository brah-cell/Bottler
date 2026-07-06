import Foundation

/// A Wine installation discovered on disk (Homebrew, CrossOver, WineHQ .app builds,
/// or manually added by the user).
struct WineInstallation: Identifiable, Codable, Hashable {
    var id: String { binaryPath }   // path is a natural unique key
    var label: String               // e.g. "Homebrew Wine Stable", "CrossOver 24"
    var binaryPath: String          // absolute path to the `wine` executable
    var winetricksPath: String?     // absolute path to `winetricks`, if found alongside
}
