# Time Left

macOS 13 이상에서 동작하는 SwiftUI 메뉴바 카운트다운 앱입니다. 기본 목표는 매주 금요일 오후 2시 20분의 하교 시간이며, 프로필과 그룹으로 일정들을 나누어 관리할 수 있습니다.

![Time Left 앱 아이콘](TimeLeft/Assets.xcassets/AppIcon.appiconset/icon_512x512.png)

## 기능

- 프로필별 일정 관리: 학교, 학원, 개인처럼 프로필을 추가·수정·삭제하고 현재 프로필 즉시 전환
- 프로필 안에서 수업, 시험, 방학 같은 그룹을 추가·수정·삭제하고 그룹별 일정 표시
- 메뉴바에 `2h 20m`, `00:00:00`, 아이콘만 형식 중 선택해 표시
- 일정마다 메뉴바 표시 방식과 표시 단위를 따로 설정
- 시스템 설정, 라이트 모드, 다크 모드 중 앱 모드 선택 및 저장
- GitHub Releases의 최신 버전을 앱 실행·설정 화면 열기 때 확인하고 설정 화면에 상태 표시
- 금요일 하교에서 일요일 등교로 자동 전환되는 기본 일정과 사용자 지정 일정 관리
- 바탕화면과 알림 센터에서 현재 프로필의 가까운 일정 최대 5개를 보여주는 macOS WidgetKit 위젯
- 앱과 위젯의 프로필별 일정 공유, 현재 일정 강조, 일정·프로필·그룹 변경 시 위젯 새로고침
- 메뉴바 팝업에서 그룹별 일정 빠른 전환 및 새 일정 추가
- 특정 요일/시간(매주 반복 또는 한 번만), 오늘의 시간, 특정 날짜/시간, 올해 종료, 사용자 지정 날짜
- 자동, 초, 분, 시간, 일, 주, 년 단위 표시
- 목표 이름과 표시 단위의 영구 저장
- macOS 로그인 시 자동 실행 및 설정 화면에서 켜기/끄기
- Dock 아이콘 없이 메뉴바에서만 실행되는 앱

## 실행

1. `TimeLeft.xcodeproj`를 Xcode 14 이상에서 엽니다.
2. `Time Left` 스킴을 선택합니다.
3. macOS 13 이상을 대상으로 빌드하고 실행합니다.

별도의 Swift Package나 외부 라이브러리는 사용하지 않습니다. 업데이트 상태는 GitHub Releases API를 읽기 전용으로 확인하며, 앱 설정과 일정은 App Group의 `UserDefaults`를 통해 앱과 위젯이 공유합니다.

앱을 한 번 실행한 뒤 바탕화면을 오른쪽 클릭해 **위젯 편집**을 열고 `Time Left`를 추가할 수 있습니다. 위젯은 macOS 정책에 맞춰 초 단위가 아닌 분 단위 타임라인으로 갱신됩니다.

## 앱 번들 배포

GitHub Release에는 폴더인 `.app`을 직접 첨부할 수 없으므로, 앱 번들만 담은 ZIP으로 패키징합니다. 사용자는 ZIP을 풀어 나온 `Time Left.app`을 Applications 폴더로 옮겨 실행합니다.

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left' -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
./scripts/package-app.sh "$(pwd)/build/Build/Products/Release/Time Left.app"
```

생성된 `dist/Time-Left-<version>.app.zip`만 GitHub의 **Releases** 항목에 첨부합니다. 공개 배포에서는 Developer ID로 앱을 서명하고 Hardened Runtime을 켠 뒤, 앱 또는 ZIP을 Apple notarization에 제출해야 Gatekeeper 경고 없이 설치할 수 있습니다.

## 버전 규칙

버전은 `메이저.마이너.패치` 형식을 사용합니다. 버그·문구·색상·오류 수정은 패치 버전을, 새 기능은 마이너 버전을, 앱 구조나 사용 방식이 크게 바뀌는 변경은 메이저 버전을 올립니다. 변경을 배포할 때마다 이 규칙에 따라 버전을 자동으로 증가시키며, 마이너와 패치는 한 자리로 제한하지 않습니다(예: `1.10.0`).

## 기본 동작

처음 실행하면 하교 프리셋이 적용됩니다. 금요일 14:20 전에는 해당 시각을 목표로 표시하고, 그 시간이 지나면 일요일 21:00까지로 자동 전환합니다. 일요일 21:00이 지나면 다음 주 금요일 14:20을 목표로 돌아갑니다. 이 특수 규칙은 하교 프리셋에만 적용되며, 사용자 지정 반복 목표는 기존 주간 반복 방식으로 동작합니다.
