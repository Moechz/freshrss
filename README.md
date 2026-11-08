# freshrss-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [FreshRSS](https://github.com/FreshRSS/FreshRSS).

## What this is

A four-file TOS Docker application archive (`freshrssdocker.tar.gz`) that installs
FreshRSS on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `freshrssdocker`)
- `freshrssdocker.lang` — 23-language superset (TOS requires 14)
- `freshrssdocker.svg` — application icon (1269 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `freshrss/freshrss:1.30.4`

## How it works

| | |
|---|---|
| Container image | `freshrss/freshrss:1.30.4` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8029/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/var/www/FreshRSS/data` → `/Volume1/DockerAppData/freshrssdocker/data`, `/var/www/FreshRSS/extensions` → `/Volume1/DockerAppData/freshrssdocker/extensions` |
| Logs | `docker logs freshrssdocker` (stdout/stderr) |

`data` holds `config.php`, the SQLite database (or DB settings), users and feed caches; `extensions` holds installed FreshRSS extensions. Copying `data` and `extensions` is a complete backup.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Non-root.** Runs as `1000:1000` with the mounted data/extensions folders writable.
- **Two volumes, one port.** `/var/www/FreshRSS/data` + `/var/www/FreshRSS/extensions`; only port 80 is published.
- **Health check** probes `/` on port 80.
- **No root cron.** The images cron is disabled because the container is non-root; use the web UI refresh or an external scheduler.
- **Fixed image tag**, Docker Hub only, no privileged mode, no host network, no Docker socket.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `data/config.php` | database and application configuration | first run | small | never overwritten; back it up |
| `data/users` | user accounts and their feed subscriptions | when the first user is created | grows with subscriptions and articles | never overwritten; back it up |
| `extensions` | installed FreshRSS extensions | when an extension is installed | grows with extensions | managed by the user; back it up |
| `/Volume1/DockerAppData/freshrssdocker/data` | FreshRSS application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/freshrssdocker/extensions` | FreshRSS application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/freshrssdocker.tar.gz + .sha256
scripts/build.sh 1.30.4-2   # packaging iteration bump
scripts/build.sh 1.30.4-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/freshrssdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v1.30.4-1`**, assets `freshrssdocker.tar.gz` +
   `freshrssdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `freshrssdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `1.30.4-1` → automated validation → review.

## License / branding

FreshRSS is distributed by its upstream authors under **AGPL-3.0**. The container image is the official image from Docker Hub (`freshrss/freshrss:1.30.4`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

There is no default account. The first-run page is open until you create the administrator; complete it immediately after installation.
SQLite is used by default. Very large feed collections may benefit from an external database, which requires editing the configuration.
Plain HTTP on the LAN; do not expose the published port to the internet without a TLS reverse proxy.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
