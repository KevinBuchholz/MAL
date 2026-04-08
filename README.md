# MAL

A minimal macOS menu bar utility that temporarily disables keyboard input so you can clean your keyboard without triggering accidental keystrokes.

Named after Mallery, who deleted a meeting from everyone's calendar while cleaning her keyboard.

---

## Download

→ **[Latest Release](../../releases/latest)**

Download the `.zip`, unzip it, and drag `MAL.app` to your `/Applications` folder.

---

## Usage

1. Launch the app — a MAL icon appears in your menu bar
2. Click it to choose a lock duration
3. A full-screen overlay appears confirming the keyboard is disabled
4. Clean away — your mouse/trackpad still works normally
5. Click **Unlock Now** or wait for the timer to finish

### Lock durations
- 30 seconds
- 1 minute
- 2 minutes
- Custom — enter any duration in seconds

---

## Requirements

- macOS 12 Monterey or later
- Accessibility permission (required for keyboard interception)

On first launch, macOS will prompt you to grant Accessibility access. You can also find it manually at:

**System Settings → Privacy & Security → Accessibility → MAL ✓**

Without this permission the app will still run, but keyboard input will not be blocked.

---

## How it works

MAL uses a `CGEventTap` at the session level to intercept and discard all `keyDown`, `keyUp`, and `flagsChanged` events system-wide for the duration of the lock. Mouse input is never affected. An always-on-top overlay provides visual confirmation and an escape hatch.

---

## Building from source

```bash
git clone https://github.com/yourusername/mal
cd mal
open KeyboardCleaner.xcodeproj
```

Build and run in Xcode. Grant Accessibility permission when prompted.

### Creating a release

Fill in the `CONFIG` section of `release.sh` with your Apple Developer credentials, then:

```bash
export NOTARIZE_PASSWORD="your-app-specific-password"
./release.sh 1.0.0
```

Requires [GitHub CLI](https://cli.github.com) and [xcpretty](https://github.com/xcpretty/xcpretty) (`gem install xcpretty`).

---

## License

MIT
