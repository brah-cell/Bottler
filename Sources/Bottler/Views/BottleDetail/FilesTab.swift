import SwiftUI
import AppKit

struct FileEntry: Identifiable, Hashable {
    var id: String { path }
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int
}

struct FilesTab: View {
    @EnvironmentObject var bottleManager: BottleManager
    let bottle: Bottle

    @State private var currentPath: String
    @State private var entries: [FileEntry] = []
    @State private var errorMessage: String?
    @State private var editingApp: BottleApp?

    init(bottle: Bottle) {
        self.bottle = bottle
        _currentPath = State(initialValue: bottle.driveCPath)
    }

    var body: some View {
        VStack(spacing: 0) {
            breadcrumbBar
            Divider()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .padding()
            }

            List(entries) { entry in
                fileRow(entry)
            }
            .listStyle(.plain)

            Divider()
            HStack {
                Button {
                    goUpOneLevel()
                } label: {
                    Label("Up", systemImage: "arrow.up")
                }
                .disabled(currentPath == bottle.driveCPath)

                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: currentPath))
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }

                Spacer()

                Button {
                    reload()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding(12)
        }
        .onAppear { reload() }
        .sheet(item: $editingApp) { app in
            AppSettingsSheet(bottle: bottle, app: app, autoLaunchOnSave: false, detectionNote: nil)
        }
    }

    // MARK: - Breadcrumbs

    private var breadcrumbBar: some View {
        let relative = currentPath
            .replacingOccurrences(of: bottle.driveCPath, with: "")
            .split(separator: "/")
            .map(String.init)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                breadcrumbButton(label: "C:", targetPath: bottle.driveCPath)
                ForEach(Array(relative.enumerated()), id: \.offset) { index, component in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    let path = bottle.driveCPath + "/" + relative[0...index].joined(separator: "/")
                    breadcrumbButton(label: component, targetPath: path)
                }
            }
            .padding(12)
        }
    }

    private func breadcrumbButton(label: String, targetPath: String) -> some View {
        Button(label) {
            currentPath = targetPath
            reload()
        }
        .buttonStyle(.plain)
        .foregroundStyle(targetPath == currentPath ? Theme.wine : .primary)
        .fontWeight(targetPath == currentPath ? .semibold : .regular)
    }

    // MARK: - Rows

    private func fileRow(_ entry: FileEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.isDirectory ? "folder.fill" : iconName(for: entry.name))
                .foregroundStyle(entry.isDirectory ? Color.accentColor : Theme.wine)
                .frame(width: 20)

            Text(entry.name)

            Spacer()

            if !entry.isDirectory {
                Text(ByteCountFormatter.string(fromByteCount: Int64(entry.size), countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.isDirectory {
                Button("Open") {
                    currentPath = entry.path
                    reload()
                }
                .buttonStyle(.bordered)
            } else if entry.name.lowercased().hasSuffix(".exe") {
                Button("Add…") {
                    editingApp = BottleApp(
                        name: (entry.name as NSString).deletingPathExtension.prettifiedAppName,
                        executablePath: entry.path
                    )
                }
                .buttonStyle(.bordered)

                Button("Launch") {
                    launch(entry)
                }
                .buttonStyle(.wineProminent)
            } else {
                Button("Reveal") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.path)])
                }
                .buttonStyle(.bordered)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if entry.isDirectory {
                currentPath = entry.path
                reload()
            } else if entry.name.lowercased().hasSuffix(".exe") {
                launch(entry)
            }
        }
        .padding(.vertical, 2)
    }

    private func iconName(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "exe": return "app.badge"
        case "dll": return "puzzlepiece"
        case "txt", "log": return "doc.text"
        case "ini", "cfg", "conf": return "gearshape"
        default: return "doc"
        }
    }

    // MARK: - Actions

    private func reload() {
        errorMessage = nil
        let fm = FileManager.default
        do {
            let names = try fm.contentsOfDirectory(atPath: currentPath)
            var result: [FileEntry] = []
            for name in names {
                if name.hasPrefix(".") { continue }
                let fullPath = (currentPath as NSString).appendingPathComponent(name)
                var isDir: ObjCBool = false
                fm.fileExists(atPath: fullPath, isDirectory: &isDir)
                var size = 0
                if !isDir.boolValue {
                    let attrs = try? fm.attributesOfItem(atPath: fullPath)
                    size = (attrs?[.size] as? Int) ?? 0
                }
                result.append(FileEntry(name: name, path: fullPath, isDirectory: isDir.boolValue, size: size))
            }
            entries = result.sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            entries = []
            errorMessage = "Couldn't read this folder: \(error.localizedDescription)"
        }
    }

    private func goUpOneLevel() {
        guard currentPath != bottle.driveCPath else { return }
        currentPath = (currentPath as NSString).deletingLastPathComponent
        reload()
    }

    private func launch(_ entry: FileEntry) {
        let transientApp = BottleApp(name: entry.name, executablePath: entry.path)
        do {
            try WineProcessManager.launch(app: transientApp, in: bottle)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
