import AppKit
import SwiftUI

final class OverlayWindowController: NSWindowController {
    private final class OverlayPanel: NSPanel {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { false }
    }

    private let viewModel: OverlayViewModel
    private let hostingView: NSHostingView<OverlayContentView>

    init(viewModel: OverlayViewModel) {
        self.viewModel = viewModel
        self.hostingView = NSHostingView(rootView: OverlayContentView(viewModel: viewModel))

        let panel = OverlayPanel(
            contentRect: Self.initialFrame(),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init(window: panel)
        configureWindow(panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        viewModel.show()
        window?.setFrame(Self.initialFrame(), display: false)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    func hide() {
        viewModel.hide()
        window?.orderOut(nil)
    }

    func apply(settings: AppSettings) {
        window?.ignoresMouseEvents = settings.clickThrough
    }

    private func configureWindow(_ panel: OverlayPanel) {
        panel.setContentSize(NSSize(width: 520, height: 160))
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false

        let containerView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        containerView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        panel.contentView = containerView
    }

    private static func initialFrame() -> NSRect {
        let width: CGFloat = 520
        let height: CGFloat = 160

        guard let visibleFrame = NSScreen.main?.visibleFrame else {
            return NSRect(x: 200, y: 600, width: width, height: height)
        }

        let originX = visibleFrame.midX - (width / 2)
        let originY = visibleFrame.maxY - height - 110
        return NSRect(x: originX, y: originY, width: width, height: height)
    }
}
