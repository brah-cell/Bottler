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
}

enum QuickInstallCatalog {
    static let apps: [QuickInstallApp] = [
        QuickInstallApp(
            name: "Steam",
            iconSystemName: "gamecontroller.fill",
            directDownloadURL: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe",
            installerFilename: "SteamSetup.exe",
            fallbackPageURL: "https://store.steampowered.com/about/",
            notes: "First launch updates itself — this can take a few minutes under Wine."
        ),
        QuickInstallApp(
            name: "Discord",
            iconSystemName: "message.fill",
            directDownloadURL: "https://discord.com/api/download?platform=win",
            installerFilename: "DiscordSetup.exe",
            fallbackPageURL: "https://discord.com/download",
            notes: nil
        ),
        QuickInstallApp(
            name: "Epic Games Store",
            iconSystemName: "gamecontroller",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://www.epicgames.com/store/download",
            notes: "Opens Epic's page — install the download through Bottler afterward."
        ),
        QuickInstallApp(
            name: "Battle.net",
            iconSystemName: "flame.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://battle.net/download",
            notes: "Opens Blizzard's page — install the download through Bottler afterward."
        ),
        QuickInstallApp(
            name: "VLC Media Player",
            iconSystemName: "play.rectangle.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://www.videolan.org/vlc/download-windows.html",
            notes: "Opens VideoLAN's page — install the download through Bottler afterward."
        ),
        QuickInstallApp(
            name: "7-Zip",
            iconSystemName: "archivebox.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://www.7-zip.org/download.html",
            notes: "Opens 7-Zip's page — install the download through Bottler afterward."
        ),
        QuickInstallApp(
            name: "Notepad++",
            iconSystemName: "doc.text.fill",
            directDownloadURL: nil,
            installerFilename: nil,
            fallbackPageURL: "https://notepad-plus-plus.org/downloads/",
            notes: "Opens Notepad++'s page — install the download through Bottler afterward."
        ),
    ]
}
