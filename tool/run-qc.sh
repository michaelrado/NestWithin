#!/usr/bin/env bash
# The Nest QC walkthrough — runs the Playwright QC suite against a real
# environment, recording video + labelled screenshots for every screen, and
# writes everything to qc/runs/v<version>-b<build>_<date>_<time>/.
# Mirrors FairGames' scripts/run-qc.sh. Run this on every release.
#
#   ./tool/run-qc.sh                                  # https://nestwithin.mrrado.com
#   QC_BASE_URL=https://staging... ./tool/run-qc.sh   # another environment
#   QC_ADMIN_PASSWORD=… ./tool/run-qc.sh              # also capture /nirvana dashboard
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

VERSION=$(python3 -c "import json;print(json.load(open('$ROOT/version.json'))['version'])")
BUILD=$(python3 -c "import json;print(json.load(open('$ROOT/version.json'))['build'])")
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M%S)
export QC_RUN_DIR="${QC_RUN_DIR:-$ROOT/qc/runs/v${VERSION}-b${BUILD}_${DATE}_${TIME}}"
mkdir -p "$QC_RUN_DIR"

TARGET="${QC_BASE_URL:-https://nestwithin.mrrado.com}"
echo "QC run → $QC_RUN_DIR"
echo "Target  → $TARGET"

cd "$ROOT/qc"
[ -d node_modules ] || npm install --no-audit --no-fund

EXIT=0
npx playwright test -c playwright.qc.config.ts "$@" || EXIT=$?

node "$ROOT/tool/qc-report.mjs" "$QC_RUN_DIR" "$VERSION" "$BUILD" "$TARGET" || EXIT=$?

echo
echo "Artifacts: $QC_RUN_DIR"
echo "Results:   $QC_RUN_DIR/RESULTS.md"
exit $EXIT
