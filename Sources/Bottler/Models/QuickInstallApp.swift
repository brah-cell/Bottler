import Foundation

/// A popular Windows app Bottler can help install. Apps with a
/// `directDownloadURL` get downloaded and installed with one click.
/// Apps without one (because a hardcoded binary URL wouldn't be safe to
/// rely on — Bottler shouldn't ship a link that quietly goes stale) just
/// open the vendor's official download page instead; the person downloads
/// it once, and can install it through Bottler's normal "Install
/// Application" flow afterward.
struct QuickInstallApp: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let iconSystemName: String
    let directDownloadURL: String?
    let installerFilename: String?   // only meaningful when directDownloadURL is set
    let fallbackPageURL: String
    let notes: String?
    /// winetricks components this app is known to need to install/run
    /// reliably under Wine. Applied automatically before the installer
    /// runs, so the person doesn't hit a hang or crash from a missing
    /// prerequisite on first launch.
    let recommendedWinetricksVerbs: [String]
    /// Extra launch arguments known to be needed for this app to actually
    /// work under Wine (e.g. a flag disabling a specific broken subsystem).
    /// Applied automatically to the app entry Bottler creates after install.
    let recommendedLaunchArguments: String
}

enum QuickInstallCatalog {
    static let apps: [QuickInstallApp] = [
        QuickInstallApp(
            name: "Steam",
            iconSystemName: "gamecontroller.fill",
            directDownloadURL: "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe",
            installerFilename: "SteamSetup.exe",
            fallbackPageURL: "https://store.steampowered.com/about/",
            notes: "Steam already has a native Mac app — only install this Windows version if you need Windows-only games or anti-cheat that doesn't support the Mac client. Bottler applies Steam's known Wine prerequisites automatically first, to avoid the common freeze on first launch.",
            recommendedWinetricksVerbs: ["corefonts", "vcrun2019", "d3dx9", "gdiplus"],
            // Steam's newer UI runs its Chromium component (steamwebhelper)
            // sandboxed, and Wine doesn't support the sandboxing syscalls it
            // needs — the well-documented result is a "steamwebhelper is not
            // responding" dialog or a black window. -cef-disable-sandbox is
            // Valve's own supported flag for exactly this scenario (also
            // used on Linux/Proton for the same underlying reason). Trade-off:
            // it disables Chromium's sandboxing, which is an acceptable
            // security trade for a single-user Wine bottle.
            recommendedLaunchArguments: "-cef-disable-sandbox"
        ),
        QuickInstallApp(
            name: "Discord",
            iconSystemName: "message.fill",
            directDownloadURL: "https://discord.com/api/download?platform=win",
            installerFilename: "DiscordSetup.exe",
            fallbackPageURL: "https://discord.com/download",
            notes: nil,
            recommendedWinetricksVerbs: ["corefonts", "vcrun2019"],
            recommendedLaunchArguments: ""
        ),
        QuickInstallApp(
            name: "Epic Games Store",
            iconSystemName: "gamecontroller",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://www.epicgames.com/store/download",
            notes: "Opens Epic's page — install the download through Bottler afterward.",
            recommendedWinetricksVerbs: ["corefonts", "vcrun2019", "d3dx9"],
            recommendedLaunchArguments: ""
        ),
        QuickInstallApp(
            name: "Battle.net",
            iconSystemName: "flame.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://battle.net/download",
            notes: "Opens Blizzard's page — install the download through Bottler afterward.",
            recommendedWinetricksVerbs: ["corefonts", "vcrun2019", "d3dx9"],
            recommendedLaunchArguments: ""
        ),
        QuickInstallApp(
            name: "VLC Media Player",
            iconSystemName: "play.rectangle.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://www.videolan.org/vlc/download-windows.html",
            notes: "Opens VideoLAN's page — install the download through Bottler afterward.",
            recommendedWinetricksVerbs: [],
            recommendedLaunchArguments: ""
        ),
        QuickInstallApp(
            name: "7-Zip",
            iconSystemName: "archivebox.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://www.7-zip.org/download.html",
            notes: "Opens 7-Zip's page — install the download through Bottler afterward.",
            recommendedWinetricksVerbs: [],
            recommendedLaunchArguments: ""
        ),
        QuickInstallApp(
            name: "Notepad++",
            iconSystemName: "doc.text.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://notepad-plus-plus.org/downloads/",
            notes: "Opens Notepad++'s page — install the download through Bottler afterward.",
            recommendedWinetricksVerbs: [],
            recommendedLaunchArguments: ""
        ),
    ]
}
