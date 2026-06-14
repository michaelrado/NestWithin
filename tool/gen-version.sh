#!/usr/bin/env bash
# Regenerate version artifacts from the single source of truth: version.json.
# Writes lib/version.dart (shown in the app UI) and syncs the pubspec.yaml
# version line. Safe to run by hand. Mirrors EmojiKeno's tool/gen-version.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Read version & build first, then the (possibly multi-word) name as the rest.
read -r VERSION BUILD NAME < <(python3 -c '
import json
d = json.load(open("version.json"))
print(d["version"], d["build"], d.get("name","Nest Within"))
')

cat > lib/version.dart <<EOF
// AUTO-GENERATED from /version.json by tool/gen-version.sh — do not edit.
const String kAppName = '$NAME';
const String kAppVersion = '$VERSION';
const int kAppBuild = $BUILD;
const String kAppVersionLabel = 'v$VERSION (build $BUILD)';
EOF

python3 - "$VERSION" "$BUILD" <<'PY'
import re, sys
version, build = sys.argv[1], max(1, int(sys.argv[2]))  # versionCode must be >= 1
src = open("pubspec.yaml").read()
src = re.sub(r"^version: .*$", f"version: {version}+{build}", src, count=1, flags=re.M)
open("pubspec.yaml", "w").write(src)
PY

echo "version: $NAME v$VERSION build $BUILD -> lib/version.dart + pubspec.yaml"
