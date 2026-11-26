# Changelog

All notable user-visible changes to the FreshRSS TOS application package.

## 1.31.0-1 — 2026-11-26

### Fixed — second-round App Center review remediation (C5, C8, T1, F5, install)

- **T1 — upstream security upgrade.** Base image bumped from
  `freshrss/freshrss:1.30.4` to `freshrss/freshrss:1.31.0`, the security release
  published 2026-11-23 that fixes several critical (local and remote)
  vulnerabilities, including the search-query exploits and the PHP 8.1 advisory.
  The image is the multi-arch OCI index
  `sha256:31b0acfcb8e11600aa6ce697ff8d9d7ea620c85d766e5e764f487b433d20d066`
  (linux/amd64 + linux/arm64 + linux/arm/v7). PHP 8.4, SQLite data and the
  `data/` layout are unchanged, so no migration step is needed — the container
  starts on the existing data directory.
- **C5 — the Help link really opens the privacy policy now.** 1.30.4-3 was
  rejected again on C5 because the *packaged* `config.ini` still carried the old
  `https://github.com/Moechz/freshrss/issues` value: `tosapp.json.help` had been
  updated but `scripts/build.sh` copied `src/config.ini` verbatim. `build.sh` now
  injects `help` / `official` / `publisher` from `tosapp.json` and fails the
  build unless the target is a public `…/PRIVACY.md` URL. `tools/verify.py`
  enforces the same invariant on the staged package.
- **C8 — explicit third-party endpoint disclosure.** `PRIVACY.md` now carries a
  numbered table with endpoint, trigger, data sent and destination/region:
  subscribed feeds, favicon/icon fetches, WebSub hubs (off by default), the
  GitHub extension catalogue (`raw.githubusercontent.com`, ≤1 request/24 h,
  can be disabled in Settings → Privacy), extension downloads from GitHub, and
  full-text extensions. It also states that FreshRSS performs **no** version
  update check — the earlier text claimed one.
- **F5 — description matches the delivered features.** The English /
  `zh-cn` / `zh-hk` descriptions now say that the API is optional and off by
  default, and the `important` note no longer claims a 20-minute automatic
  refresh (the image cron needs root and is not started in a non-root
  container). `.lang` is now generated from `tosapp.json` by
  `scripts/render-lang.py`, so description text cannot drift from the spec
  again.
- **Install / first-run fix (the "check did not pass" finding).** The wrapper
  skipped `cli/prepare.php`, so `data/users`, `data/tokens`, `data/favicons`,
  `data/cache` and `data/PubSubHubbub` were missing: the first-run page emitted
  `touch(): Unable to create file …` warnings, the web installer could not
  create the administrator, favicon caching and API tokens were broken. The
  entrypoint now runs `cli/prepare.php` like the official one (a full install
  through the web installer is now part of `test/smoke.sh`).
- **Hardening.** `cap_drop: [ALL]` and `no-new-privileges` added; healthcheck
  retries raised to 5 with a 60 s start period so a slow first start on ARM does
  not trip the platform's installation check.
- **New gate.** `test/smoke.sh` drives the real first-run flow (installer →
  SQLite → administrator → login → API route) and fails the build when the app
  is not usable.

## 1.30.4-3 — 2026-11-19

### Fixed — first-round App Center listing review remediation
- **C3/C4/C5** Added `PRIVACY.md` (retention, user rights, security measures,
  third-party sharing, deletion channel). *Correction: this round updated
  `tosapp.json.help` only — the packaged `config.ini` kept the old issue-tracker
  URL, which is why C5 was raised again for 1.30.4-3.*
- **C6/C8** Documented outbound endpoints in prose (superseded by the endpoint
  table in 1.31.0-1).
- **C9/F5** Aligned the description with the delivered functionality.
- **C10** Documented the repository layout in `README.md`.
- **T1** Upstream `freshrss/freshrss` 1.30.4 is the current release; inherited
  components will be upgraded with the next upstream image.

## 1.30.4-2 — 2026-11-09

### Added
- First release. FreshRSS (`freshrss/freshrss:1.30.4`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8029 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/freshrssdocker/`.
