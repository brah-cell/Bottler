import Foundation

/// A single winetricks "verb" (a package/component it can install), grouped
/// for display as checkboxes in the UI.
struct WinetricksPreset: Identifiable, Hashable {
    var id: String { verb }
    let verb: String
    let label: String
    let category: String
}

enum WinetricksManager {

    static let presets: [WinetricksPreset] = [
        .init(verb: "corefonts", label: "Core Fonts", category: "Fonts"),
        .init(verb: "tahoma", label: "Tahoma Font", category: "Fonts"),
        .init(verb: "vcrun2015", label: "Visual C++ 2015", category: "Runtimes"),
        .init(verb: "vcrun2019", label: "Visual C++ 2019", category: "Runtimes"),
        .init(verb: "dotnet48", label: ".NET Framework 4.8", category: "Runtimes"),
        .init(verb: "dotnet6", label: ".NET 6", category: "Runtimes"),
        .init(verb: "d3dx9", label: "DirectX 9 (d3dx9)", category: "Graphics"),
        .init(verb: "d3dx11_43", label: "DirectX 11 (d3dx11)", category: "Graphics"),
        .init(verb: "dxvk", label: "DXVK (D3D9/10/11 → Vulkan)", category: "Graphics"),
        .init(verb: "gdiplus", label: "GDI+", category: "Graphics"),
        .init(verb: "riched20", label: "Rich Edit Control", category: "Misc"),
        .init(verb: "msxml6", label: "MSXML 6", category: "Misc"),
    ]

    /// Runs one or more winetricks verbs against a bottle, streaming output.
    static func run(
        verbs: [String],
        in bottle: Bottle,
        winetricksPath: String,
        onOutput: @escaping (String) -> Void
    ) async throws {
        guard !verbs.isEmpty else { return }
        await ensureDependenciesInstalled(onOutput: onOutput)
        try await Shell.run(
            winetricksPath,
            arguments: ["--unattended"] + verbs,
            environment: [
                "WINEPREFIX": bottle.prefixPath,
                "WINEARCH": bottle.architecture.rawValue,
                "WINE": bottle.wineBinaryPath
            ],
            onOutput: onOutput
        )
    }

    /// winetricks relies on a couple of command-line tools — `cabextract`
    /// and `7z` (from p7zip) — to unpack the font/runtime packages it
    /// downloads. Neither ships with macOS, and `brew install winetricks`
    /// doesn't pull them in automatically either, so without this,
    /// winetricks silently prints "Cannot find cabextract" and skips the
    /// component instead of installing it. These are plain Homebrew
    /// formulae (not casks with a pkg installer), so installing them
    /// doesn't need `sudo` and can run headlessly — no Terminal required.
    private static func ensureDependenciesInstalled(onOutput: @escaping (String) -> Void) async {
        guard let brew = WineSetupManager.brewPath else { return }
        let requiredTools = [
            (command: "cabextract", formula: "cabextract"),
            (command: "7z", formula: "p7zip"),
        ]
        for tool in requiredTools {
            let alreadyInstalled = ["/opt/homebrew/bin/\(tool.command)", "/usr/local/bin/\(tool.command)"]
                .contains(where: { FileManager.default.isExecutableFile(atPath: $0) })
            guard !alreadyInstalled else { continue }
            onOutput("Installing \(tool.formula) (a tool winetricks needs to unpack its downloads)…")
            try? await Shell.run(brew, arguments: ["install", tool.formula], onOutput: onOutput)
        }
    }
}
