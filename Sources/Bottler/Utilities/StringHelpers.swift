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
}
