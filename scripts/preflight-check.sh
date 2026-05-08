#!/usr/bin/env bash
# ============================================
# preflight-check.sh — 設定整合性の双方向検証
# ============================================
# 目的:
#   Phase G v2 混沌テスト（2026-05-08）で発見した R-1 / R-3 / R-4 / N-1
#   と同型の不整合を、CRUD 期間中も継続検出するための自動化スクリプト。
#
#   仕組みの形骸化を防ぐため、PR 提出前 / 振り返り時 / 講師提出前に
#   必ず実行する想定。
#
# 検出範囲:
#   A. CI workflow 設置場所
#   B. Rails ENV.fetch 参照と .env.example の双方向 diff
#   C. .env.example / .env / nuxt.config.ts の API base 値整合性（N-1 同型）
#   D. docker-compose の弱パスワードフォールバック検出（R-6 同型）
#   E. dead ENV 検出（.env.example にあるがコードで参照無し）
#
# 実行:
#   bash scripts/preflight-check.sh
#
# 終了コード:
#   0 = 全 OK / 1 = 1 件以上の異常検出
# ============================================

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ERRORS=0
WARNINGS=0

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
header() { printf "\n\033[1m===== %s =====\033[0m\n" "$*"; }

# ============================================
# A. CI workflow 設置場所（R-1 同型）
# ============================================
header "A. CI workflow 設置場所検査"

MISPLACED=$(find . -type d -name workflows 2>/dev/null \
  | grep -v -E '(^./\.github/workflows$|/node_modules/|/\.git/)' || true)

if [ -n "$MISPLACED" ]; then
  red "❌ サブディレクトリに workflows ディレクトリ発見:"
  echo "$MISPLACED"
  red "   → GitHub Actions は .github/workflows/ のみ参照する"
  ERRORS=$((ERRORS + 1))
else
  green "✓ workflow は .github/workflows/ 配下のみ"
fi

# ============================================
# B. ENV 整合性（R-3 / R-4 同型）
# ============================================
header "B. Rails ENV.fetch ↔ .env.example 双方向 diff"

if [ -d backend/config ] && [ -f .env.example ]; then
  RAILS_REFS=$(grep -rhE 'ENV\.fetch\("[A-Z_]+"|ENV\["[A-Z_]+"' backend/ \
    --include='*.rb' --include='*.yml' 2>/dev/null \
    | grep -oE '"[A-Z_]+"' | tr -d '"' | sort -u \
    | grep -vE '^(BUNDLE_GEMFILE|CI)$')

  EXAMPLE_KEYS=$(grep -E '^[A-Z_]+=|^# [A-Z_]+=' .env.example \
    | sed 's/^# //' | cut -d= -f1 | sort -u)

  MISSING=$(comm -23 <(echo "$RAILS_REFS") <(echo "$EXAMPLE_KEYS"))
  if [ -n "$MISSING" ]; then
    red "❌ Rails が参照しているが .env.example に未記載:"
    echo "$MISSING" | sed 's/^/   - /'
    ERRORS=$((ERRORS + 1))
  else
    green "✓ Rails ENV.fetch 参照キーはすべて .env.example に存在"
  fi

  DEAD=$(comm -13 <(echo "$RAILS_REFS") <(echo "$EXAMPLE_KEYS") \
    | grep -vE '^(AWS_|DATABASE_URL|MYSQL_ROOT_PASSWORD|NUXT_PUBLIC_|RAILS_ENV|RAILS_HOSTS|SECRET_KEY_BASE)' || true)
  if [ -n "$DEAD" ]; then
    yellow "⚠ .env.example にあるが Rails コードで未参照（dead 候補）:"
    echo "$DEAD" | sed 's/^/   - /'
    WARNINGS=$((WARNINGS + 1))
  fi
else
  yellow "⚠ backend/config または .env.example が見つからない（スキップ）"
fi

# ============================================
# C. API base 値整合性（N-1 同型）
# ============================================
header "C. NUXT_PUBLIC_API_BASE 値の三点整合"

if [ -f .env.example ] && [ -f frontend/nuxt.config.ts ]; then
  EXAMPLE_VAL=$(grep -E '^NUXT_PUBLIC_API_BASE=' .env.example | cut -d= -f2- || true)
  FALLBACK_VAL=$(grep -oE "apiBase:[^,]*" frontend/nuxt.config.ts \
    | grep -oE "'[^']+'" | tr -d "'" || true)

  if [ -z "$EXAMPLE_VAL" ] || [ -z "$FALLBACK_VAL" ]; then
    yellow "⚠ NUXT_PUBLIC_API_BASE の値が抽出できない（スキップ）"
  elif [ "$EXAMPLE_VAL" = "$FALLBACK_VAL" ]; then
    green "✓ .env.example と nuxt.config フォールバックが一致: $EXAMPLE_VAL"
  else
    red "❌ NUXT_PUBLIC_API_BASE 値が不一致（N-1 同型）:"
    red "   .env.example      = $EXAMPLE_VAL"
    red "   nuxt.config (fallback) = $FALLBACK_VAL"
    ERRORS=$((ERRORS + 1))
  fi

  # 画面設計書との突合（/api プレフィックス必須を確認）
  if grep -qE '/api/[a-z]' docs/画面設計書.md 2>/dev/null; then
    if ! echo "$EXAMPLE_VAL" | grep -qE '/api$|/api/'; then
      red "❌ 画面設計書は /api/ パスを使うが .env.example には /api 無し"
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# ============================================
# D. docker-compose 弱パスフォールバック（R-6 同型）
# ============================================
header "D. docker-compose の弱パスワードフォールバック検出"

if [ -f docker-compose.yml ]; then
  WEAK=$(grep -nE ':-[a-z]+(pass|word|secret)?\}' docker-compose.yml || true)
  if [ -n "$WEAK" ]; then
    yellow "⚠ 弱パスフォールバックの可能性（R-6 同型）:"
    echo "$WEAK" | sed 's/^/   /'
    yellow '   → ${VAR:?...} の必須化を検討'
    WARNINGS=$((WARNINGS + 1))
  else
    green "✓ 弱パスフォールバック検出なし"
  fi
fi

# ============================================
# E. 結果サマリ
# ============================================
header "結果サマリ"
echo "ERRORS:   $ERRORS"
echo "WARNINGS: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  red "→ 異常検出。修正してから commit / PR / 提出すること。"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  yellow "→ 警告あり。レビューで判断。"
  exit 0
else
  green "→ 全項目クリア。"
  exit 0
fi
