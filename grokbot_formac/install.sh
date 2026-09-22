#!/bin/bash
# install.sh — 미리 빌드된 Codenotch(Grok Bot 포크)를 /Applications 에 설치합니다.
# Xcode 불필요 · Apple Silicon(arm64) 전용 · Intel 맥은 install-from-source.sh 사용
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ZIP="$DIR/Codenotch-GrokBot-mac-arm64.zip"
APP="/Applications/Codenotch.app"

say() { printf '\n== %s\n' "$*"; }

[ "$(uname -m)" = "arm64" ] || {
    echo "이 미리 빌드된 앱은 Apple Silicon 전용입니다."
    echo "Intel 맥에서는 install-from-source.sh 로 직접 빌드하세요."
    exit 1
}
[ -f "$ZIP" ] || { echo "오류: 압축 파일이 없습니다: $ZIP"; exit 1; }

# git clone/pull 로 받으면 격리 속성이 없지만, 브라우저로 내려받은 경우에 대비해 제거.
xattr -dr com.apple.quarantine "$ZIP" 2>/dev/null

say "실행 중인 기존 Codenotch 종료"
pkill -x Codenotch 2>/dev/null; sleep 1

if [ -d "$APP" ]; then
    mkdir -p "$HOME/.Trash"
    mv "$APP" "$HOME/.Trash/Codenotch-$(date +%Y%m%d-%H%M%S).app" \
        && echo "기존 앱을 휴지통에 백업했습니다 (설정은 그대로 이어집니다)"
fi

say "설치 중"
ditto -x -k --keepParent "$ZIP" /Applications/ || { echo "압축 해제 실패"; exit 1; }
open "$APP"
sleep 3

if pgrep -f "$APP/Contents/MacOS/Codenotch" >/dev/null; then
    say "완료 — 노치를 펼쳐 로봇얼굴 아이콘(Grok Bot)을 확인하세요"
else
    echo "실행에 실패했습니다. install-from-source.sh 를 시도해 보세요."
    exit 1
fi
