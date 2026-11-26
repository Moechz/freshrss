# Privacy Policy — FreshRSS for TerraMaster TOS 7

This policy describes how the **FreshRSS** Docker application package
(`freshrssdocker`) handles data when installed on your TerraMaster NAS. It is
the document the App Center **Help** link opens
(<https://github.com/Moechz/freshrss/blob/main/PRIVACY.md>).

- Package: `freshrssdocker` (TOS 7 App Center, Docker application)
- Upstream software: [FreshRSS](https://github.com/FreshRSS/FreshRSS) 1.31.0
- Container image: `freshrss/freshrss:1.31.0` (Docker Hub, used unmodified)
- Publisher: Moechz

## 1. Scope

The application runs the official `freshrss/freshrss` Docker Hub image,
unmodified, as a non-root container (uid 1000) with all Linux capabilities
dropped. This policy covers the package and its default configuration.
Extensions you install yourself may have their own behaviour.

## 2. Data stored on your NAS

Everything FreshRSS needs is stored locally, under
`/Volume1/DockerAppData/freshrssdocker/`:

| Data | Where | Why |
|---|---|---|
| Feed subscriptions, categories, read/starred state | `data/` (SQLite by default) | Core functionality |
| Cached article content and full-text archives (if enabled) | `data/` | Offline reading |
| User accounts, password hashes, API passwords and API tokens | `data/users/`, `data/tokens/` | Authentication |
| Cached favicons and article images | `data/favicons/`, `data/cache/` | Display and performance |
| Application settings, logs | `data/` | Operation and troubleshooting |
| User-installed extensions | `extensions/` | Optional features |

Nothing in this list is uploaded to the publisher or to TerraMaster. FreshRSS
has no telemetry, no analytics and no crash reporting, and it does not contact
the publisher's servers at any time.

## 3. Data sent off your NAS (third-party endpoints)

FreshRSS is a feed reader: every outbound request is caused by content **you**
choose to follow or by an optional feature you enable. There is no background
reporting and no phone-home.

| # | Endpoint contacted | When | Data sent | Destination / region |
|---|---|---|---|---|
| 1 | The feed URLs **you** subscribe to (any host) | On refresh (manual from the web UI, or from an external scheduler you configure) | The feed URL, standard HTTP headers (User-Agent, IP address, conditional-GET headers, HTTP credentials if you put them in the URL) | The feed publisher's server, wherever it is hosted |
| 2 | The site of each subscribed feed: `<site>/favicon.ico`, `<link rel="icon">` targets and the feed's declared image URL | The first time a feed icon is displayed, then cached in `data/favicons/` | GET request for the icon, standard headers, IP address | The feed's own site, wherever it is hosted |
| 3 | The WebSub / PubSubHubbub hub advertised by a feed (`<link rel="hub">`) | Only if WebSub is enabled (it is **off by default**; the installer enables it only when the instance URL is publicly reachable) | Topic URL and the callback URL of your instance (`http://<your-nas>:8029/…`), plus standard headers | The hub named by the feed publisher |
| 4 | `https://raw.githubusercontent.com/FreshRSS/Extensions/refs/heads/main/extensions.json` | When the extensions page is opened, at most once per 24 h (cached in `data/cache/`) | GET request, standard headers, IP address. No account data | GitHub / Microsoft Azure, United States |
| 5 | GitHub download URLs listed in that catalogue (`github.com`, `raw.githubusercontent.com`) | Only when you install or update an extension | GET request, standard headers, IP address | GitHub / Microsoft Azure, United States |
| 6 | The article URL fetched by a full-text or scraping extension | Only if you install and enable such an extension, and request the full text | The article URL and standard headers | The article's site |
| 7 | Your own API / mobile clients (`/api/greader.php`, `/api/fever.php`) | Only if you enable the API and configure a client | Inbound requests to your NAS; no outbound traffic from the app | Not applicable (client → NAS on your LAN) |

Notes:

- **No update check.** FreshRSS does not poll GitHub or any other server for new
  versions. Upgrading is done by installing a newer package from the App Center.
- **Extension catalogue can be disabled.** FreshRSS → Settings → Privacy →
  "Retrieve extension list" turns endpoint 4 (and therefore 5) off; the app then
  never contacts GitHub.
- **WebSub can be disabled** in the FreshRSS administration settings; it is off
  by default in this package.
- **Image pull is the platform's job.** The Docker image is pulled from Docker
  Hub by the TerraMaster Docker Engine, not by the application. That request
  carries no user data beyond the image name.
- Credentials of your feed accounts (HTTP Basic auth or URLs with tokens) are
  stored in `data/` and sent only to the server that requires them.

## 4. Third parties

The only recipients of data are the servers listed in §3. They are chosen by you
through the feeds you subscribe to and the extensions you install. No data is
sold, shared for advertising, or sent to the publisher or to TerraMaster.

## 5. Retention

Data is kept for as long as the application is installed and you keep it.
Article retention can be limited per feed or globally in the FreshRSS settings.
Uninstalling the application with data removal, or deleting
`/Volume1/DockerAppData/freshrssdocker/`, deletes everything.

## 6. Your rights

You control the data directly on the NAS:

- **Access / portability** — export subscriptions as OPML and articles from the
  web UI, or copy the SQLite database.
- **Rectification** — edit subscriptions, categories and account data in the UI.
- **Erasure** — delete individual articles or feeds in the UI, or delete the data
  directory to remove everything.
- **Restriction** — disable WebSub, the extension list retrieval and any
  optional extension in the FreshRSS settings.

Because the publisher never receives your data, there is nothing to request from
the publisher; every request is handled locally by you.

## 7. Security measures

- The container runs as uid 1000 (non-root), with `cap_drop: [ALL]`,
  `no-new-privileges`, no privileged mode, no host networking and no access to
  the Docker socket.
- The web UI is served over plain HTTP on your LAN; if you expose it to the
  internet, put it behind HTTPS (reverse proxy) and keep authentication enabled.
- The API and WebSub are disabled by default and must be enabled deliberately.
- Only the two data volumes are mounted; the application code inside the image is
  never modified.

## 8. Deletion channel

To delete all data: App Center → uninstall the application **and** remove
`/Volume1/DockerAppData/freshrssdocker/`. There is no server-side copy to delete.

## 9. Changes

Material changes to this policy are published in this file and noted in the
package changelog with the version that introduced them. This revision
(1.31.0-1) adds the explicit endpoint table required by the App Center review
(C8) and corrects the earlier wording about update checks.

## 10. Contact

Open an issue at <https://github.com/Moechz/freshrss/issues>.
