import SwiftUI

/// A scrolling monospaced console, bound to the shared LogStore, used to
/// show live output from installers / winetricks / prefix creation.
struct LogConsoleView: View {
    @ObservedObject var logStore = LogStore.shared

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(logStore.lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: logStore.lines.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(logStore.lines.count - 1, anchor: .bottom)
                }
            }
        }
    }
}
