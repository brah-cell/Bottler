import Foundation

extension String {
    /// Turns a raw filename stem like "MyGame_Setup-x64" into a friendlier
    /// display name like "MyGame Setup x64", used as a starting suggestion
    /// the user can still rename.
    var prettifiedAppName: String {
        let replaced = self
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let collapsed = replaced.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.isEmpty ? self : collapsed
    }

    /// Splits a launch-arguments string into individual arguments,
    /// respecting double-quoted sections so a value like
    /// `--config "C:\Program Files\thing"` becomes two arguments, not five.
    /// Simple by design (no escape-character support) — good enough for the
    /// common "one quoted path" case without pulling in a full shell lexer.
    func splitRespectingQuotes() -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        for character in self {
            if character == "\"" {
                insideQuotes.toggle()
            } else if character == " " && !insideQuotes {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}
