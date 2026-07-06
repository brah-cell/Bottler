import Foundation

/// A Windows application installed inside a particular bottle, plus any
/// per-app overrides the user wants applied only when launching it.
struct BottleApp: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var executablePath: String       // absolute path, typically under the bottle's drive_c
    var arguments: String = ""
    var envOverrides: [String: String] = [:]   // e.g. ["WINEDLLOVERRIDES": "winmm=n,b"]
    var virtualDesktopResolution: String?      // e.g. "1024x768"; nil = disabled
    var dateAdded: Date = Date()
}
