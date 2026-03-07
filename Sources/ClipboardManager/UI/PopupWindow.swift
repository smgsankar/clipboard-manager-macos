import AppKit
import SwiftUI

@MainActor
protocol ClipboardPopupPanelControlling {
    func show(store: ClipboardStore, coordinator: AppCoordinator)
    func close(shouldHideApp: Bool)
}

@MainActor
final class ClipboardPopupPanelController: ClipboardPopupPanelControlling {
    private var panel: NSPanel?
    private var panelDelegate: PanelDelegate?

    func show(store: ClipboardStore, coordinator: AppCoordinator) {
        let hostingController = NSHostingController(
            rootView: PopupWindow(coordinator: coordinator)
                .environmentObject(store)
        )

        if let panel {
            panel.contentViewController = hostingController
        } else {
            let panel = ClipboardPanel(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.title = "Clipboard History"
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentViewController = hostingController
            
            // Set up delegate to handle window closing
            let delegate = PanelDelegate { [weak self] in
                self?.handlePanelClosing()
            }
            panel.delegate = delegate
            self.panelDelegate = delegate
            self.panel = panel
        }

        panel?.center()
        NSApp.activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(nil)
    }

    func close(shouldHideApp: Bool = true) {
        panel?.orderOut(nil)
        if shouldHideApp {
            handlePanelClosing()
        }
    }
    
    private func handlePanelClosing() {
        // Hide the app to return focus to the previously active application
        if NSApplication.shared as NSApplication? != nil {
            NSApp.hide(nil)
        }
    }
}

private final class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

struct PopupWindow: View {
    @ObservedObject var coordinator: AppCoordinator
    @EnvironmentObject private var store: ClipboardStore

    @State private var searchText = ""
    @State private var selectedItemID: ClipboardItem.ID?
    @State private var isShowingClearConfirmation = false
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [ClipboardItem] {
        store.searchItems(query: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                }
            }
            .padding(.horizontal, 16)

            Divider()

            ClipboardListView(
                items: filteredItems,
                selectedItemID: $selectedItemID,
                onCopy: coordinator.copyItem,
                onDelete: coordinator.deleteItem
            )
            .frame(minHeight: 340)

            Divider()

            HStack {
                Text("\(filteredItems.count) items")
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Preferences") {
                    coordinator.closePopupWithoutHiding()
                    coordinator.openPreferences()
                }

                Button("Clear History", role: .destructive) {
                    isShowingClearConfirmation = true
                }
                .disabled(store.items.isEmpty)
            }
            .padding(.horizontal, 16)
        }
        .frame(minWidth: 640, idealWidth: 720, minHeight: 420, idealHeight: 520)
        .background(
            PopupKeyMonitor(
                onEscape: coordinator.closePopup,
                onReturn: copySelection
            )
        )
        .onAppear {
            isSearchFocused = true
            selectedItemID = filteredItems.first?.id
        }
        .onChange(of: searchText) { _ in
            if !filteredItems.contains(where: { $0.id == selectedItemID }) {
                selectedItemID = filteredItems.first?.id
            }
        }
        .alert("Clear Clipboard History?", isPresented: $isShowingClearConfirmation) {
            Button("Clear", role: .destructive) {
                coordinator.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every saved clipboard entry.")
        }
    }

    private func copySelection() {
        guard let item = selectedItem else {
            return
        }

        coordinator.copyItem(item)
    }

    private var selectedItem: ClipboardItem? {
        if let selectedItemID {
            return filteredItems.first(where: { $0.id == selectedItemID }) ?? filteredItems.first
        }

        return filteredItems.first
    }
}

private struct PopupKeyMonitor: NSViewRepresentable {
    let onEscape: () -> Void
    let onReturn: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEscape: onEscape, onReturn: onReturn)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.install()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onEscape = onEscape
        context.coordinator.onReturn = onReturn
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator {
        var onEscape: () -> Void
        var onReturn: () -> Void
        private var monitor: Any?

        init(onEscape: @escaping () -> Void, onReturn: @escaping () -> Void) {
            self.onEscape = onEscape
            self.onReturn = onReturn
        }

        func install() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else {
                    return event
                }

                switch event.keyCode {
                case 53:
                    onEscape()
                    return nil
                case 36:
                    onReturn()
                    return nil
                default:
                    return event
                }
            }
        }

        func uninstall() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }
    }
}

private class PanelDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
