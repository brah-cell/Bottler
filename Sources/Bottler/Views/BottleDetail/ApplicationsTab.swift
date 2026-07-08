import SwiftUI
import UniformTypeIdentifiers

struct ApplicationsTab: View {
    @EnvironmentObject var bottleManager: BottleManager
    let bottle: Bottle

    @State private var showingInstaller = false
    @State private var showingQuickInstall = false
    @State private var showingLogSheet = false
    @State private var editingApp: BottleApp?
    @State private var editingAutoLaunch = false
    @State private var editingDetectionNote: String?
    @State private var errorMessage: String?
    @State private var isInstalling = false

    @State private var detectedCandidates: [ExeDiffScanner.Candidate] = []
    @State private var showingDetectedPicker = false
    @State private var pendingAppName = ""
    @State private var pendingEnvOverrides: [String: String] = [:]

    @State private var appPendingUninstall: BottleApp?
    @State private var showingUninstallDialog = false

    var body: some View {
        VStack(spacing: 0) {
            if bottle.apps.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(bottle.apps) { app in
                            appRow(app)
                        }
                    }
                    .padding(16)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .padding(.horizontal)
            }

            Divider()

            HStack {
                Button {
                    showingInstaller = true
                } label: {
                    Label(isInstalling ? "Installing…" : "Install Application…", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.wineProminent)
                .disabled(isInstalling)

                Button {
                    showingQuickInstall = true
                } label: {
                    Label("Quick Install…", systemImage: "arrow.down.app.fill")
                }
                .disabled(isInstalling)

                if isInstalling {
                    ProgressView().controlSize(.small).padding(.leading, 4)
                }

                Spacer()

                Button {
                    openWindowsUninstaller()
                } label: {
                    Label("Windows Uninstaller…", systemImage: "trash.square")
                }
                .help("Opens Wine's native Add/Remove Programs dialog for this bottle")

                Button {
                    showingLogSheet = true
                } label: {
                    Label("Log", systemImage: "terminal")
                }
            }
            .padding(16)
        }
        .fileImporter(
            isPresented: $showingInstaller,
            allowedContentTypes: [UTType(filenameExtension: "exe") ?? .exe, UTType(filenameExtension: "msi") ?? .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { install(installerURL: url) }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $editingApp) { app in
            AppSettingsSheet(
                bottle: bottle,
                app: app,
                autoLaunchOnSave: editingAutoLaunch,
                detectionNote: editingDetectionNote
            )
        }
        .sheet(isPresented: $showingDetectedPicker) {
            DetectedAppPickerSheet(
                candidates: detectedCandidates,
                onPick: { candidate in
                    openEditor(
                        for: candidate.path,
                        suggestedName: (candidate.path as NSString).lastPathComponent
                            .replacingOccurrences(of: ".exe", with: "", options: .caseInsensitive)
                            .prettifiedAppName,
                        autoLaunch: true,
                        note: "Detected automatically after install."
                    )
                },
                onManualFallback: {
                    openEditor(for: "", suggestedName: pendingAppName, autoLaunch: false, note: nil)
                }
            )
        }
        .sheet(isPresented: $showingQuickInstall) {
            QuickInstallSheet { downloadedURL, prerequisiteVerbs, envOverrides in
                install(installerURL: downloadedURL, prerequisiteVerbs: prerequisiteVerbs, envOverrides: envOverrides)
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            VStack(alignment: .leading) {
                Text("Log").font(.title2.weight(.semibold)).padding([.top, .horizontal])
                LogConsoleView()
                HStack {
                    Spacer()
                    Button("Close") { showingLogSheet = false }
                }
                .padding()
            }
            .frame(width: 640, height: 420)
        }
        .confirmationDialog(
            appPendingUninstall.map { "Uninstall \u{201c}\($0.name)\u{201d}?" } ?? "Uninstall",
            isPresented: $showingUninstallDialog,
            titleVisibility: .visible
        ) {
            if let app = appPendingUninstall {
                Button("Delete Files & Remove", role: .destructive) {
                    deleteFilesAndRemove(app)
                }
                Button("Remove from List Only", role: .destructive) {
                    bottleManager.removeApp(app, from: bottle)
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            Text("\"Remove from List Only\" just stops Bottler from tracking it. \"Delete Files & Remove\" also deletes its folder from the bottle.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Applications Yet")
                .font(.title3.weight(.medium))
            Text("Install a Windows .exe or .msi to get started — Bottler will detect the installed program and offer to launch it automatically.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func appRow(_ app: BottleApp) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.wine.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "app.badge.fill")
                    .foregroundStyle(Theme.wine)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.headline)
                Text(app.executablePath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button("Edit…") {
                editingAutoLaunch = false
                editingDetectionNote = nil
                editingApp = app
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                appPendingUninstall = app
                showingUninstallDialog = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)

            Button("Launch") { launch(app) }
                .buttonStyle(.wineProminent)
        }
        .card()
    }

    private func install(installerURL: URL, prerequisiteVerbs: [String] = [], envOverrides: [String: String] = [:]) {
        showingLogSheet = true
        errorMessage = nil
        isInstalling = true
        LogStore.shared.clear()
        pendingAppName = installerURL.deletingPathExtension().lastPathComponent.prettifiedAppName
        pendingEnvOverrides = envOverrides

        Task {
            if !prerequisiteVerbs.isEmpty {
                if let winetricksPath = bottleManager.wineInstallations
                    .first(where: { $0.binaryPath == bottle.wineBinaryPath })?.winetricksPath
                    ?? WineDetector.firstAvailableWinetricks() {
                    LogStore.shared.append("Installing prerequisites this app needs (\(prerequisiteVerbs.joined(separator: ", ")))…")
                    do {
                        try await WinetricksManager.run(
                            verbs: prerequisiteVerbs,
                            in: bottle,
                            winetricksPath: winetricksPath
                        ) { line in
                            Task { @MainActor in LogStore.shared.append(line) }
                        }
                    } catch {
                        // Prerequisites are a best-effort head start, not a hard
                        // requirement — log it and still attempt the install,
                        // rather than blocking the person entirely.
                        LogStore.shared.append("Couldn't install prerequisites automatically (\(error.localizedDescription)) — continuing with the install anyway.")
                    }
                } else {
                    LogStore.shared.append("winetricks isn't installed, so prerequisites were skipped. Install it from the Winetricks tab, then reinstall this app if it doesn't run correctly.")
                }
            }

            let before = ExeDiffScanner.snapshot(root: bottle.driveCPath)
            do {
                try await WineProcessManager.runInstaller(installerURL.path, in: bottle) { line in
                    Task { @MainActor in LogStore.shared.append(line) }
                }
            } catch {
                errorMessage = error.localizedDescription
                isInstalling = false
                return
            }
            let after = ExeDiffScanner.snapshot(root: bottle.driveCPath)
            let candidates = ExeDiffScanner.rankedNewCandidates(before: before, after: after)
            isInstalling = false

            switch candidates.count {
            case 0:
                openEditor(for: "", suggestedName: pendingAppName, autoLaunch: false,
                           note: "Couldn't auto-detect the installed program \u{2014} choose its .exe below.")
            case 1:
                let candidate = candidates[0]
                openEditor(
                    for: candidate.path,
                    suggestedName: (candidate.path as NSString).lastPathComponent
                        .replacingOccurrences(of: ".exe", with: "", options: .caseInsensitive)
                        .prettifiedAppName,
                    autoLaunch: true,
                    note: "Detected automatically after install."
                )
            default:
                detectedCandidates = candidates
                showingDetectedPicker = true
            }
        }
    }

    private func openEditor(for executablePath: String, suggestedName: String, autoLaunch: Bool, note: String?) {
        editingAutoLaunch = autoLaunch
        editingDetectionNote = note
        var app = BottleApp(name: suggestedName, executablePath: executablePath)
        app.envOverrides = pendingEnvOverrides
        editingApp = app
    }

    private func launch(_ app: BottleApp) {
        do {
            try WineProcessManager.launch(app: app, in: bottle)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteFilesAndRemove(_ app: BottleApp) {
        let folder = (app.executablePath as NSString).deletingLastPathComponent
        // Safety: only auto-delete if the folder lives inside this bottle's drive_c.
        if folder.hasPrefix(bottle.driveCPath), FileManager.default.fileExists(atPath: folder) {
            try? FileManager.default.removeItem(atPath: folder)
        }
        bottleManager.removeApp(app, from: bottle)
    }

    private func openWindowsUninstaller() {
        do {
            try Shell.launchDetached(
                bottle.wineBinaryPath,
                arguments: ["uninstaller"],
                environment: ["WINEPREFIX": bottle.prefixPath, "WINEARCH": bottle.architecture.rawValue]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension UTType {
    static var exe: UTType { UTType(importedAs: "com.microsoft.windows-executable") }
}
