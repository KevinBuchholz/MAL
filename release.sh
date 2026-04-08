#!/usr/bin/env bash
# release.sh — Build, sign, notarize, and package MAL for GitHub release
# Usage: ./release.sh [version]
# Example: ./release.sh 1.0.0
#
# Prerequisites:
#   - Xcode command line tools + xcpretty (gem install xcpretty)
#   - Apple Developer account with valid signing certificate
#   - App-specific password for notarization (create at appleid.apple.com)
#   - GitHub CLI (gh) installed and authenticated (brew install gh && gh auth login)
#
# First-time setup:
#   Set the variables in the CONFIG section below, then:
#   export NOTARIZE_PASSWORD="your-app-specific-password"
#   ./release.sh 1.0.0

set -euo pipefail

# ── CONFIG ────────────────────────────────────────────────────────────────────
SCHEME="MAL"
PROJECT="KeyboardCleaner.xcodeproj"
BUNDLE_ID="com.kevinbuchholz.MAL"
TEAM_ID="5Q9K7U8YKX"                                          # e.g. "ABC123DEF4"
SIGNING_IDENTITY="Developer ID Application: Kevin Buchholz (5Q9K7U8YKX)"                                # e.g. "Developer ID Application: Kevin Buchholz (ABC123DEF4)"
APPLE_ID="buchholz.kevin@gmail.com"                                         # your Apple ID email
NOTARIZE_PASSWORD="${NOTARIZE_PASSWORD:-}"           # set via: export NOTARIZE_PASSWORD="xxxx-xxxx-xxxx-xxxx"
GITHUB_REPO="https://github.com/KevinBuchholz/MAL"                                      # e.g. "kevinbuchholz/mal"
# ─────────────────────────────────────────────────────────────────────────────

VERSION="${1:-1.0.0}"
ARCHIVE_PATH="build/MAL.xcarchive"
EXPORT_PATH="build/export"
ZIP_NAME="MAL-${VERSION}.zip"
ZIP_PATH="build/${ZIP_NAME}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

check_config() {
    local missing=()
    [[ -z "$TEAM_ID" ]]           && missing+=("TEAM_ID")
    [[ -z "$SIGNING_IDENTITY" ]]  && missing+=("SIGNING_IDENTITY")
    [[ -z "$APPLE_ID" ]]          && missing+=("APPLE_ID")
    [[ -z "$NOTARIZE_PASSWORD" ]] && missing+=("NOTARIZE_PASSWORD (env var)")
    [[ -z "$GITHUB_REPO" ]]       && missing+=("GITHUB_REPO")
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing config values:${NC}"
        printf '  • %s\n' "${missing[@]}"
        echo "Edit the CONFIG section in release.sh before running."
        exit 1
    fi
}

step() { echo -e "\n${YELLOW}▸ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }

check_config

step "Cleaning build folder"
rm -rf build && mkdir -p build

step "Archiving MAL v${VERSION}"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    DEVELOPMENT_TEAM="$TEAM_ID" \

ok "Archive created at ${ARCHIVE_PATH}"

step "Exporting .app (Developer ID)"
cat > build/ExportOptions.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>             <string>developer-id</string>
    <key>teamID</key>             <string>${TEAM_ID}</string>
    <key>signingStyle</key>       <string>manual</string>
    <key>signingCertificate</key> <string>${SIGNING_IDENTITY}</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist build/ExportOptions.plist \


# Find the actual .app — name may vary
APP_PATH=$(find "$EXPORT_PATH" -name "*.app" -maxdepth 1 | head -1)
if [[ -z "$APP_PATH" ]]; then
    echo -e "${RED}Error: No .app found in ${EXPORT_PATH}${NC}"
    echo "Contents of export folder:"
    ls -la "$EXPORT_PATH"
    exit 1
fi
ok "App exported: ${APP_PATH}"

step "Zipping for notarization"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
ok "Zipped to ${ZIP_PATH}"

step "Submitting to Apple for notarization"
xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$NOTARIZE_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait
ok "Notarization complete"

step "Stapling notarization ticket"
xcrun stapler staple "$APP_PATH"
ok "Ticket stapled"

step "Re-zipping with stapled app"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
ok "Final zip ready: ${ZIP_PATH}"

step "Creating GitHub release v${VERSION}"
RELEASE_NOTES="## MAL v${VERSION}

Temporarily disable your keyboard for cleaning.

### Installation
1. Download \`${ZIP_NAME}\`
2. Unzip and drag \`MAL.app\` to \`/Applications\`
3. Launch — grant Accessibility permission when prompted
4. Click the MAL icon in your menu bar to start a lock session

### Requirements
- macOS 12 Monterey or later
"

gh release create "v${VERSION}" "$ZIP_PATH" \
    --repo "$GITHUB_REPO" \
    --title "MAL v${VERSION}" \
    --notes "$RELEASE_NOTES"

ok "GitHub release published: https://github.com/${GITHUB_REPO}/releases/tag/v${VERSION}"
echo -e "\n${GREEN}All done!${NC}\n"
