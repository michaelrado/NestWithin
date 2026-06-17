#!/usr/bin/env bash
# Build & deploy the Nest API (Node + Express + SQLite) to the VPS as a
# systemd service listening on 127.0.0.1:8091.
#
#   ./deploy/deploy-api.sh
#   HOST=root@1.2.3.4 ./deploy/deploy-api.sh
#
# The API is exposed publicly at https://nestwithin.mrrado.com/api via the web
# vhost (deploy/nginx/nestwithin.conf) — run ./deploy/deploy-web.sh to install
# that routing. No separate domain or cert needed.
#
# Idempotent. First run installs Node + build tools if missing and writes a
# starter /etc/nest-api.env (Mailgun blank → email runs in STUB mode). Re-run to
# ship new code; your /etc/nest-api.env is preserved.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

HOST="${HOST:-root@192.168.1.11}"
APPDIR="${APPDIR:-/opt/nest-api}"

pass() { printf "  \033[1;32mPASS\033[0m %s\n" "$*"; }
fail() { printf "  \033[1;31mFAIL\033[0m %s\n" "$*"; exit 1; }

echo "== 1. ensure Node + build tools on $HOST =="
ssh "$HOST" 'bash -s' <<'REMOTE'
set -e
if ! command -v node >/dev/null 2>&1; then
  echo "installing Node.js LTS…"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi
if ! dpkg -s build-essential >/dev/null 2>&1; then
  apt-get install -y --no-install-recommends build-essential python3
fi
echo "node $(node --version)"
REMOTE
pass "node ready"

echo "== 2. ship server code + install deps =="
TARBALL="$(mktemp --suffix=.tgz)"
tar czf "$TARBALL" -C server --exclude=node_modules --exclude='*.db*' --exclude=.env .
scp -q "$TARBALL" "$HOST:/tmp/nest-api.tgz"
rm -f "$TARBALL"
ssh "$HOST" "
  set -e
  mkdir -p '$APPDIR'
  tar xzf /tmp/nest-api.tgz -C '$APPDIR'
  rm -f /tmp/nest-api.tgz
  cd '$APPDIR'
  npm install --omit=dev --no-audit --no-fund
"
pass "code shipped + deps installed"

echo "== 3. config, data dir, systemd service =="
scp -q deploy/systemd/nest-api.service "$HOST:/tmp/nest-api.service"
ssh "$HOST" "
  set -e
  if [ ! -f /etc/nest-api.env ]; then
    SECRET=\$(openssl rand -hex 32)
    cat > /etc/nest-api.env <<EOF
PORT=8091
NEST_DB=/var/lib/nest-api/nest.db
APP_URL=https://nestwithin.mrrado.com
PUBLIC_URL=https://nestwithin.mrrado.com
JWT_SECRET=\$SECRET
MAILGUN_API_KEY=
MAILGUN_DOMAIN=
MAILGUN_REGION=US
MAIL_FROM=The Nest <no-reply@nestwithin.mrrado.com>
EOF
    chmod 600 /etc/nest-api.env
    echo 'wrote starter /etc/nest-api.env (Mailgun blank → stub mode)'
  fi
  mkdir -p /var/lib/nest-api
  chown -R www-data:www-data /var/lib/nest-api '$APPDIR'
  cp /tmp/nest-api.service /etc/systemd/system/nest-api.service
  rm -f /tmp/nest-api.service
  systemctl daemon-reload
  systemctl enable nest-api >/dev/null 2>&1 || true
  systemctl restart nest-api
  sleep 1
  systemctl is-active nest-api || (journalctl -u nest-api -n 30 --no-pager; exit 1)
"
pass "service active"

echo "== 4. verify service locally on the VPS =="
health=$(ssh "$HOST" "curl -s http://127.0.0.1:8091/api/health" || true)
echo "  health: $health"
echo "$health" | grep -q '"ok":true' \
  && pass "nest-api healthy on 127.0.0.1:8091" \
  || fail "service did not report healthy"

echo "Done. Now run ./deploy/deploy-web.sh to expose it at https://nestwithin.mrrado.com/api"
