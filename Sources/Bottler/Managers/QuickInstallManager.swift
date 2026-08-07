import Foundation

/// Downloads an installer file for the Quick Install catalog. Uses `curl`
/// directly (no shell interpolation risk, no admin/sudo needed — this is
/// plain network access) and fails loudly with `--fail` so a bad/expired
/// link is reported as an error instead of silently saving an HTML error
/// page as if it were the installer.
enum QuickInstallManager {

    static func downloadInstaller(
        from urlString: String,
        suggestedFilename: String,
        onOutput: @escaping (String) -> Void
    ) async throws -> URL {
        guard URL(string: urlString) != nil else {
            throw QuickInstallError.invalidURL
        }

        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
        try? FileManager.default.removeItem(at: destURL)

        onOutput("Downloading \(suggestedFilename)…")
        try await Shell.run(
            "/usr/bin/curl",
            arguments: ["-L", "-sS", "--fail", "-o", destURL.path, urlString],
            onOutput: onOutput
        )

        guard FileManager.default.fileExists(atPath: destURL.path) else {
            throw QuickInstallError.downloadFailed
        }
        return destURL
    }

    /// Deletes stale per-user folders (e.g. SquirrelTemp) left over from a
    /// prior failed install attempt. Squirrel-based installers like Discord
    /// commonly fail with a generic "Installation has failed" when these
    /// directories contain corrupted partial state.
    static func cleanupStaleInstallState(
        relativePaths: [String],
        in bottle: Bottle,
        onOutput: @escaping (String) -> Void
    ) {
        let usersRoot = (bottle.driveCPath as NSString).appendingPathComponent("users")
        guard FileManager.default.fileExists(atPath: usersRoot) else { return }

        guard let userEntries = try? FileManager.default.contentsOfDirectory(atPath: usersRoot) else {
            return
        }

        for userName in userEntries where userName != "Public" && !userName.hasPrefix(".") {
            let profileRoot = (usersRoot as NSString).appendingPathComponent(userName)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: profileRoot, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }

            for relativePath in relativePaths {
                let target = (profileRoot as NSString).appendingPathComponent(relativePath)
                guard FileManager.default.fileExists(atPath: target) else { continue }
                onOutput("Removing stale \(relativePath) from a prior install attempt…")
                try? FileManager.default.removeItem(atPath: target)
            }
        }
    }

    /// Reads Squirrel.Windows setup logs after a failed Discord (or other
    /// Squirrel) install so the real error shows up in Bottler's log console
    /// instead of only the installer's generic dialog.
    static func readSquirrelInstallLog(in bottle: Bottle) -> String? {
        let usersRoot = (bottle.driveCPath as NSString).appendingPathComponent("users")
        guard let userEntries = try? FileManager.default.contentsOfDirectory(atPath: usersRoot) else {
            return nil
        }

        let logNames = ["SquirrelSetup.log", "Squirrel-Install.log"]
        for userName in userEntries where userName != "Public" && !userName.hasPrefix(".") {
            let squirrelTemp = (usersRoot as NSString)
                .appendingPathComponent(userName)
                .appending("/AppData/Local/SquirrelTemp")
            for logName in logNames {
                let logPath = (squirrelTemp as NSString).appendingPathComponent(logName)
                guard let content = try? String(contentsOfFile: logPath, encoding: .utf8),
                      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continue
                }
                return content
            }
        }
        return nil
    }

    enum QuickInstallError: Error, LocalizedError {
        case invalidURL
        case downloadFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "That download link looks invalid."
            case .downloadFailed:
                return "The download didn't complete."
            }
        }
    }
}
