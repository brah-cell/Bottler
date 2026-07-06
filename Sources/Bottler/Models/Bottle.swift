import Foundation

enum Architecture: String, Codable, CaseIterable, Identifiable {
    case win32
    case win64

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .win32: return "32-bit"
        case .win64: return "64-bit"
        }
    }
}

enum WindowsVersion: String, Codable, CaseIterable, Identifiable {
    case win11 = "win11"
    case win10 = "win10"
    case win7  = "win7"
    case winxp = "winxp"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .win11: return "Windows 11"
        case .win10: return "Windows 10"
        case .win7:  return "Windows 7"
        case .winxp: return "Windows XP"
        }
    }
}

/// A single Wine prefix ("bottle") along with the metadata Bottler
/// needs to operate on it.
struct Bottle: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var prefixPath: String          // absolute path to the WINEPREFIX directory
    var wineBinaryPath: String      // absolute path to the `wine` binary used for this bottle
    var architecture: Architecture
    var windowsVersion: WindowsVersion = .win10
    var apps: [BottleApp] = []
    var dateCreated: Date = Date()

    /// Convenience: drive_c path inside the prefix.
    var driveCPath: String {
        (prefixPath as NSString).appendingPathComponent("drive_c")
    }
}
