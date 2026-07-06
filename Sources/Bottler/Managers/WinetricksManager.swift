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
}
