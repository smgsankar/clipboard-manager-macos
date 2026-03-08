import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    @Binding var selectedItemID: ClipboardItem.ID?
    let onCopy: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedItemID) {
                ForEach(items) { item in
                    ClipboardRowView(
                        item: item,
                        isSelected: selectedItemID == item.id,
                        onCopy: { onCopy(item) },
                        onDelete: { onDelete(item) }
                    )
                    .tag(item.id)
                    .id(item.id)
                    .contentShape(Rectangle())
                    .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                    .onTapGesture {
                        selectedItemID = item.id
                    }
                    .onTapGesture(count: 2) {
                        onCopy(item)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: selectedItemID) { newValue in
                if let newValue {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .overlay {
                if items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clipboard")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text("No clipboard items")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
