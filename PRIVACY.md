# Privacy Policy — FreshRSS for TerraMaster TOS 7

This policy describes how the **FreshRSS** Docker application package
(`freshrssdocker`) handles data when installed on your TerraMaster NAS.

- Package: `freshrssdocker` (TOS 7 App Center, Docker application)
- Upstream software: [FreshRSS](https://github.com/FreshRSS/FreshRSS) 1.30.4
- Publisher: Moechz

## 1. Scope

The application runs the official `freshrss/freshrss` Docker Hub image,
unmodified, as a non-root container (uid 1000). This policy covers the package
and the default configuration. Extensions you install yourself may have their
own behaviour.

## 2. Data stored on your NAS

Everything FreshRSS needs is stored locally, under
`/Volume1/DockerAppData/freshrssdocker/`:

| Data | Where | Why |
|---|---|---|
| Feed subscriptions, categories, read/starred state | `data/` (SQLite) | Core functionality |
| Cached article content and full-text archives (if enabled) | `data/` | Offline reading |
| User accounts, password hashes, API passwords | `data/` | Authentication |
| Application settings, logs | `data/` | Operation and troubleshooting |
| User-installed extensions | `extensions/` | Optional features |

Nothing in this list is uploaded to the publisher or to TerraMaster.

## 3. Data sent off your NAS

FreshRSS is a feed reader: it periodically fetches the feeds **you** subscribe
to. Requests go directly from your NAS to those feed servers and include the
feed URL and standard HTTP headers (user agent, IP address). No account data or
reading history is sent.

Optional features that cause outbound requests, only when enabled by you:

- **Favicon / site icon fetching** — requests the site's icon from the feed's domain.
- **WebSub / PubSubHubbub** — subscription handshakes with the hub advertised by a feed.
- **Full-text retrieval extensions** — fetch the linked article page.
- **Update checks and extension downloads** — contact GitHub / the extension source you configured.

The publisher collects no telemetry, analytics or crash reports, and operates no
server that receives data from this application.

## 4. Third parties

| Recipient | Data | Purpose |
|---|---|---|
| Feed servers you subscribe to | Feed URL, HTTP headers | Retrieve feeds and articles |
| WebSub hubs advertised by feeds | Topic URL, callback URL | Push notifications for new articles |
| GitHub (if update checks enabled) | HTTP request metadata | Extension/version information |

No data is sold or shared for advertising. The publisher does not receive any of
the above.

## 5. Retention

Data is kept for as long as the application is installed and you keep it.
Article retention can be limited in FreshRSS settings (per-feed or global).
Uninstalling the application with data removal, or deleting
`/Volume1/DockerAppData/freshrssdocker/`, deletes all of it.

## 6. Your rights

You control the data directly on the NAS:

- **Access / portability** — export feeds and articles from FreshRSS (SQLite
  database or OPML export for subscriptions).
- **Rectification** — edit subscriptions, categories and account data in the UI.
- **Erasure** — delete individual articles or feeds in the UI, or delete the
  data directory to remove everything.
- **Restriction** — disable any optional network feature listed in §3.

Because the publisher never receives your data, there is nothing to request from
the publisher; all requests are handled locally by you.

## 7. Security measures

- The container runs as uid 1000 (non-root), without privileged mode, host
  networking, or access to the Docker socket.
- Data lives in a directory readable and writable only by that user.
- The web UI is served over plain HTTP on your LAN; if you expose it to the
  internet, put it behind HTTPS (reverse proxy) and enable authentication.

## 8. Deletion channel

To delete all data: App Center → uninstall the application **and** remove
`/Volume1/DockerAppData/freshrssdocker/`. There is no server-side copy to
delete.

## 9. Changes

Material changes to this policy are published in this file and noted in the
package changelog with the version that introduced them.

## 10. Contact

Open an issue at <https://github.com/Moechz/freshrss/issues>.
