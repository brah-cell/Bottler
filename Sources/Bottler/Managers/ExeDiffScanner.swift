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
    private static let ignoredPathFragments = [
        "/windows/",
        "/programdata/",
        "/users/",
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
            .sorted { $0.fileSize > $1.fileSize }
    }
}
