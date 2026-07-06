import SwiftUI

@main
struct BottlerApp: App {
    @StateObject private var bottleManager = BottleManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bottleManager)
                .frame(minWidth: 900, minHeight: 600)
                .tint(Theme.wine)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Bottle…") {
                    NotificationCenter.default.post(name: .requestNewBottle, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let requestNewBottle = Notification.Name("requestNewBottle")
}
