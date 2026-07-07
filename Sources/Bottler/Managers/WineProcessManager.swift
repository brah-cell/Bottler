import Foundation

/// All interactions with the `wine` binary itself: creating prefixes,
/// running installers, launching apps and helper tools (winecfg, explorer,
/// cmd), and tearing down wineserver processes.
enum WineProcessManager {

    /// Base environment every Wine invocation for a bottle needs.
    private static func baseEnvironment(for bottle: Bottle) -> [String: String] {
        [
            "WINEPREFIX": bottle.prefixPath,
            "WINEARCH": bottle.architecture.rawValue,
            "WINEDEBUG": "-all"
        ]
    }

    /// Initializes a brand-new Wine prefix on disk. This is what actually
    /// creates the `drive_c` folder etc. via `wineboot --init`.
    static func createPrefix(for bottle: Bottle) async throws {
        try FileManager.default.createDirectory(
            atPath: bottle.prefixPath, withIntermediateDirectories: true
        )
        let wineboot = (bottle.wineBinaryPath as NSString).deletingLastPathComponent
            .appending("/wineboot")
        let bootBinary = FileManager.default.isExecutableFile(atPath: wineboot)
            ? wineboot
            : bottle.wineBinaryPath  // fall back to `wine wineboot`

        let args = bootBinary == bottle.wineBinaryPath ? ["wineboot", "--init"] : ["--init"]

        try await Shell.run(
            bootBinary,
            arguments: args,
            environment: baseEnvironment(for: bottle)
        ) { line in
            Task { @MainActor in LogStore.shared.append(line) }
        }

        try await setWindowsVersion(bottle.windowsVersion, for: bottle)
    }

    /// Sets the reported Windows version for a bottle via `winecfg /v`.
    static func setWindowsVersion(_ version: WindowsVersion, for bottle: Bottle) async throws {
        let winecfg = (bottle.wineBinaryPath as NSString).deletingLastPathComponent
            .appending("/winecfg")
        guard FileManager.default.isExecutableFile(atPath: winecfg) else { return }
        try await Shell.run(
            winecfg,
            arguments: ["/v", version.rawValue],
            environment: baseEnvironment(for: bottle)
        ) { line in
            Task { @MainActor in LogStore.shared.append(line) }
        }
    }

    /// Opens the winecfg GUI for the bottle (detached — user closes it manually).
    static func openWinecfg(for bottle: Bottle) throws {
        let winecfg = (bottle.wineBinaryPath as NSString).deletingLastPathComponent
            .appending("/winecfg")
        let binary = FileManager.default.isExecutableFile(atPath: winecfg) ? winecfg : bottle.wineBinaryPath
        let args = binary == bottle.wineBinaryPath ? ["winecfg"] : []
        try Shell.launchDetached(binary, arguments: args, environment: baseEnvironment(for: bottle))
    }

    /// Opens Windows Explorer within the bottle, rooted at drive_c.
    static func openExplorer(for bottle: Bottle) throws {
        try Shell.launchDetached(
            bottle.wineBinaryPath,
            arguments: ["explorer", bottle.driveCPath],
            environment: baseEnvironment(for: bottle)
        )
    }

    /// Opens a Wine console (cmd.exe) within the bottle.
    static func openConsole(for bottle: Bottle) throws {
        try Shell.launchDetached(
            bottle.wineBinaryPath,
            arguments: ["cmd"],
            environment: baseEnvironment(for: bottle)
        )
    }

    /// Runs a Windows installer (.exe/.msi) inside the bottle, streaming
    /// output live so the UI can show install progress/errors.
    static func runInstaller(
        _ installerPath: String,
        in bottle: Bottle,
        extraArguments: [String] = [],
        onOutput: @escaping (String) -> Void
    ) async throws {
        var args: [String]
        // Wine can't directly execute a .msi the way it does a .exe — it
        // needs to be handed to msiexec explicitly, or the installer
        // silently does nothing.
        if (installerPath as NSString).pathExtension.lowercased() == "msi" {
            args = ["msiexec", "/i", installerPath]
        } else {
            args = [installerPath]
        }
        args.append(contentsOf: extraArguments)
        try await Shell.run(
            bottle.wineBinaryPath,
            arguments: args,
            environment: baseEnvironment(for: bottle),
            onOutput: onOutput
        )
    }

    /// Launches an already-installed app, applying any per-app overrides
    /// (env vars, virtual desktop, extra arguments).
    static func launch(app: BottleApp, in bottle: Bottle) throws {
        var env = baseEnvironment(for: bottle)
        for (key, value) in app.envOverrides {
            env[key] = value
        }

        var args: [String] = []
        if let resolution = app.virtualDesktopResolution, !resolution.isEmpty {
            args.append(contentsOf: ["explorer", "/desktop=\(app.name),\(resolution)", app.executablePath])
        } else {
            args.append(app.executablePath)
        }
        if !app.arguments.isEmpty {
            args.append(contentsOf: app.arguments.splitRespectingQuotes())
        }

        try Shell.launchDetached(bottle.wineBinaryPath, arguments: args, environment: env)
    }

    /// Kills all wine processes associated with a bottle via `wineserver -k`.
    static func killProcesses(for bottle: Bottle) async throws {
        let wineserver = (bottle.wineBinaryPath as NSString).deletingLastPathComponent
            .appending("/wineserver")
        guard FileManager.default.isExecutableFile(atPath: wineserver) else { return }
        try await Shell.run(
            wineserver,
            arguments: ["-k"],
            environment: baseEnvironment(for: bottle)
        ) { line in
            Task { @MainActor in LogStore.shared.append(line) }
        }
    }

    /// Deletes a bottle's prefix directory entirely. Irreversible.
    static func deletePrefix(for bottle: Bottle) throws {
        if FileManager.default.fileExists(atPath: bottle.prefixPath) {
            try FileManager.default.removeItem(atPath: bottle.prefixPath)
        }
    }
}
