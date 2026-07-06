import Foundation
import SwiftUI

/// Shared, observable log buffer. Any long-running Wine/Winetricks operation
/// appends to this so the UI can show a live console.
@MainActor
final class LogStore: ObservableObject {
    static let shared = LogStore()

    @Published var lines: [String] = []
    @Published var isBusy: Bool = false

    func append(_ line: String) {
        lines.append(line)
        if lines.count > 2000 {
            lines.removeFirst(lines.count - 2000)
        }
    }

    func clear() {
        lines.removeAll()
    }
}
