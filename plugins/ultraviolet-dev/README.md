# ultraviolet-dev

A Claude plugin for working on this repository, using the
[knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) structure.

## Install (Claude Code)

From the repository root:

```bash
claude plugin marketplace add ./
claude plugin install ultraviolet-dev@ultraviolet-app-plugins
```

The skills then fire automatically when relevant, or can be called explicitly,
for example `/ultraviolet-dev:smoke-test`.

## Skills

| Skill                | What it does                                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `run-local`          | Install dependencies and start the server locally, then confirm it is serving.                                      |
| `smoke-test`         | Hit every route the app depends on (`/`, `/uv/*`, `/bare/`, 404) and report pass/fail. Ships `scripts/smoke.sh`.    |
| `deploy-check`       | Pre-deploy checklist for Docker, Heroku, Railway, Koyeb, Replit, or a bare VPS behind a reverse proxy.              |
| `update-deps`        | Safely bump `@titaniumnetwork-dev/ultraviolet`, `@tomphttp/bare-server-node` and `ultraviolet-static`, then verify. |
| `debug-proxy`        | Diagnose "service worker not registered", blank pages, broken WebSockets, 404s on `/uv/` and similar.               |
| `customize-frontend` | Replace or override the stock `ultraviolet-static` frontend without breaking the proxy.                             |

## How the app is wired (shared context for all skills)

- `src/index.js` creates one Node `http` server.
  - Requests where `bare.shouldRoute(req)` is true (path prefix `/bare/`) go to the **Bare server**, which fetches upstream sites.
  - Everything else goes to **Express**: first `ultraviolet-static`'s `publicPath` (frontend and the overriding `uv/uv.config.js`), then `/uv/` → the Ultraviolet package's `uvPath` (bundle, handler, client, sw), then a 404 page.
  - WebSocket `upgrade` events are routed to Bare too; anything else is closed.
- Port comes from `PORT` (default `8080`). Listens on all interfaces.
- The browser side registers `/uv/sw.js` with scope `/uv/service/`. Service workers need **HTTPS** unless the host is `localhost` or `127.0.0.1`.
