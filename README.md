# Time Left

한국어 | [English](README.en.md)

Time Left는 메뉴 막대에서 선택한 일정까지의 남은 시간을 보여 주는 macOS 카운트다운 유틸리티입니다. 학교, 학원, 개인 일정처럼 서로 다른 맥락을 프로필과 그룹으로 정리하고, 메뉴바와 위젯에서 다음 일정을 빠르게 확인할 수 있습니다.

소스에서 빌드하는 방법은 아래에 안내되어 있습니다. 사전 빌드된 앱은 준비되는 대로 [GitHub Releases](https://github.com/injisung0818-spec/Time-Left/releases)에서 제공합니다.

## 다운로드

최신 배포본은 [GitHub Releases](https://github.com/injisung0818-spec/Time-Left/releases/latest)에서 받을 수 있습니다.

1. `Time-Left-<version>.app.zip`을 다운로드합니다.
2. 압축을 풀고 `Time Left.app`을 **응용 프로그램(Applications)** 폴더로 옮깁니다.
3. 앱을 실행한 뒤 메뉴바의 아이콘을 눌러 일정을 확인하거나 설정을 엽니다.

릴리스 노트에는 해당 빌드의 코드 서명과 notarization 상태를 명시해야 합니다. 서명되지 않거나 notarization되지 않은 빌드는 macOS에서 실행 전 확인을 요구할 수 있습니다.

## 주요 기능

- 실행 중인 앱을 메뉴바에만 표시하는 `LSUIElement` macOS 앱입니다.
- 프로필을 만들어 학교, 학원, 개인 등 서로 다른 일정 모음을 분리합니다.
- 프로필 안에서 수업, 시험, 방학 등의 그룹으로 일정을 묶습니다. 그룹이 없는 일정은 `기타`에 표시됩니다.
- 특정 요일과 시간(매주 반복 가능), 오늘의 시간, 특정 날짜와 시간, 올해 종료, 사용자 지정 날짜를 카운트다운 목표로 설정합니다.
- 선택한 일정의 남은 시간을 기본 형식, `00:00:00` 형식, 아이콘만 표시 중에서 고를 수 있으며, 표시 단위도 일정별로 지정할 수 있습니다.
- 메뉴바 팝업에서 현재 프로필의 일정을 그룹별로 살펴보고 바로 전환합니다.
- 데스크톱과 알림 센터용 WidgetKit 위젯에 가까운 일정 최대 5개를 표시하고, 선택된 일정을 강조합니다.
- `SMAppService`를 사용해 설정에서 켠 경우에만 로그인 시 자동 실행합니다.
- `timeleft://open`으로 설정을 열고, `timeleft://schedule/<일정 UUID>`로 특정 일정을 선택해 설정을 열 수 있습니다.
- 앱 시작과 설정 창을 열 때 GitHub Releases에서 새 버전을 확인합니다.

## 기본 하교 프리셋

처음 실행하면 `하교` 일정이 포함됩니다. 이 일정은 일반적인 매주 반복과 달리 아래의 학교 주기를 사용합니다.

| 현재 시점 | 다음 목표 |
| --- | --- |
| 금요일 14:20 전 | 그 주 금요일 14:20의 `하교` |
| 금요일 14:20 후 ~ 일요일 21:00 전 | 일요일 21:00의 `등교` |
| 일요일 21:00 후 | 다음 주 금요일 14:20의 `하교` |

이 동작은 기본 프리셋에만 적용됩니다. 직접 만든 주간 일정은 지정한 요일과 시간을 기준으로 반복됩니다.

## 호환성

| 항목 | 지원 |
| --- | --- |
| 배포 대상 | macOS 13.0 이상 |
| 앱 UI | SwiftUI |
| 위젯 | WidgetKit 데스크톱 및 알림 센터 위젯 |

배포 대상은 [`TimeLeft/Info.plist`](TimeLeft/Info.plist)와 위젯의 `Info.plist`에 정의되어 있습니다. 이는 빌드 대상이며, 모든 macOS 버전에서의 개별 동작을 보장한다는 뜻은 아닙니다.

## 개인정보

일정, 프로필, 표시 설정은 앱과 위젯이 공유하는 App Group `UserDefaults`에 로컬로 저장됩니다. 일정 데이터는 외부 서비스로 전송하지 않습니다.

새 버전을 확인할 때만 GitHub Releases API에 요청합니다. 위젯은 일정 또는 프로필 변경처럼 표시 내용에 영향을 주는 경우에만 새로고침합니다.

## 소스에서 빌드하기

Time Left는 Xcode 프로젝트로 제공되며 SwiftUI와 WidgetKit을 사용합니다. macOS 13 이상을 대상으로 빌드할 수 있는 Xcode가 필요합니다.

1. 저장소를 복제하고 이동합니다.

   ```bash
   git clone https://github.com/injisung0818-spec/Time-Left.git
   cd Time-Left
   ```

2. `TimeLeft.xcodeproj`를 Xcode에서 엽니다.
3. `Time Left` 스킴을 선택한 뒤 빌드하고 실행합니다.

명령줄에서 빌드할 수도 있습니다.

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left' build
```

## 테스트

카운트다운 엔진 테스트는 학교 주기, 주간 반복, 만료된 일회성 일정, 연말 계산, 시간대와 일광 절약 시간제(DST) 경계를 다룹니다.

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left Tests' test
```

## 패키징과 배포

Release 구성으로 빌드한 뒤 패키징 스크립트를 실행합니다.

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left' -configuration Release -derivedDataPath build build
./scripts/package-app.sh "$(pwd)/build/Build/Products/Release/Time Left.app"
```

스크립트는 앱과 위젯을 ad-hoc 서명하고 `dist/Time-Left-<version>.app.zip`을 생성합니다. 이 ZIP 파일만 GitHub Release 자산으로 첨부하세요.

ad-hoc 서명은 Apple Developer ID 서명, Hardened Runtime, notarization 또는 Gatekeeper 신뢰와 같지 않습니다. 일반 사용자에게 배포할 빌드는 별도의 Developer ID 서명과 Apple notarization을 적용해야 하며, 인증서·개인 키·내보낸 `.p12` 파일은 저장소나 릴리스에 포함하면 안 됩니다.

## 기술 구성

- `TimeLeft` — 앱 수명 주기, 메뉴바, 설정, 일정 관리
- `TimeLeftWidget` — 공유 일정을 표시하는 WidgetKit 확장
- `TimeLeftTests` — 카운트다운 계산 검증
- `scripts/package-app.sh` — 앱 번들 서명 및 ZIP 패키징

## 알려진 제한 사항

- 위젯은 시스템의 갱신 정책에 따라 분 단위로 업데이트되므로 메뉴바의 초 단위 표시와 정확히 동시에 바뀌지 않을 수 있습니다.
- `오늘의 특정 시간` 및 일회성 날짜 일정은 목표 시간이 지나면 완료로 표시됩니다. 새 목표를 지정해야 다시 카운트다운합니다.
- 자동 업데이트 설치 기능은 제공하지 않으며, 앱은 새 릴리스가 있는지만 확인합니다.

## 라이선스

Time Left는 [MIT 라이선스](LICENSE)로 제공됩니다.

Copyright © 2026 Injisung.

## 기여

버그 제보와 개선 제안은 [Issues](https://github.com/injisung0818-spec/Time-Left/issues)에서 받습니다. 변경 제안에는 가능한 경우 관련 테스트를 포함해 주세요.
