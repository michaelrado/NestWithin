#!/usr/bin/env bash
# Increment the build number in version.json, then regenerate version artifacts.
# Called automatically by the pre-commit hook (once per commit). Pass a semver as
# $1 to also set the version, e.g. ./tool/bump-build.sh 0.2.0
# Mirrors FairGames' scripts/bump-build.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NEWVER="${1:-}"
python3 - "$NEWVER" <<'PY'
import json, sys
newver = sys.argv[1] if len(sys.argv) > 1 else ""
d = json.load(open("version.json"))
d["build"] = int(d.get("build", 0)) + 1
if newver:
    d["version"] = newver
json.dump(d, open("version.json", "w"), indent=2)
open("version.json", "a").write("\n")
print(f"bumped to v{d['version']} build {d['build']}")
PY

"$ROOT/tool/gen-version.sh"
