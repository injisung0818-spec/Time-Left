#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_PATH="${1:-$PROJECT_ROOT/build/Release/Time Left.app}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/dist}"

if [[ ! -d "$APP_PATH" ]]; then
  print -u2 "앱 번들을 찾을 수 없습니다: $APP_PATH"
  print -u2 "사용법: $0 '/경로/Time Left.app' [출력_폴더]"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
DMG_PATH="$OUTPUT_DIR/Time-Left-$VERSION.dmg"
STAGING_DIR=$(mktemp -d "${TMPDIR:-/tmp}/time-left-dmg.XXXXXX")

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"
ditto "$APP_PATH" "$STAGING_DIR/Time Left.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create \
  -volname "Time Left" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

print "DMG 생성 완료: $DMG_PATH"
print "배포 전에는 Developer ID 서명과 Apple notarization을 적용하세요."
