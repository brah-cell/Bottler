# Bottler

A native macOS SwiftUI app for managing Wine bottles: it installs Wine for
you if needed, creates/deletes prefixes, installs Windows applications and
auto-detects + launches them, runs winetricks components, and lets you
rename, edit, or uninstall any tracked program.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ (or just the Xcode Command Line Tools, for `swift build`)
- Wine — **you don't need to install this yourself.** If Bottler doesn't
  find one on first launch, it offers to install Wine + winetricks for you
  via Homebrew (installing Homebrew first, if needed) with a live progress log.

If you'd rather do it manually first:
```bash
brew install --cask wine-stable
brew install winetricks
```

## Building a double-clickable .app (drag to Applications)

Requires only the **Xcode Command Line Tools**, not full Xcode:
```bash
xcode-select --install   # skip if already installed
```

Then:
```bash
cd Bottler
chmod +x build_app.sh
./build_app.sh
```

This runs `swift build -c release`, packages the binary into a proper
`Bottler.app` bundle (with a custom icon baked in via `iconutil`, and
an `Info.plist`), and ad-hoc code-signs it. Drag `Bottler.app` into
`/Applications` (or run the `mv` command it prints for you).

**First launch:** since this isn't signed with a paid Apple Developer ID,
Gatekeeper will flag it as "unidentified developer." Right-click the app →
**Open** the first time instead of double-clicking. One-time step per machine.

## Building for development (Xcode)

**Option A — Swift Package Manager:**
```bash
cd Bottler
swift run
```

**Option B — Xcode:** open the folder (`open Package.swift`), then ⌘R.

## Features

- **Zero-dependency setup** — detects Wine on launch; if missing, installs
  Wine + winetricks automatically via Homebrew (and Homebrew itself, if
  needed) with a live log, no Terminal required.
- **Bottles** — create/duplicate/delete Wine prefixes, choose architecture
  (32/64-bit) and reported Windows version, auto-detects Wine installs from
  Homebrew, CrossOver, and WineHQ builds.
- **Browse the C: drive anytime** — a dedicated Files tab lets you navigate
  the bottle's `drive_c` like a mini Finder: breadcrumb navigation, folder
  drill-down, launch any `.exe` directly, or register it as a tracked app
  on the spot. ("Reveal in Finder" from Overview still works too, for when
  you want the full macOS Finder instead.)
- **Install & auto-launch** — pick an `.exe`/`.msi`; after it installs,
  Bottler diffs the bottle's `drive_c` to find the newly-created
  program automatically. One clear candidate → it's registered and offered
  as "Save & Launch" immediately. Multiple candidates → you pick from a
  short list. None found → falls back to manually browsing for it.
- **Name, edit, and uninstall any program** — every tracked app can be
  renamed, have its launch arguments / environment variable overrides /
  virtual desktop resolution edited at any time, or removed — either just
  untracked, or with its files deleted from the bottle too. There's also a
  one-click "Windows Uninstaller…" that opens Wine's native Add/Remove
  Programs dialog for a fully proper uninstall when a program registers one.
- **Winetricks tab** — checkbox presets for common runtimes/fonts/DirectX
  components (corefonts, VC++ redistributables, .NET, DXVK, etc.), plus a
  free-text field for any other verb.
- **Sleek, single-purpose UI** — a wine-toned accent color, card-style app
  rows, and a custom app icon, rather than default system chrome everywhere.

## How it works

- **Bottles** live under `~/Library/Application Support/Bottler/Bottles/<name>`,
  with a JSON registry at `~/Library/Application Support/Bottler/bottles.json`.
- All Wine invocations (`wineboot`, `winecfg`, `wine <installer.exe>`,
  `wineserver -k`, `winetricks`, `wine uninstaller`) shell out via
  `Shell.swift`, streaming stdout/stderr live into `LogStore` for the
  on-screen console.
- **Auto-detection** (`ExeDiffScanner.swift`) snapshots every `.exe` under
  `drive_c` before and after an install, ignoring system/temp/redist
  folders, and ranks newly-appeared files by size (installers often leave
  small helper/uninstaller exes alongside the real app).
- **Per-app settings**: environment variable overrides (e.g.
  `WINEDLLOVERRIDES=winmm=n,b`), optional virtual desktop resolution, and
  extra launch arguments — stored per app, applied only when that app runs.

## Known v1 limitations / good next steps

- No code signing / notarization — this is ad-hoc signed for local use, not
  Mac App Store or wide distribution.
- Auto-detection after install is heuristic (newest + largest .exe outside
  system folders); unusual installers may need the manual fallback.
- "Delete Files & Remove" only removes the folder containing the tracked
  .exe — it's not a full registry-aware uninstall. Use "Windows
  Uninstaller…" when a program has a real uninstaller registered.
- No drive-letter mapping UI (symlinks to `~/Desktop`, `~/Documents`, etc.) —
  Wine's defaults are used as-is.
- No bundling of Wine/winetricks inside the app itself; it installs them via
  Homebrew on demand rather than shipping its own copy.
