import SwiftUI

struct DetectedAppPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let candidates: [ExeDiffScanner.Candidate]
    let onPick: (ExeDiffScanner.Candidate) -> Void
    var onManualFallback: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which program did that install?")
                .font(.title2.weight(.semibold))
            Text("The installer created more than one .exe. Pick the one that launches the actual program — usually the largest, or the one whose name matches what you installed.")
                .font(.callout)
                .foregroundStyle(.secondary)

            List(candidates, id: \.path) { candidate in
                Button {
                    onPick(candidate)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "app.badge")
                        VStack(alignment: .leading) {
                            Text((candidate.path as NSString).lastPathComponent)
                                .font(.headline)
                            Text(candidate.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: Int64(candidate.fileSize), countStyle: .file))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 240)

            HStack {
                Spacer()
                Button("None of these — I'll choose manually") {
                    dismiss()
                    onManualFallback()
                }
            }
        }
        .padding(24)
        .frame(width: 520, height: 420)
    }
}
