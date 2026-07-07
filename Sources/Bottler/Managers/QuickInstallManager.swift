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
