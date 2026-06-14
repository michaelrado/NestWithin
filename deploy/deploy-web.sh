#!/usr/bin/env bash
# Build The Nest web bundle and deploy it to the VPS at nestwithin.mrrado.com.
#
# Usage:
#   ./deploy/deploy-web.sh                      # uses defaults below
#   HOST=root@1.2.3.4 ./deploy/deploy-web.sh
#
# The app is fully static (no backend, no secrets), so this just builds the
# Flutter web release, ships it, installs the nginx vhost, and gets a cert.
# Idempotent: safe to re-run any time. Mirrors EmojiKeno's deploy flow.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

HOST="${HOST:-root@192.168.1.11}"
DOMAIN="${DOMAIN:-nestwithin.mrrado.com}"
WEBROOT="${WEBROOT:-/var/www/nestwithin}"
FLUTTER="${FLUTTER:-$HOME/development/flutter/bin/flutter}"
EMAIL="${EMAIL:-admin@mrrado.com}"

pass() { printf "  \033[1;32mPASS\033[0m %s\n" "$*"; }
fail() { printf "  \033[1;31mFAIL\033[0m %s\n" "$*"; exit 1; }

echo "== 1. regenerate version + build web release =="
[ -x tool/gen-version.sh ] && tool/gen-version.sh || true
"$FLUTTER" build web --release
pass "built build/web"

echo "== 2. ship bundle to $HOST:$WEBROOT =="
TARBALL="$(mktemp --suffix=.tgz)"
tar czf "$TARBALL" -C build/web .
scp -q "$TARBALL" "$HOST:/tmp/nestwithin-web.tgz"
ssh "$HOST" "rm -rf '$WEBROOT' && mkdir -p '$WEBROOT' && tar xzf /tmp/nestwithin-web.tgz -C '$WEBROOT' && rm -f /tmp/nestwithin-web.tgz"
rm -f "$TARBALL"
pass "deployed static files"

echo "== 3. install nginx vhost =="
scp -q deploy/nginx/nestwithin.conf "$HOST:/tmp/nestwithin.conf"
ssh "$HOST" "
  set -e
  cp /tmp/nestwithin.conf /etc/nginx/sites-available/nestwithin.conf
  rm -f /tmp/nestwithin.conf
  ln -sf /etc/nginx/sites-available/nestwithin.conf /etc/nginx/sites-enabled/nestwithin.conf
  mkdir -p /var/www/html
  nginx -t && systemctl reload nginx
"
pass "nginx vhost installed and reloaded"

echo "== 4. obtain/renew TLS cert =="
ssh "$HOST" "certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect"
pass "certbot done"

echo "== 5. verify =="
code=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/")
[ "$code" = "200" ] && pass "https://$DOMAIN/ -> $code" || fail "https://$DOMAIN/ -> $code"
echo "Done. https://$DOMAIN/"
