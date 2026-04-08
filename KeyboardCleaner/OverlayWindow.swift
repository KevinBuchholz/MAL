import Cocoa

class OverlayWindow: NSWindow {
    var onCancel: (() -> Void)?
    private var countdownLabel: NSTextField!
    private var progressTrack: NSView!
    private var progressFill: NSView!
    private var progressWidthConstraint: NSLayoutConstraint!
    private let totalSeconds: Int

    private let bgColor      = NSColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1)
    private let primaryColor = NSColor(srgbRed: 0.08, green: 0.08, blue: 0.10, alpha: 1)
    private let accentColor  = NSColor(srgbRed: 0.12, green: 0.47, blue: 0.98, alpha: 1)
    private let mutedColor   = NSColor(srgbRed: 0.50, green: 0.50, blue: 0.53, alpha: 1)
    private let trackColor   = NSColor(srgbRed: 0.85, green: 0.85, blue: 0.87, alpha: 1)
    private let ruleColor    = NSColor(srgbRed: 0.80, green: 0.80, blue: 0.82, alpha: 1)

    init(screen: NSScreen, seconds: Int) {
        self.totalSeconds = seconds
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        self.level = .screenSaver
        self.backgroundColor = bgColor
        self.isOpaque = true
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        setupUI(seconds: seconds)
    }

    private func setupUI(seconds: Int) {
        guard let content = contentView else { return }

        // Top chrome
        let appLabel = mono("MAL", size: 11, weight: .regular, color: mutedColor)
        let versionLabel = mono("v1.0", size: 11, weight: .regular, color: mutedColor)
        let topRule = rule()
        content.addSubview(appLabel)
        content.addSubview(versionLabel)
        content.addSubview(topRule)

        // Center block
        let center = NSView()
        center.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(center)

        // MAL icon
        let iconView = NSImageView()
        iconView.image = NSImage(named: "OverlayIcon")
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        center.addSubview(iconView)

        let statusLabel = mono("INPUT SUSPENDED", size: 13, weight: .semibold, color: accentColor)
        countdownLabel  = mono(formatTime(seconds), size: 96, weight: .thin, color: primaryColor)
        let subLabel    = mono("ALL KEYBOARD INPUT IS DISABLED", size: 11, weight: .regular, color: mutedColor)
        center.addSubview(statusLabel)
        center.addSubview(countdownLabel)
        center.addSubview(subLabel)

        // Progress bar
        progressTrack = NSView()
        progressTrack.wantsLayer = true
        progressTrack.layer?.backgroundColor = trackColor.cgColor
        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        center.addSubview(progressTrack)

        progressFill = NSView()
        progressFill.wantsLayer = true
        progressFill.layer?.backgroundColor = accentColor.cgColor
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.addSubview(progressFill)

        // Cancel button
        let cancelBtn = UnderlineButton(title: "UNLOCK NOW", target: self, action: #selector(cancelTapped))
        cancelBtn.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        cancelBtn.isBordered = false
        cancelBtn.contentTintColor = primaryColor
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        center.addSubview(cancelBtn)

        // Bottom chrome
        let bottomRule = rule()
        let hintLabel = mono("MOUSE INPUT REMAINS ACTIVE  ·  CLICK UNLOCK OR WAIT FOR TIMER", size: 10, weight: .regular, color: mutedColor)
        content.addSubview(bottomRule)
        content.addSubview(hintLabel)

        progressWidthConstraint = progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 1.0)

        NSLayoutConstraint.activate([
            // Top chrome
            appLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            appLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),

            versionLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            versionLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),

            topRule.topAnchor.constraint(equalTo: appLabel.bottomAnchor, constant: 12),
            topRule.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            topRule.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            topRule.heightAnchor.constraint(equalToConstant: 1),

            // Center block
            center.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            center.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            center.widthAnchor.constraint(equalToConstant: 480),

            // Icon
            iconView.topAnchor.constraint(equalTo: center.topAnchor),
            iconView.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),

            statusLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: center.centerXAnchor),

            countdownLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            countdownLabel.centerXAnchor.constraint(equalTo: center.centerXAnchor),

            subLabel.topAnchor.constraint(equalTo: countdownLabel.bottomAnchor, constant: 12),
            subLabel.centerXAnchor.constraint(equalTo: center.centerXAnchor),

            progressTrack.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 32),
            progressTrack.leadingAnchor.constraint(equalTo: center.leadingAnchor),
            progressTrack.trailingAnchor.constraint(equalTo: center.trailingAnchor),
            progressTrack.heightAnchor.constraint(equalToConstant: 2),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressWidthConstraint,

            cancelBtn.topAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: 24),
            cancelBtn.centerXAnchor.constraint(equalTo: center.centerXAnchor),
            cancelBtn.bottomAnchor.constraint(equalTo: center.bottomAnchor),

            // Bottom chrome
            bottomRule.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -48),
            bottomRule.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            bottomRule.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            bottomRule.heightAnchor.constraint(equalToConstant: 1),

            hintLabel.topAnchor.constraint(equalTo: bottomRule.bottomAnchor, constant: 12),
            hintLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),
        ])
    }

    func updateCountdown(_ seconds: Int) {
        countdownLabel.stringValue = formatTime(seconds)
        let fraction = CGFloat(seconds) / CGFloat(totalSeconds)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.9
            ctx.timingFunction = CAMediaTimingFunction(name: .linear)
            progressWidthConstraint.isActive = false
            progressWidthConstraint = progressFill.widthAnchor.constraint(
                equalTo: progressTrack.widthAnchor,
                multiplier: max(fraction, 0.001)
            )
            progressWidthConstraint.isActive = true
            progressTrack.layoutSubtreeIfNeeded()
        }
    }

    private func formatTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    private func mono(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.font = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        tf.textColor = color
        tf.alignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    private func rule() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = ruleColor.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    @objc private func cancelTapped() { onCancel?() }
}

// MARK: - Underline-on-hover button

class UnderlineButton: NSButton {
    private let idleColor  = NSColor(srgbRed: 0.08, green: 0.08, blue: 0.10, alpha: 1)
    private let hoverColor = NSColor(srgbRed: 0.12, green: 0.47, blue: 0.98, alpha: 1)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways],
                                       owner: self, userInfo: nil))
    }
    override func mouseEntered(with event: NSEvent) { applyStyle(color: hoverColor, underline: true) }
    override func mouseExited(with event: NSEvent)  { applyStyle(color: idleColor,  underline: false) }

    private func applyStyle(color: NSColor, underline: Bool) {
        var attrs: [NSAttributedString.Key: Any] = [.font: font!, .foregroundColor: color]
        if underline { attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        attributedTitle = NSAttributedString(string: title, attributes: attrs)
    }
}
