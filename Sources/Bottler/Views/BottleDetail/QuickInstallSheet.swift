import SwiftUI
import AppKit

struct QuickInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onDownloaded: (URL, [String], String) -> Void

    @State private var downloadingApp: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Quick Install", systemImage: "arrow.down.app.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.wine)

            Text("Download and install a popular Windows app directly into this bottle.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            List(QuickInstallCatalog.apps) { app in
                HStack(spacing: 12) {
                    Image(systemName: app.iconSystemName)
                        .foregroundStyle(Theme.wine)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name).font(.headline)
                        if let notes = app.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if downloadingApp == app.name {
                        ProgressView().controlSize(.small)
                    } else if app.directDownloadURL != nil {
                        Button("Install") { download(app) }
                            .buttonStyle(.wineProminent)
                    } else {
                        Button("Open Download Page") { openFallback(app) }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 340)

            HStack {
                Spacer()
                Button("Close") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 500, height: 500)
    }

    private func download(_ app: QuickInstallApp) {
        guard let urlString = app.directDownloadURL else { return }
        errorMessage = nil
        downloadingApp = app.name
        Task {
            do {
                let filename = app.installerFilename ?? "\(app.name)-installer.exe"
                let localURL = try await QuickInstallManager.downloadInstaller(
                    from: urlString,
                    suggestedFilename: filename
                ) { _ in }
                downloadingApp = nil
                dismiss()
                onDownloaded(localURL, app.recommendedWinetricksVerbs, app.recommendedLaunchArguments)
            } catch {
                downloadingApp = nil
                errorMessage = "Couldn't download \(app.name) automatically. Opening its download page instead — install manually, then use \"Install Application\" in Bottler."
                openFallback(app)
            }
        }
    }

    private func openFallback(_ app: QuickInstallApp) {
        if let url = URL(string: app.fallbackPageURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
