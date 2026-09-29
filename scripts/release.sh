#!/bin/bash
# Builds, signs with Developer ID, notarizes and staples build/release/Spacer.dmg.
#
# One-time setup:
#   1. Create a "Developer ID Application" certificate (Xcode > Settings > Accounts > Manage Certificates).
#   2. Store notary credentials (use an app-specific password from appleid.apple.com):
#        xcrun notarytool store-credentials spacer-notary --apple-id YOU@example.com --team-id TEAMID
#
# Usage: TEAM_ID=ABCDE12345 scripts/release.sh
set -euo pipefail

: "${TEAM_ID:?Set TEAM_ID to your Apple Developer team ID}"
NOTARY_PROFILE="${NOTARY_PROFILE:-spacer-notary}"

cd "$(dirname "$0")/.."
OUT=build/release
ARCHIVE="$OUT/Spacer.xcarchive"
EXPORT="$OUT/export"
DMG="$OUT/Spacer.dmg"

/bin/rm -rf "$OUT"
mkdir -p "$OUT"

xcodegen generate

xcodebuild archive \
  -project Spacer.xcodeproj -scheme Spacer -configuration Release \
  -archivePath "$ARCHIVE" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  -quiet

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Developer ID Application</string>
  <key>teamID</key><string>$TEAM_ID</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -quiet

APP="$EXPORT/Spacer.app"
codesign --verify --deep --strict "$APP"

# Disk image with an Applications shortcut for drag-to-install.
STAGE="$OUT/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname Spacer -srcfolder "$STAGE" -ov -format UDZO "$DMG" -quiet
codesign --sign "Developer ID Application" --timestamp "$DMG"

xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"

echo "Done: $DMG"
