#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI(gh)가 없습니다. brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub에 로그인이 필요합니다. 터미널에서 다음을 실행하세요:"
  echo "  gh auth login"
  echo "완료 후 이 스크립트를 다시 실행하세요:"
  echo "  bash scripts/github-push.sh [저장소이름]"
  exit 1
fi

REPO_NAME="${1:-precision-stitch-trading}"

if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main
  echo "Pushed to existing origin."
  exit 0
fi

gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
echo "Created github.com/$(gh api user -q .login)/$REPO_NAME and pushed main."
