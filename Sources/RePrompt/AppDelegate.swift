import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var idleMonitor: IdleMonitor!
    private var alertController: AlertWindowController?
    private var thresholdMenu: NSMenu!

    /// 選択肢（秒）
    private static let thresholdOptions: [(label: String, seconds: TimeInterval)] = [
        ("30秒",  30),
        ("1分",   60),
        ("3分",   180),
        ("5分",   300),
        ("10分",  600),
        ("15分",  900),
        ("30分",  1800),
    ]

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupIdleMonitor()
        ensureMediaDirectory()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "Re:P"

        let menu = NSMenu()

        // 閾値サブメニュー
        let thresholdItem = NSMenuItem(title: "閾値: \(Self.formatTime(Config.idleThreshold))", action: nil, keyEquivalent: "")
        thresholdMenu = NSMenu()
        for option in Self.thresholdOptions {
            let item = NSMenuItem(
                title: option.label,
                action: #selector(changeThreshold(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = Int(option.seconds)
            if option.seconds == Config.idleThreshold {
                item.state = .on
            }
            thresholdMenu.addItem(item)
        }
        thresholdItem.submenu = thresholdMenu
        menu.addItem(thresholdItem)

        menu.addItem(NSMenuItem.separator())

        let mediaItem = NSMenuItem(
            title: "メディアフォルダを開く",
            action: #selector(openMediaFolder),
            keyEquivalent: ""
        )
        mediaItem.target = self
        menu.addItem(mediaItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Idle Monitor

    private func setupIdleMonitor() {
        idleMonitor = IdleMonitor(threshold: Config.idleThreshold)
        idleMonitor.delegate = self
        idleMonitor.start()
    }

    // MARK: - Media Directory

    private func ensureMediaDirectory() {
        let mediaDir = Config.mediaDirectoryURL
        if !FileManager.default.fileExists(atPath: mediaDir.path) {
            try? FileManager.default.createDirectory(
                at: mediaDir,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - Actions

    @objc private func changeThreshold(_ sender: NSMenuItem) {
        let newThreshold = TimeInterval(sender.tag)
        idleMonitor.threshold = newThreshold
        Config.idleThreshold = newThreshold

        // チェックマーク更新
        for item in thresholdMenu.items {
            item.state = (item.tag == sender.tag) ? .on : .off
        }

        // 親メニューのタイトル更新
        if let parentItem = statusItem.menu?.items.first {
            parentItem.title = "閾値: \(Self.formatTime(newThreshold))"
        }
    }

    @objc private func openMediaFolder() {
        NSWorkspace.shared.open(Config.mediaDirectoryURL)
    }

    @objc private func quit() {
        idleMonitor.stop()
        alertController?.dismiss()
        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s)秒" }
        return "\(s / 60)分"
    }
}

// MARK: - IdleMonitorDelegate

extension AppDelegate: IdleMonitorDelegate {
    func idleMonitorDidExceedThreshold(_ monitor: IdleMonitor) {
        guard alertController == nil else { return }

        let controller = AlertWindowController()
        controller.onDismiss = { [weak self] in
            self?.alertController = nil
        }
        controller.show()
        alertController = controller
    }

    func idleMonitorDidDetectInput(_ monitor: IdleMonitor) {
        alertController?.dismiss()
        alertController = nil
    }
}
