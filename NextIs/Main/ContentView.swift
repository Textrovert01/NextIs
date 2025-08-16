// Notification extension for popping to KidListView
extension Notification.Name {
    static let popToKidListView = Notification.Name("popToKidListView")
}

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlacesView()
                .tabItem { Label("Places", systemImage: "square.grid.3x3.fill") }
                .tag(0)

            KidListView()
                .tabItem { Label("Kids", systemImage: "person.3.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .background(TabBarIntrospector())
        .onReceive(NotificationCenter.default.publisher(for: .tabReselected)) { note in
            guard let index = note.userInfo?["index"] as? Int else { return }
            selectedTab = index
            if index == 1 {
                NotificationCenter.default.post(name: .popToKidListView, object: nil)
            } else {
                UIApplication.shared.sendAction(#selector(UINavigationController.popToRootViewController(animated:)), to: nil, from: nil, for: nil)
            }
        }
    }
}

#Preview {
    ContentView()
}
