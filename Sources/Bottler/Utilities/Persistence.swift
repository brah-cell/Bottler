import Foundation

/// Handles reading/writing the JSON registry of known bottles, and knows
/// where Bottler keeps its application-support data.
enum Persistence {

    static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Bottler", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var bottlesRootDirectory: URL {
        let dir = appSupportDirectory.appendingPathComponent("Bottles", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var registryFile: URL {
        appSupportDirectory.appendingPathComponent("bottles.json")
    }

    static func loadBottles() -> [Bottle] {
        guard let data = try? Data(contentsOf: registryFile) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Bottle].self, from: data)) ?? []
    }

    static func saveBottles(_ bottles: [Bottle]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(bottles) else { return }
        try? data.write(to: registryFile, options: .atomic)
    }
}
