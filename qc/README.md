# The Nest — QC walkthrough (Playwright)

Records video + labelled screenshots of every screen/feature against the
deployed app. Run on **every release** (see `../docs/versioning.md`).

```bash
../tool/run-qc.sh                                  # https://nestwithin.mrrado.com
QC_BASE_URL=https://staging... ../tool/run-qc.sh   # another environment
QC_ADMIN_PASSWORD=… ../tool/run-qc.sh              # also capture the /nirvana dashboard
```

Artifacts → `runs/v<version>-b<build>_<date>_<time>/` (`screenshots/`, `videos/`,
`RESULTS.md`). The app renders to a canvas, so navigation uses fixed-viewport
(412×915) tap coordinates defined in `e2e/qc/_helpers.ts` — update them if the
layout changes. The `/nirvana` admin page is plain HTML and uses DOM selectors.
