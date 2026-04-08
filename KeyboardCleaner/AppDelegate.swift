import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var keyboardBlocker: KeyboardBlocker?
    var overlayWindow: OverlayWindow?
    var countdownTimer: Timer?
    var remainingSeconds: Int = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        AXIsProcessTrustedWithOptions(options)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIconIdle()

        if let button = statusItem?.button {
            button.action = #selector(showMenu)
            button.target = self
        }

        keyboardBlocker = KeyboardBlocker()
    }

    func updateStatusIconIdle() {
        guard let button = statusItem?.button else { return }
        if let icon = NSImage(named: "MenuBarIcon") {
            icon.isTemplate = true
            button.image = icon
        } else {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "MAL")
        }
        button.title = ""
    }

    @objc func showMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "MAL", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Lock for 30 seconds", action: #selector(lock30), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Lock for 1 minute",   action: #selector(lock60), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Lock for 2 minutes",  action: #selector(lock120), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Custom duration...", action: #selector(showCustomDuration), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Uninstall MAL...", action: #selector(uninstall), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.items.forEach { if $0.action != #selector(NSApplication.terminate(_:)) { $0.target = self } }
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func lock30()  { startLock(seconds: 30) }
    @objc func lock60()  { startLock(seconds: 60) }
    @objc func lock120() { startLock(seconds: 120) }

    @objc func uninstall() {
        let alert = NSAlert()
        alert.messageText = "Uninstall MAL?"
        alert.informativeText = "MAL will be moved to the Trash and quit."
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        guard let appURL = Bundle.main.bundleURL else { return }

        do {
            try NSWorkspace.shared.recycle([appURL])
        } catch {
            // Fallback: open Finder to the app location
            NSWorkspace.shared.activateFileViewerSelecting([appURL])
        }

        NSApplication.shared.terminate(nil)
    }

    @objc func showCustomDuration() {
        let alert = NSAlert()
        alert.messageText = "Custom Lock Duration"
        alert.informativeText = "Enter the number of seconds to lock the keyboard:"
        alert.addButton(withTitle: "Lock")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = "e.g. 45"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input

        if alert.runModal() == .alertFirstButtonReturn,
           let seconds = Int(input.stringValue), seconds > 0 {
            startLock(seconds: seconds)
        }
    }

    func startLock(seconds: Int) {
        guard AXIsProcessTrusted() else {
            showAccessibilityAlert()
            return
        }
        remainingSeconds = seconds
        keyboardBlocker?.startBlocking()
        showOverlay(seconds: seconds)
        updateStatusIconCounting(remaining: seconds)

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remainingSeconds -= 1
            self.updateStatusIconCounting(remaining: self.remainingSeconds)
            self.overlayWindow?.updateCountdown(self.remainingSeconds)
            if self.remainingSeconds <= 0 { self.stopLock() }
        }
    }

    func stopLock() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        keyboardBlocker?.stopBlocking()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        updateStatusIconIdle()
    }

    func showOverlay(seconds: Int) {
        guard let screen = NSScreen.main else { return }
        overlayWindow = OverlayWindow(screen: screen, seconds: seconds)
        overlayWindow?.onCancel = { [weak self] in self?.stopLock() }
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    func updateStatusIconCounting(remaining: Int) {
        guard let button = statusItem?.button else { return }
        if let icon = NSImage(named: "MenuBarIcon") {
            icon.isTemplate = true
            button.image = icon
        }
        let m = remaining / 60
        let s = remaining % 60
        button.title = m > 0 ? " \(m):\(String(format: "%02d", s))" : " \(s)s"
    }

    func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "MAL needs Accessibility access to block keyboard input.\n\nEnable it in System Settings → Privacy & Security → Accessibility."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}

