# Changelog

All notable user-visible changes to the FreshRSS TOS application package.

## 1.30.4-3 — 2026-11-19

### Fixed — App Center listing review remediation
- **C3/C4/C5** Added `PRIVACY.md` (retention, user rights, security measures,
  third-party sharing, deletion channel) and linked it from the package Help field.
- **C6/C8** Disclosed every outbound endpoint: subscribed feed servers, WebSub
  hubs advertised by feeds, and optional update checks.
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
