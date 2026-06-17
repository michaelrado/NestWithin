# The Nest — Versioning & QC Policy

Single source of truth: **`/version.json`** at the repo root.

```json
{ "name": "Nest Within", "version": "0.1.0", "build": 1 }
```

- **`version`** — semantic version (`MAJOR.MINOR.PATCH`), bumped intentionally for releases.
- **`build`** — monotonically increasing counter, **incremented automatically on every commit**.

Same scheme as **FairGames** (`docs/versioning.md` there).

## How it flows
```
version.json ──tool/gen-version.sh──► lib/version.dart   (shown in the app UI)
             └──────────────────────► pubspec.yaml `version:` (Android/iOS build)
```

## Automatic build increment + commit stamping
Git hooks live in **`.githooks/`**, activated once with:
```bash
git config core.hooksPath .githooks
```
- **`pre-commit`** → runs `tool/bump-build.sh` (increments `build`, regenerates
  `lib/version.dart` + syncs `pubspec.yaml`) and stages them.
- **`prepare-commit-msg`** → appends a `Nest Within vX.Y.Z (build N)` trailer to
  the commit message (above any `Co-Authored-By`).

## Bumping the semantic version
```bash
./tool/bump-build.sh 0.2.0    # sets version=0.2.0 and increments build
# or edit version.json's "version" by hand; the next commit regenerates artifacts
```
PATCH = fix, MINOR = feature, MAJOR = breaking. The `build` counter only ever
moves forward — never reset it.

## QC on every release
Run the Playwright QC walkthrough as part of every release. It records a video
and labelled screenshots of every screen/feature against the deployed app:

```bash
./tool/run-qc.sh                                   # against https://nestwithin.mrrado.com
QC_BASE_URL=https://staging... ./tool/run-qc.sh    # another environment
QC_ADMIN_PASSWORD=… ./tool/run-qc.sh               # also capture the /nirvana dashboard
```

Artifacts are written to a **version- + date/time-stamped** folder:
```
qc/runs/v<version>-b<build>_<YYYY-MM-DD>_<HHMMSS>/
  screenshots/<feature>/NN-label.png
  videos/<feature>--<test>.webm
  RESULTS.md            # every test, status, duration, links
  playwright-report.json
```

Release checklist:
1. Bump version if warranted (`./tool/bump-build.sh X.Y.Z`), commit (build auto-increments).
2. Deploy (`./deploy/deploy-web.sh`, `./deploy/deploy-api.sh`) and build the APK.
3. `./tool/run-qc.sh` → review `RESULTS.md` and the screenshots/videos.
