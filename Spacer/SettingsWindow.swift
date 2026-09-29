import AppKit
import SpacerCore
import SwiftUI

@Observable
final class SettingsModel {
    var desktops: [Desktop] = []
    @ObservationIgnored var onNamesChanged: () -> Void = {}
    @ObservationIgnored private let nameStore: NameStore

    init(nameStore: NameStore) {
        self.nameStore = nameStore
    }

    func nameBinding(for desktop: Desktop) -> Binding<String> {
        Binding(
            get: { [nameStore] in nameStore.name(for: desktop.id) ?? "" },
            set: { [weak self] newValue in
                self?.nameStore.setName(newValue, for: desktop.id)
                self?.onNamesChanged()
            }
        )
    }
}

struct SettingsView: View {
    let model: SettingsModel
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section("Desktop names") {
                if model.desktops.isEmpty {
                    Text("No desktops found.").foregroundStyle(.secondary)
                }
                ForEach(model.desktops, id: \.id) { desktop in
                    TextField("Desktop \(desktop.index)", text: model.nameBinding(for: desktop),
                              prompt: Text(String(desktop.index)))
                }
            }
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in LoginItem.setEnabled(newValue) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
    }
}

final class SettingsWindowController {
    private let model: SettingsModel
    private var window: NSWindow?

    init(model: SettingsModel) {
        self.model = model
    }

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window
        // Fresh view each time so the login toggle reflects current state.
        window.contentViewController = NSHostingController(rootView: SettingsView(model: model))
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Spacer Settings"
        window.isReleasedWhenClosed = false
        return window
    }
}
