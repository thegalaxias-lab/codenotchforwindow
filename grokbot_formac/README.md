# grokbot_formac — 맥용 Codenotch 포크 (Grok Bot 별도 아이콘)

윈도우 포트(`codenotch/`)에서 성공한 **Grok Bot 주간 사용량 별도 표시**를 맥용
[Codenotch](https://github.com/vinzdg/codenotch)(v1.16.0)에 이식한 포크입니다.

## 원본(vinzdg/codenotch 1.16.0)과의 차이

| 기능 | 내용 |
|---|---|
| **Grok Bot 별도 아이콘** | 로봇얼굴 아이콘 + 자기 자체 링으로 주간 사용량 표시. 그록 봇 앱의 설정→사용량과 같은 숫자(`GetSandUsageStatus`, Cursor 세션으로 조회) |
| **Cursor 상세보기 개선** | 아이콘에 마우스를 올리면 Cursor Models / Other Models 두 줄이 항상 표시(대시보드와 동일). 0%여도 숨기지 않음 |
| Sparkle 자동 업데이트 꺼짐 | 업스트림 릴리스가 이 포크를 덮어써서 Grok Bot이 사라지는 일을 방지 |
| 버전 | 1.16.1 (20) |

각 기능이 읽는 자격증명(모두 "빌려 읽기"만 하고 절대 쓰지 않음):

- **Grok Bot**: Cursor 에디터 로그인(`~/Library/Application Support/Cursor/.../state.vscdb`의 세션) 또는 `cursor-agent` 로그인
- **Grok 본체**: grok CLI 로그인(`~/.grok/auth.json`)
- **GLM(Z.ai)**: 코딩 도구가 가진 키 — 아래 `tools/glm-key-setup` 참고

## 설치

### 방법 A — 미리 빌드된 앱 (가장 편함, Xcode 불필요)

Apple Silicon(ML/M 시리즈) 맥 전용. 터미널에서:

```bash
git clone https://github.com/thegalaxias-lab/codenotchforwindow
cd codenotchforwindow/grokbot_formac
bash install.sh
```

끝입니다. 기존 Codenotch가 있으면 휴지통에 백업 후 교체하며, 설정(프로바이더 순서·on/off)은 그대로 이어받습니다.

> 브라우저로 저장소를 ZIP 다운로드한 경우에도 `install.sh`가 격리 속성을 알아서
> 제거합니다. 그래도 macOS가 실행을 물으면 한 번 허용해 주세요.

### 방법 B — 소스에서 직접 빌드 (Intel 맥은 이쪽)

Xcode가 필요합니다. 방법 A와 동일하게:

```bash
bash install-from-source.sh
```

Xcode 라이선스 동의와 필수 구성요소 설치를 위해 최초 1회 Mac 비밀번호를 물어봅니다.

## 설치 후 확인

1. 노치를 펼쳐 **로봇얼굴 아이콘**(Grok Bot)이 뜨는지 — Cursor에 로그인돼 있어야 합니다
2. 마우스를 올리면 "Grok Bot Usage / 플랜 / n% Used / 리셋 날짜"가 보이는지
3. Cursor 아이콘에 올리면 "Cursor Models"와 "Other Models" 두 줄이 모두 보이는지

Grok Bot 행이 안 보이면: Cursor를 한 번 실행해 로그인하고 노치의 GLM처럼 아이콘을
클릭해 새로고침하거나, Codenotch 설정 → Connected에서 Grok Bot 토글을 확인하세요.

## 폴더 구조

```
grokbot_formac/
├── Codenotch-GrokBot-mac-arm64.zip   # 미리 빌드된 앱 (방법 A)
├── install.sh                        # 방법 A 설치 스크립트
├── install-from-source.sh            # 방법 B 설치 스크립트
├── tools/glm-key-setup               # (선택) z.ai GLM 코딩플랜 키 등록 도우미
└── src/                              # 포크 전체 소스 (XcodeGen + SPM 레이아웃)
```

`tools/glm-key-setup`는 Z.ai 코딩 플랜 API 키를 발급받아 실행하면 키를 검증하고
codenotch가 읽는 위치(`~/.local/share/opencode/auth.json`)에 저장해 줍니다.
키 발급: https://z.ai/manage-apikey/apikey-list

## 문제 해결

- **실행이 바로 죽음(크래시)**: 임베디드 Sparkle 프레임워크와 앱의 서명 팀이 달라서
  그렇습니다. `codesign --force --deep --sign - /Applications/Codenotch.app` 후 재실행.
  (두 설치 스크립트는 이 단계를 이미 포함합니다.)
- **"손상됨/확인 안 됨" 메시지**: `xattr -dr com.apple.quarantine /Applications/Codenotch.app`
- **Grok Bot 사용량이 안 읽힘**: Cursor가 로그인 상태인지 확인. 이 표시는 Cursor
  플랜에 딸린 그록봇 사용권한을 Cursor 세션으로 조회하는 방식이라 Cursor 로그인이 필수입니다.
- **키체인 허용 창**: Claude 등 다른 항목은 처음 한 번 "허용/항상 허용"이 필요할 수 있습니다.

## 소스 빌드에 대해 (기여자용)

`src/`는 upstream 그대로의 구조입니다(XcodeGen 필요: `make gen`, 빌드: `make build`).
이 포크가 추가한 파일:

- `Sources/Providers/GrokBotProvider.swift` / `GrokBotUsage.swift` — Grok Bot 프로바이더
- `Sources/Providers/CursorUsage.swift` — Cursor Models / Other Models 상세 수정
- `Sources/Assets.xcassets/glyph-grok-bot.imageset` — 로봇얼굴 아이콘(템플릿)
- `Tests/GrokBotUsageTests.swift` / `Tests/CursorUsageTests.swift` — 파서 테스트
- `Package.swift` — Xcode 없이 `swift build`/`swift test` 검증용 로컬 매니페스트

라이선스는 upstream 을 따릅니다 (`src/LICENSE`).
