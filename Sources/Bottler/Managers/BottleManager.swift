import Foundation
import SwiftUI

/// Central app state: the list of known bottles and detected Wine
/// installations, plus operations that mutate them. Persists to disk
/// on every change.
@MainActor
final class BottleManager: ObservableObject {
    @Published var bottles: [Bottle] = []
    @Published var wineInstallations: [WineInstallation] = []
    @Published var selectedBottleID: Bottle.ID?

    var selectedBottle: Bottle? {
        get { bottles.first(where: { $0.id == selectedBottleID }) }
        set {
            guard let newValue else { return }
            update(newValue)
        }
    }

    init() {
        bottles = Persistence.loadBottles()
        wineInstallations = WineDetector.detectInstallations()
        selectedBottleID = bottles.first?.id
    }

    func refreshWineInstallations() {
        wineInstallations = WineDetector.detectInstallations()
    }

    // MARK: - Bottle CRUD

    func createBottle(
        name: String,
        wineInstallation: WineInstallation,
        architecture: Architecture,
        windowsVersion: WindowsVersion
    ) async throws -> Bottle {
        let safeDirName = name.replacingOccurrences(of: "/", with: "-")
        let prefixURL = Persistence.bottlesRootDirectory.appendingPathComponent(safeDirName)

        let bottle = Bottle(
            name: name,
            prefixPath: prefixURL.path,
            wineBinaryPath: wineInstallation.binaryPath,
            architecture: architecture,
            windowsVersion: windowsVersion
        )

        try await WineProcessManager.createPrefix(for: bottle)

        bottles.append(bottle)
        selectedBottleID = bottle.id
        persist()
        return bottle
    }

    func delete(_ bottle: Bottle) throws {
        try WineProcessManager.deletePrefix(for: bottle)
        bottles.removeAll { $0.id == bottle.id }
        if selectedBottleID == bottle.id {
            selectedBottleID = bottles.first?.id
        }
        persist()
    }

    func duplicate(_ bottle: Bottle, newName: String) throws {
        let safeDirName = newName.replacingOccurrences(of: "/", with: "-")
        let newPrefixURL = Persistence.bottlesRootDirectory.appendingPathComponent(safeDirName)
        try FileManager.default.copyItem(atPath: bottle.prefixPath, toPath: newPrefixURL.path)

        var copy = bottle
        copy.id = UUID()
        copy.name = newName
        copy.prefixPath = newPrefixURL.path
        copy.dateCreated = Date()
        bottles.append(copy)
        persist()
    }

    func update(_ bottle: Bottle) {
        guard let index = bottles.firstIndex(where: { $0.id == bottle.id }) else { return }
        bottles[index] = bottle
        persist()
    }

    // MARK: - App CRUD (within a bottle)

    func addApp(_ app: BottleApp, to bottle: Bottle) {
        guard var target = bottles.first(where: { $0.id == bottle.id }) else { return }
        target.apps.append(app)
        update(target)
    }

    func removeApp(_ app: BottleApp, from bottle: Bottle) {
        guard var target = bottles.first(where: { $0.id == bottle.id }) else { return }
        target.apps.removeAll { $0.id == app.id }
        update(target)
    }

    func updateApp(_ app: BottleApp, in bottle: Bottle) {
        guard var target = bottles.first(where: { $0.id == bottle.id }) else { return }
        guard let index = target.apps.firstIndex(where: { $0.id == app.id }) else { return }
        target.apps[index] = app
        update(target)
    }

    private func persist() {
        Persistence.saveBottles(bottles)
    }
}
