import SwiftUI

struct BottleDetailView: View {
    @EnvironmentObject var bottleManager: BottleManager
    let bottle: Bottle

    var body: some View {
        TabView {
            OverviewTab(bottle: bottle)
                .tabItem { Label("Overview", systemImage: "info.circle") }

            FilesTab(bottle: bottle)
                .tabItem { Label("Files", systemImage: "folder") }

            ApplicationsTab(bottle: bottle)
                .tabItem { Label("Applications", systemImage: "square.grid.2x2") }

            WinetricksTab(bottle: bottle)
                .tabItem { Label("Winetricks", systemImage: "wrench.and.screwdriver") }

            SettingsTab(bottle: bottle)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .navigationTitle(bottle.name)
    }
}
