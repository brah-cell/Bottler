import SwiftUI

struct BottleListView: View {
    @EnvironmentObject var bottleManager: BottleManager
    @Binding var showingNewBottleSheet: Bool

    var body: some View {
        List(selection: $bottleManager.selectedBottleID) {
            Section("Bottles") {
                ForEach(bottleManager.bottles) { bottle in
                    HStack(spacing: 8) {
                        Image(systemName: "wineglass.fill")
                            .foregroundStyle(Theme.wine)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(bottle.name)
                            Text(bottle.architecture.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(bottle.id)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Bottler")
        .toolbar {
            ToolbarItem {
                Button {
                    showingNewBottleSheet = true
                } label: {
                    Label("New Bottle", systemImage: "plus")
                }
            }
        }
    }
}
