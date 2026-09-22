#!/bin/bash
# install-from-source.sh — 이 폴더의 src/ 소스에서 직접 빌드해 /Applications 에 설치합니다.
# Xcode가 필요합니다 (App Store 또는 developer.apple.com 에서 설치). Intel 맥도 이 경로로.
# 최초 1회, Xcode 라이선스 동의와 필수 구성요소 설치를 위해 Mac 로그인 비밀번호를 물어봅니다.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$DIR/src"
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
APP="/Applications/Codenotch.app"

say() { printf '\n== %s\n' "$*"; }

[ -d "$XCODE_DIR" ] || {
    echo "오류: /Applications/Xcode.app 가 없습니다."
    echo "Xcode 를 먼저 설치하세요 (App Store). 소요 시간이 길지만 이 경로는 그 후에만 가능합니다."
    exit 1
}
[ -d "$REPO" ] || { echo "오류: 소스 폴더 없음: $REPO"; exit 1; }

command -v xcodegen >/dev/null 2>&1 || {
    echo "xcodegen 이 필요합니다 — Homebrew 로 설치합니다"
    brew install xcodegen || { echo "오류: brew install xcodegen 실패 (brew 는 brew.sh 참고)"; exit 1; }
}

# xcode-select 가 Command Line Tools 를 가리키는 맥에서도 동작하도록 항상 Xcode 를 직접 지정.
if DEVELOPER_DIR="$XCODE_DIR" xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    say "Xcode 초기 설정: 이미 완료됨"
else
    say "Xcode 필수 구성요소 설치 — Mac 로그인 비밀번호를 입력하세요 (최초 1회)"
    sudo env DEVELOPER_DIR="$XCODE_DIR" xcodebuild -license accept \
        || { echo "오류: 라이선스 동의 실패"; exit 1; }
    sudo env DEVELOPER_DIR="$XCODE_DIR" xcodebuild -runFirstLaunch \
        || { echo "오류: 구성요소 설치 실패 — 네트워크 확인 후 재실행"; exit 1; }
fi

# 이후 모든 xcodebuild 호출이 Xcode 를 직접 보게 한다 (xcode-select 가 CLT 를 가리키는
# 맥에서 "requires Xcode" 로 실패하는 것을 막는다).
export DEVELOPER_DIR="$XCODE_DIR"

say "실행 중인 기존 Codenotch 종료"
pkill -x Codenotch 2>/dev/null; sleep 1
if [ -d "$APP" ]; then
    mkdir -p "$HOME/.Trash"
    mv "$APP" "$HOME/.Trash/Codenotch-$(date +%Y%m%d-%H%M%S).app" \
        && echo "기존 앱을 휴지통에 백업했습니다"
fi

say "빌드 (Release, 첫 빌드는 몇 분 걸릴 수 있습니다)"
# make install 은 복사 직후 앱을 열어버려서, 재서명 전 순간에 크래시 다이얼로그가
# 뜬다. 여기서는 빌드만 하고 복사-재서명-실행 순서를 직접 제어한다.
SIGN='CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Automatic'
(cd "$REPO" && make gen >/dev/null && xcodebuild -project Codenotch.xcodeproj \
    -scheme Codenotch -destination "platform=macOS,arch=$(uname -m)" \
    -configuration Release $SIGN build) \
    || { echo "빌드 실패 — 오류 메시지를 이슈로 남겨주세요."; exit 1; }

BUILT="$(cd "$REPO" && xcodebuild -project Codenotch.xcodeproj -scheme Codenotch \
    -destination "platform=macOS,arch=$(uname -m)" -configuration Release \
    -showBuildSettings 2>/dev/null \
    | awk -F' = ' '/ BUILT_PRODUCTS_DIR/ {print $2; exit}')/Codenotch.app"
[ -d "$BUILT" ] || { echo "오류: 빌드 산출물을 찾지 못했습니다"; exit 1; }

say "번들 전체 서명 통일 (임베디드 Sparkle 팀 불일치로 인한 실행 크래시 방지)"
codesign --force --deep --sign - "$BUILT" || { echo "오류: 재서명 실패"; exit 1; }

if [ -d "$APP" ]; then
    mkdir -p "$HOME/.Trash"
    mv "$APP" "$HOME/.Trash/Codenotch-$(date +%Y%m%d-%H%M%S).app" \
        && echo "기존 앱을 휴지통에 백업했습니다"
fi
cp -R "$BUILT" /Applications/
codesign --verify --deep --strict "$APP" >/dev/null 2>&1 && echo "서명 검증 OK"

open "$APP"; sleep 3
pgrep -f "$APP/Contents/MacOS/Codenotch" >/dev/null \
    && say "완료 — 노치를 펼쳐 로봇얼굴 아이콘(Grok Bot)을 확인하세요" \
    || { echo "실행 실패 — 오류 메시지를 확인해 주세요"; exit 1; }
