import SwiftUI
import AppKit

// Hosts an NSView that becomes first responder and forwards key events into SwiftUI.
struct KeyCaptureView<Content: View>: NSViewRepresentable {
    class HostingNSView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }

    let onKeyDown: (NSEvent) -> Void
    let content: Content

    init(onKeyDown: @escaping (NSEvent) -> Void,
         @ViewBuilder content: () -> Content) {
        self.onKeyDown = onKeyDown
        self.content = content()
    }

    func makeNSView(context: Context) -> HostingNSView {
        let view = HostingNSView()
        view.onKeyDown = context.coordinator.onKeyDown

        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func updateNSView(_ nsView: HostingNSView, context: Context) {
        nsView.onKeyDown = context.coordinator.onKeyDown
        if let hosting = nsView.subviews.first as? NSHostingView<Content> {
            hosting.rootView = content
        }
        nsView.window?.makeFirstResponder(nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onKeyDown: onKeyDown)
    }

    final class Coordinator {
        let onKeyDown: (NSEvent) -> Void

        init(onKeyDown: @escaping (NSEvent) -> Void) {
            self.onKeyDown = onKeyDown
        }
    }
}

