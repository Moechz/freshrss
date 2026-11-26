# freshrss-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [FreshRSS](https://github.com/FreshRSS/FreshRSS).

## What this is

A four-file TOS Docker application archive (`freshrssdocker.tar.gz`) that installs
FreshRSS on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `freshrssdocker`)
- `freshrssdocker.lang` — 23-language superset (TOS requires 14), generated from `tosapp.json`
- `freshrssdocker.svg` — application icon
- `docker-compose.yml` — one service, image `freshrss/freshrss:1.31.0`

## How it works

| | |
|---|---|
| Container image | `freshrss/freshrss:1.31.0` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8029/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"`, `cap_drop: [ALL]`, `no-new-privileges` |
| Persistent data | `/var/www/FreshRSS/data` → `/Volume1/DockerAppData/freshrssdocker/data`, `/var/www/FreshRSS/extensions` → `/Volume1/DockerAppData/freshrssdocker/extensions` |
| Logs | `docker logs freshrssdocker` (stdout/stderr) |

`data` holds `config.php`, the SQLite database (or DB settings), users, API
tokens, favicon/article caches and logs; `extensions` holds installed FreshRSS
extensions. Copying `data` and `extensions` is a complete backup.

## Design highlights

- **Non-root.** `user: "1000:1000"`; all capabilities dropped, `no-new-privileges`,
  no `privileged`, no `network_mode: host`, no Docker socket.
- **Entrypoint wrapper.** The upstream image is built to run as root and keeps
  state in root-owned paths, so the compose file replaces the entrypoint with
  `src/entrypoint.sh`. The wrapper runs `cli/prepare.php` (exactly like the
  official entrypoint) to create `data/users`, `data/tokens`, `data/favicons`,
  `data/cache` and `data/PubSubHubbub`, then starts Apache as uid 1000 on port
  8080 with a private, writable copy of the Apache configuration. The FreshRSS
  code itself is unmodified.
- **Fixed image tag, never `:latest`**, Docker Hub only.
- **Health check** probes container port 8080 (retries 5, 60 s start period).
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip
  without a timestamp, plus the review-standards self-check.
- **No root cron.** The image cron needs root and is not started, so feeds
  refresh on demand from the web UI, or from an external scheduler
  (for example a TOS task calling
  `http://<NAS-IP>:8029/i/?c=feed&a=actualize` while logged in, or a
  `docker exec … php /var/www/FreshRSS/app/actualize_script.php` task).
- **API optional, off by default.** The Google Reader / Fever API is enabled in
  FreshRSS → Administration → Authentication when you want mobile clients.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `data` | config.php, SQLite database, users, API tokens, favicon/article caches, logs | first run / installer | grows with subscriptions and articles | never overwritten; back it up |
| `extensions` | installed FreshRSS extensions | when an extension is installed | grows with extensions | managed by the user; back it up |

## Data and uninstall

- **Where the data is:**
  `/Volume1/DockerAppData/freshrssdocker/data` (database, users, settings,
  caches) and `/Volume1/DockerAppData/freshrssdocker/extensions`.
- **Backup:** copy those two directories while the container is stopped, or use
  FreshRSS → Import/Export for subscriptions (OPML).
- **Uninstall:** App Center → uninstall. The data directory is kept on purpose;
  delete `/Volume1/DockerAppData/freshrssdocker/` yourself to remove all data.
  Nothing is written anywhere else, and there is no uninstall hook that leaves
  files behind.
- **Upgrade:** install the newer package over the old one. FreshRSS applies its
  own schema migrations on first start; data stays in place.

## Build

```bash
scripts/build.sh                          # one architecture -> out/freshrssdocker.tar.gz
scripts/build.sh 1.31.0-1                 # explicit version
scripts/build.sh 1.31.0-1 aarch64         # explicit platform
scripts/build-dual.sh 1.31.0-1            # both architectures -> out/freshrssdocker_{x86_64,aarch64}.tar.gz
```

