import Foundation

/// Scans common locations for Wine installations so the user doesn't have
/// to hunt down binary paths themselves. Also supports manually adding one.
enum WineDetector {

    private static let candidateBinaryPaths: [(label: String, path: String)] = [
        ("Homebrew Wine (Apple Silicon)", "/opt/homebrew/bin/wine"),
        ("Homebrew Wine (Intel)", "/usr/local/bin/wine"),
        ("Homebrew Wine Stable (Apple Silicon)", "/opt/homebrew/bin/wine64"),
        ("Homebrew Wine Stable (Intel)", "/usr/local/bin/wine64"),
        ("CrossOver", "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"),
        ("WineHQ Wine Stable.app", "/Applications/Wine Stable.app/Contents/Resources/wine/bin/wine"),
        ("WineHQ Wine Devel.app", "/Applications/Wine Devel.app/Contents/Resources/wine/bin/wine"),
        ("Wine (Kegworks) Staging.app", "/Applications/Wine Staging.app/Contents/Resources/wine/bin/wine"),
    ]

    private static let candidateWinetricksPaths: [String] = [
        "/opt/homebrew/bin/winetricks",
        "/usr/local/bin/winetricks",
    ]

    static func detectInstallations() -> [WineInstallation] {
        var found: [WineInstallation] = []
        let fm = FileManager.default

        for candidate in candidateBinaryPaths {
            if fm.isExecutableFile(atPath: candidate.path) {
                found.append(
                    WineInstallation(
                        label: candidate.label,
                        binaryPath: candidate.path,
                        winetricksPath: candidateWinetricksPaths.first(where: { fm.isExecutableFile(atPath: $0) })
                    )
                )
            }
        }
        return found
    }

    static func firstAvailableWinetricks() -> String? {
        candidateWinetricksPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }
}
