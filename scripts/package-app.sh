#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_PATH="${1:-$PROJECT_ROOT/build/Release/Time Left.app}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/dist}"

APP_PATH="${APP_PATH:A}"
OUTPUT_DIR="${OUTPUT_DIR:A}"

if [[ ! -d "$APP_PATH" ]]; then
  print -u2 "앱 번들을 찾을 수 없습니다: $APP_PATH"
  print -u2 "사용법: $0 '/경로/Time Left.app' [출력_폴더]"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
ARCHIVE_PATH="$OUTPUT_DIR/Time-Left-$VERSION.app.zip"

mkdir -p "$OUTPUT_DIR"
rm -f "$ARCHIVE_PATH"

# Ad-hoc signing keeps the bundle internally consistent for local test builds.
# Public distribution should replace this with Developer ID signing and notarization.
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
(
  cd "${APP_PATH:h}"
  /usr/bin/zip -q -r -X "$ARCHIVE_PATH" "${APP_PATH:t}"
)

print "앱 ZIP 생성 완료: $ARCHIVE_PATH"
print "배포 전에는 Developer ID 서명과 Apple notarization을 적용하세요."