The build renders `src/freshrssdocker.lang` from `tosapp.json`
(`scripts/render-lang.py`), stages the four files, injects `help` / `official` /
`publisher` from `tosapp.json` (so the packaged Help link can never drift from
the spec again), substitutes the version/platform placeholders, embeds
`src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes
CRLF/BOM/AppleDouble, then runs `tools/verify.py` — a review-standards self-check
(archive layout, JSON validity, required fields, Help → PRIVACY.md, 14+ language
coverage, no ASCII `;` in `.lang`, version consistency, Docker-Hub-only images,
fixed tag, reserved/recommended host ports, non-root user, capability drop,
per-service healthcheck/TZ/restart, data path below the application data root,
never the `/Volume*` wildcard, comment-free sequence blocks, `x-app-meta`
position, no literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/freshrssdocker_x86_64.tar.gz   # official spec check
TOSAppSelfTestingTool -c out/freshrssdocker_aarch64.tar.gz

# isolated runtime check (temporary port + temporary data dir, never the
# production DockerAppData directory):
python3 ../stage.py . --timeout 300     # container healthy, non-root, HTTP
bash test/smoke.sh http://127.0.0.1:<staged-port>   # install -> login -> API
python3 ../smoke.py . --timeout 300     # runs stage + the smoke test above
```

`test/smoke.sh` drives the real first-run flow over HTTP: language → requirements
→ SQLite database → administrator account → login → API route. It exits non-zero
when the app cannot be installed or used.

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README + PRIVACY).
2. Release **tag `v1.31.0-1`** with assets `freshrssdocker_x86_64.tar.gz`,
   `freshrssdocker_x86_64.tar.gz.sha256`, `freshrssdocker_aarch64.tar.gz`,
   `freshrssdocker_aarch64.tar.gz.sha256`.
3. Developer platform → application records `freshrssdocker` for `x86_64` and
   `aarch64` (same app id, one record per architecture).
4. Version Management → add version `1.31.0-1` for each architecture and submit
   the matching asset.

## Architecture support

`freshrss/freshrss:1.31.0` is a multi-arch OCI index:

```
sha256:31b0acfcb8e11600aa6ce697ff8d9d7ea620c85d766e5e764f487b433d20d066
  linux/amd64   sha256:0e96aa405358d6c85c4e99879693abdf21177f2898922fd4630b9a236715a241
  linux/arm64   sha256:97d4bd1ac3a00eaa7ff9b759d98490e149e6d4fa9619c982c345268f1921a660
  linux/arm/v7  sha256:dcca3c4afee770538976c8960cfead83c9953adc4b9dcb9bbf2646a2542b20fd
```

Both packages reference the same tag; the Docker engine pulls the image that
matches the NAS architecture.

## License / branding

FreshRSS is distributed by its upstream authors under **AGPL-3.0**
(see `LICENSE`). The container image is the official image from Docker Hub
(`freshrss/freshrss:1.31.0`) and is used unmodified; no upstream source code is
redistributed here. "FreshRSS" and the FreshRSS logo belong to the upstream
project; this packaging is an independent community submission by Moechz and is
not affiliated with the upstream project or TerraMaster.

## Limitations

- There is no default account. The first-run page is open until you create the
  administrator; complete it immediately after installation.
- The API (Google Reader / Fever) is disabled by default; enable it in the
  FreshRSS administration settings if you need mobile clients.
- No automatic background refresh: the image cron needs root, so feeds refresh
  on demand from the web UI or from an external scheduler.
- SQLite is used by default. Very large feed collections may benefit from an
  external database, which requires editing the configuration.
- Plain HTTP on the LAN; do not expose the published port to the internet
  without a TLS reverse proxy.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.

## Repository layout

```
src/                        four shipped files (config.ini, lang, svg, compose)
src/entrypoint.sh           rootless wrapper (prepare.php + Apache on 8080)
scripts/build.sh            build + self-verify one architecture
scripts/build-dual.sh       build both architectures, keep <appid>_<arch>.tar.gz assets
scripts/render-lang.py      render src/<appid>.lang from tosapp.json
tools/verify.py             review-standards self-check (hard gate)
test/smoke.sh               functional smoke: install -> login -> API
test/install-and-verify.sh  on-device E2E (requires uid 0; do NOT run on a production NAS)
PRIVACY.md                  privacy policy, the package Help target
CHANGELOG.md                per-version remediation notes
```

## Privacy

See [PRIVACY.md](PRIVACY.md). The package collects no telemetry and performs no
update check; the outbound requests are the feeds you subscribe to, their
favicons, optional WebSub hubs, and the GitHub extension catalogue (which can be
disabled). All application data stays in
`/Volume1/DockerAppData/freshrssdocker/`.
