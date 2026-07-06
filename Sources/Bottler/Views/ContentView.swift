import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bottleManager: BottleManager
    @State private var showingNewBottleSheet = false

    var body: some View {
        NavigationSplitView {
            BottleListView(showingNewBottleSheet: $showingNewBottleSheet)
        } detail: {
            if bottleManager.wineInstallations.isEmpty {
                WineSetupView(onFinished: {})
            } else if let bottle = bottleManager.selectedBottle {
                BottleDetailView(bottle: bottle)
                    .id(bottle.id)
            } else {
                EmptyStateView(showingNewBottleSheet: $showingNewBottleSheet)
            }
        }
        .sheet(isPresented: $showingNewBottleSheet) {
            NewBottleSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestNewBottle)) { _ in
            showingNewBottleSheet = true
        }
    }
}

struct EmptyStateView: View {
    @Binding var showingNewBottleSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.wine)
            Text("No Bottle Selected")
                .font(.title2.weight(.medium))
            Text("Create a bottle to start installing Windows apps.")
                .foregroundStyle(.secondary)
            Button("New Bottle…") {
                showingNewBottleSheet = true
            }
            .buttonStyle(.wineProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
