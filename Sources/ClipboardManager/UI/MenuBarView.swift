import SwiftUI

struct MenuBarView: View {
    @ObservedObject var coordinator: AppCoordinator
    @EnvironmentObject private var store: ClipboardStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if store.items.isEmpty {
                Text("No clipboard items")
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            } else {
                ForEach(store.recentItems()) { item in
                    Button {
                        coordinator.copyItem(item)
                    } label: {
                        Text(MenuBarItemFormatter.preview(for: item.content))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Divider()

            Button("Show All") {
                coordinator.showPopup()
            }

            Button("Preferences") {
                coordinator.openPreferences()
            }

            Divider()

            Button("Quit") {
                coordinator.quit()
            }
        }
        .frame(width: 320)
        .padding(.vertical, 4)
    }
}
