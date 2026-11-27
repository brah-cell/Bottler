import Foundation

/// Detects which new .exe was just installed by diffing the bottle's
/// drive_c before and after an installer runs. Not perfect — installers
/// vary — but handles the common case automatically instead of always
/// asking the user to browse for it.
enum ExeDiffScanner {

    struct Candidate {
        let path: String
        let fileSize: Int
    }

    /// Directories under drive_c that are never the "real" app (system
    /// noise, temp files, shared redistributables).
    ///
    /// Note: `/users/` as a whole is deliberately NOT ignored. Per-user
    /// installers (Discord and most other Electron/Squirrel apps) install
    /// into `users/<name>/AppData/Local`, and ignoring it meant the real
    /// app was never detected.
    private static let ignoredPathFragments = [
        "/windows/",
        "/programdata/",
        "/users/public/",
        "/squirreltemp/",
        "/appdata/local/temp/",
        "/temp/",
        "/tmp/",
        "/common files/",
        "/microsoft shared/",
        "/installshield installation information/",
        "/redist/",
    ]

    /// Snapshots every .exe under `root`, keyed by path, with its size —
    /// used both before and after running an installer.
    static func snapshot(root: String) -> [String: Int] {
        var result: [String: Int] = [:]
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: root),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return result }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "exe" else { continue }
            let lowerPath = fileURL.path.lowercased()
            if ignoredPathFragments.contains(where: { lowerPath.contains($0) }) { continue }
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            result[fileURL.path] = size
        }
        return result
    }

    /// Compares before/after snapshots and ranks the plausible "main app"
    /// candidates: newly-appeared exe files, largest first (installers
    /// often drop small helper/uninstaller exes alongside the real app).
    static func rankedNewCandidates(before: [String: Int], after: [String: Int]) -> [Candidate] {
        let newPaths = Set(after.keys).subtracting(before.keys)
        return newPaths
            .map { Candidate(path: $0, fileSize: after[$0] ?? 0) }
            .sorted { lhs, rhs in
                let lhsHelper = isLikelyHelper(lhs.path)
                let rhsHelper = isLikelyHelper(rhs.path)
                if lhsHelper != rhsHelper { return !lhsHelper }
                return lhs.fileSize > rhs.fileSize
            }
    }

    /// Executables installers commonly drop next to the real app that are
    /// never what the person wants to launch. They stay in the list (just
    /// ranked last) in case the guess is wrong.
    private static let helperNameFragments = [
        "unins", "uninstall", "update", "updater", "setup", "crashpad",
        "crashhandler", "crashreporter", "helper", "squirrel", "elevate",
    ]

    private static func isLikelyHelper(_ path: String) -> Bool {
        let name = (path as NSString).lastPathComponent.lowercased()
        return helperNameFragments.contains { name.contains($0) }
    }

    /// Squirrel.Windows apps (Discord, Slack, Teams, and others) install the
    /// real program into a versioned folder like `Discord/app-1.0.9035/`
    /// and delete that folder on their next update, so a saved path to
    /// `app-1.0.9035/Discord.exe` stops existing. The stable entry point
    /// is `Update.exe --processStart Discord.exe` one folder up.
    ///
    /// Returns the launcher path and argument string to use instead, or nil
    /// if `path` isn't inside a Squirrel install. `extraAppArguments` are
    /// forwarded to the real app via `--process-start-args`.
    static func squirrelLauncher(for path: String, extraAppArguments: String) -> (executablePath: String, arguments: String)? {
        let appFolder = (path as NSString).deletingLastPathComponent
        guard (appFolder as NSString).lastPathComponent.lowercased().hasPrefix("app-") else { return nil }

        let installRoot = (appFolder as NSString).deletingLastPathComponent
        let updateExe = (installRoot as NSString).appendingPathComponent("Update.exe")
        guard FileManager.default.fileExists(atPath: updateExe) else { return nil }

        let exeName = (path as NSString).lastPathComponent
        var arguments = "--processStart \"\(exeName)\""
        let trimmed = extraAppArguments.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            arguments += " --process-start-args \"\(trimmed)\""
        }
        return (updateExe, arguments)
    }
}
