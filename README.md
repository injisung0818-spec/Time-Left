# Time Left

Time Left는 macOS 13 이상에서 동작하는 SwiftUI 메뉴바 카운트다운 앱입니다. 프로필과 그룹별로 일정을 정리하고, 메뉴바와 위젯에서 현재 프로필의 남은 시간을 빠르게 확인할 수 있습니다.

![Time Left 앱 아이콘](TimeLeft/Assets.xcassets/AppIcon.appiconset/icon_512x512.png)

최신 배포본은 [GitHub Releases](https://github.com/injisung0818-spec/Time-Left/releases/latest)에서 받을 수 있습니다.

## 주요 기능

- 프로필별 일정 관리: 학교, 학원, 개인 등 프로필을 추가·수정·삭제하고 현재 프로필을 전환합니다.
- 그룹별 일정 관리: 프로필 안에 수업, 시험, 방학 등의 그룹을 만들고 일정을 묶습니다. 그룹이 없는 일정은 `기타`로 표시됩니다.
- 메뉴바에서 현재 선택된 일정의 남은 시간을 `기본`, `00:00:00`, `아이콘만` 중 원하는 방식으로 표시합니다.
- 메뉴바 팝업에서 현재 프로필의 일정을 그룹별로 확인하고 바로 전환합니다. `새 일정` 버튼은 설정의 일정 편집 화면을 그대로 엽니다.
- 일정마다 메뉴바 표시 방식과 표시 단위를 따로 설정할 수 있습니다.
- 특정 요일/시간, 오늘의 시간, 특정 날짜/시간, 올해 종료, 사용자 지정 날짜 카운트다운을 지원합니다.
- 바탕화면과 알림 센터용 WidgetKit 위젯은 가까운 일정 최대 5개를 분 단위로 갱신하며 현재 선택된 일정을 강조합니다.
- 앱과 위젯은 App Group `UserDefaults`로 같은 프로필·일정 데이터를 공유합니다. 일정·프로필 변경처럼 위젯 내용에 영향을 주는 경우에만 위젯을 새로고침합니다.
- 앱 실행 및 설정 창을 열 때 GitHub Releases API로 최신 버전을 확인합니다. 같은 확인 요청이 겹치지 않도록 처리합니다.
- 로그인 시 자동 실행은 설정의 토글을 켰을 때만 등록되며, 끈 상태는 앱을 다시 실행해도 유지됩니다.
- `timeleft://open` 링크로 설정 창을 열 수 있습니다. `timeleft://schedule/<일정 UUID>`는 해당 일정을 선택한 뒤 설정 창을 엽니다.

## 기본 하교 일정

처음 실행하면 `하교` 기본 일정이 포함됩니다. 이 일정의 주기는 고정되어 있습니다.

- 금요일 14:20 전: 그 주 금요일 14:20까지 `하교`
- 금요일 14:20 후부터 일요일 21:00 전: 일요일 21:00까지 `등교`
- 일요일 21:00 후: 다음 주 금요일 14:20까지 `하교`

이 동작은 하교 기본 일정에만 적용됩니다. 사용자 지정 주간 일정은 일반적인 매주 반복 규칙을 따릅니다.

## 실행과 개발

1. `TimeLeft.xcodeproj`를 Xcode에서 엽니다.
2. `Time Left` 스킴을 선택합니다.
3. macOS 13 이상을 대상으로 빌드하고 실행합니다.

카운트다운 계산 검증은 `Time Left Tests` 스킴으로 실행할 수 있습니다. 학교 주기, 주간 반복, 일회성 일정 만료, 연말, 시간대/DST 경계를 테스트합니다.

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left Tests' test
```

## 배포

Release 빌드와 앱 번들 ZIP 생성:

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left' -configuration Release -derivedDataPath build build
./scripts/package-app.sh "$(pwd)/build/Build/Products/Release/Time Left.app"
```

`dist/Time-Left-<version>.app.zip` 파일만 GitHub Release에 첨부합니다. 사용자는 ZIP을 풀어 나온 `Time Left.app`을 Applications 폴더로 옮겨 실행합니다.

현재 프로젝트는 서명 없이도 개발·개인 사용 빌드를 만들 수 있습니다. 다른 사용자에게 Gatekeeper 경고 없이 배포하려면 별도로 Developer ID 서명, Hardened Runtime, notarization을 적용해야 합니다.

## 버전

현재 버전은 **2.1.2**입니다. 버전은 `메이저.마이너.패치` 형식을 사용합니다. 버그 수정은 패치, 새 기능은 마이너, 구조나 사용 방식의 큰 변경은 메이저 버전을 올립니다.
