#!/bin/bash
# recipe-board / infra / user_data.sh — Phase 4 B-5-ε
#
# 目的: EC2 第一起動時に最小限の OS bootstrap を行い、nginx で起動完了マーカーを表示する。
# スコープ: dnf update / swap 2GB / TZ=Asia/Tokyo / nginx 起動 / 完了マーカー
# 含まない（B-5-ζ 以降の別 PR で追加）:
#   - Ruby / Rails
#   - MySQL クライアント（mariadb-connector-c-devel 等）
#   - Node.js
#   - アプリ clone / systemd unit / Nginx reverse proxy 設定
#
# 適用した過去事故対策:
#   - 2026-05-07-curl-minimal-conflict: AL2023 既定の curl-minimal を尊重し curl を直接 install しない
#   - 2026-05-07-t3micro-oom: 1GB RAM の OOM 防止のため swap 2GB を必須化
#   - 2026-05-07-java-version-mismatch: アプリランタイム（Ruby）はクロスレイヤー監査確立まで導入しない

set -euo pipefail

# --- ログ: stdout/stderr を /var/log/user-data.log に二重出力 ---
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "===== user-data start: $(date -Is) ====="

# --- idempotency: 完了マーカーがあれば skip ---
DONE_MARKER=/var/log/user-data.done
if [ -f "$DONE_MARKER" ]; then
  echo "[SKIP] user-data already completed at: $(cat "$DONE_MARKER")"
  exit 0
fi

# --- timezone: JST ---
timedatectl set-timezone Asia/Tokyo
echo "[OK] timezone=Asia/Tokyo"

# --- swap 2GB (incident 2026-05-07-t3micro-oom 対策) ---
SWAPFILE=/swapfile
if [ -f "$SWAPFILE" ] && swapon --show 2>/dev/null | grep -q "$SWAPFILE"; then
  echo "[SKIP] swap already active at $SWAPFILE"
elif [ -f "$SWAPFILE" ]; then
  echo "[..] swapfile exists but not active; activating"
  swapon "$SWAPFILE"
  echo "[OK] swap activated"
else
  echo "[..] creating 2GB swap at $SWAPFILE"
  fallocate -l 2G "$SWAPFILE"
  chmod 600 "$SWAPFILE"
  mkswap "$SWAPFILE"
  swapon "$SWAPFILE"
  if ! grep -q "$SWAPFILE" /etc/fstab; then
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
  fi
  echo "[OK] swap=2GB created and persisted in /etc/fstab"
fi

# --- dnf retry helper (issue #81) ---
# cloud-init は同一 instance-id では user_data を再実行しない仕様。
# dnf が一時的ネットワーク障害で fail すると bootstrap が永久失敗するため、
# 3 回 retry + 指数的ウェイト（10s/20s）で耐性を持たせる。
dnf_with_retry() {
  local label="$1"; shift
  local i wait
  for i in 1 2 3; do
    if dnf "$@"; then
      echo "[OK] $label (attempt $i)"
      return 0
    fi
    if [ "$i" -eq 3 ]; then
      echo "[ERROR] $label failed after 3 attempts"
      return 1
    fi
    wait=$((i * 10))
    echo "[..] $label attempt $i failed, retrying in ${wait}s"
    sleep "$wait"
  done
}

# --- パッケージ更新 ---
# 注意: AL2023 は curl-minimal がプリインストール済（incident 2026-05-07-curl-minimal-conflict）。
# 本フェーズでは curl の install を行わないため update のみで衝突は起きない。
echo "[..] dnf update (with retry)"
dnf_with_retry "dnf update" update -y --quiet

# --- 必要パッケージ install ---
# nginx: 起動完了を HTTP で確認するためのプレースホルダ
# git:   後続フェーズでアプリを clone する基礎
echo "[..] dnf install: nginx, git (with retry)"
dnf_with_retry "dnf install nginx git" install -y nginx git

# --- nginx 用 起動マーカー HTML を配置 ---
mkdir -p /usr/share/nginx/html
cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html lang="ja">
<head><meta charset="UTF-8"><title>recipe-board EC2 bootstrap</title></head>
<body>
<h1>recipe-board: EC2 bootstrap successful</h1>
<p>Phase 4 B-5-ε (user_data.sh のみ・アプリ未配置)</p>
<p>completed_at: $(date -Is)</p>
<p>hostname: $(hostname)</p>
</body>
</html>
HTML
echo "[OK] nginx index.html written"

# --- nginx 起動 + 自動起動有効化 ---
systemctl enable --now nginx
echo "[OK] nginx enabled & started"

# --- 完了マーカー（idempotency 用）---
date -Is > "$DONE_MARKER"
echo "===== user-data done: $(cat "$DONE_MARKER") ====="
