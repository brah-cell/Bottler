import Foundation

/// Repairs persisted app entries that were created under older Quick Install
/// workarounds — e.g. Steam bottles saved with the v1.1.4 WINEDLLOVERRIDES
/// hack that prevented steamwebhelper from starting at all.
enum QuickInstallMigration {

    static func migrate(_ bottle: Bottle) -> Bottle {
        var copy = bottle
        copy.apps = bottle.apps.map { migrateApp($0) }
        return copy
    }

    static func migrateApp(_ app: BottleApp) -> BottleApp {
        guard isSteamApp(app) else { return app }

        var app = app

        // v1.1.4 set WINEDLLOVERRIDES=steamwebhelper.exe= which blocks the
        // component entirely and triggers the "not responding" dialog.
        if let overrides = app.envOverrides["WINEDLLOVERRIDES"],
           overrides.localizedCaseInsensitiveContains("steamwebhelper") {
            app.envOverrides.removeValue(forKey: "WINEDLLOVERRIDES")
        }

        app.arguments = ensureLaunchFlags(
            in: app.arguments,
            required: ["-cef-disable-sandbox", "-no-cef-sandbox"]
        )
        return app
    }

    static func bottlesNeedMigration(_ bottles: [Bottle]) -> Bool {
        bottles.contains { bottle in
            bottle.apps.contains { app in
                migrateApp(app) != app
            }
        }
    }

    private static func isSteamApp(_ app: BottleApp) -> Bool {
        if app.name.localizedCaseInsensitiveContains("steam") { return true }
        let lower = app.executablePath.lowercased()
        return lower.contains("/steam/") || lower.hasSuffix("\\steam.exe")
    }

    private static func ensureLaunchFlags(in arguments: String, required: [String]) -> String {
        var args = arguments.splitRespectingQuotes()
        for flag in required where !args.contains(flag) {
            args.append(flag)
        }
        return args.joined(separator: " ")
    }
}
