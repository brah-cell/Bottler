import SwiftUI

/// Shared visual identity: a wine-toned accent plus a few reusable
/// view modifiers so every screen feels like one designed product
/// instead of default-system-everything.
enum Theme {
    static let wine = Color(red: 0.60, green: 0.16, blue: 0.28)         // deep burgundy
    static let wineDark = Color(red: 0.29, green: 0.07, blue: 0.15)     // near-black plum
    static let gold = Color(red: 0.80, green: 0.66, blue: 0.42)         // muted gold accent

    static var cardBackground: some ShapeStyle {
        Color(nsColor: .controlBackgroundColor)
    }
}

/// A rounded "card" container used for grouped content throughout the app,
/// instead of raw system Forms everywhere.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// A subtle badge/pill, used for status labels like "Ready" / "Not Installed".
struct PillLabel: View {
    let text: String
    var color: Color = Theme.wine

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

/// Primary action button style used across the app for the main call-to-action.
struct WineProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.wine.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .foregroundStyle(.white)
    }
}

extension ButtonStyle where Self == WineProminentButtonStyle {
    static var wineProminent: WineProminentButtonStyle { WineProminentButtonStyle() }
}
