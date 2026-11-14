---
name: debug-proxy
description: Diagnose Ultraviolet-App failures - "service worker not registered", "Failed to register service worker", blank or broken proxied pages, WebSocket sites not working, 404s on /uv/ files, Bare server errors, port conflicts, or a deploy that works locally but not in production. Trigger with any error message or symptom from the app.
argument-hint: "<symptom or error message>"
---

# /debug-proxy

Find the root cause of the symptom in `$1`. Ask for the symptom if none is given. Reproduce first; don't guess.

## Request path (where things can break)

```
Browser ── index.html ── register-sw.js ── registers /uv/sw.js (scope /uv/service/)
   │
   └─ /uv/service/<encoded-url> ─ service worker rewrites ─ fetches /bare/... ─┐
                                                                               ▼
src/index.js: http server ── bare.shouldRoute? ── yes ─ Bare server ─ upstream site
                                     └─ no ─ express: publicPath → /uv/ (uvPath) → 404
```

## Symptom → cause

| Symptom                                              | Likely cause                                                                                                     | Check / fix                                                                                                                    |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| "Service workers cannot be registered without https" | Site served over plain HTTP on a non-localhost host                                                              | Serve over HTTPS (see `deploy-check`). For local testing, use `localhost`, not a LAN IP.                                       |
| "Your browser doesn't support service workers"       | Private/incognito mode in some browsers, Firefox with SW disabled, or an embedded webview                        | Try a normal browser window.                                                                                                   |
| `/uv/uv.bundle.js` etc. return 404                   | Install incomplete, or `/uv/` mount was moved or removed in `src/index.js`                                       | `npm ci`; confirm `app.use("/uv/", express.static(uvPath))` still exists and comes after `express.static(publicPath)`.         |
| Wrong UV config loaded                               | Mount order changed                                                                                              | `publicPath` **must** be mounted before `uvPath`, so the repo's `uv/uv.config.js` overrides the stock one.                     |
| Proxied pages hang or show network errors            | `/bare/` not reachable: a reverse proxy strips it, or a firewall blocks the server's outbound traffic            | `curl <base>/bare/` should return JSON with `versions`. On the server, `curl -I https://example.com` to test outbound access.  |
| WebSocket sites (chat, games) fail                   | Reverse proxy does not forward `Upgrade`/`Connection` headers, or the platform disables WebSockets               | Add the upgrade headers (nginx snippet in `deploy-check`). Upgrades not under `/bare/` are closed on purpose (`socket.end()`). |
| Works locally, not in production                     | HTTPS missing, `PORT` mismatch, or the Docker image is missing a file (release stage copies only `src/index.js`) | Check platform logs (`~~hosting`), `docker run` the image locally, and run the smoke test against it.                          |
| `EADDRINUSE`                                         | Port taken                                                                                                       | `PORT=8081 npm start`, or find the process with `lsof -i :8080`.                                                               |
| Stale behaviour after update                         | Old service worker cached in the browser                                                                         | DevTools → Application → Service Workers → Unregister, then hard reload.                                                       |

## Method

1. Run the `smoke-test` skill against the failing instance. Most server-side causes show up there.
2. If the server side passes, the problem is in the browser: ask for the DevTools Console and Network output (filter `/uv/` and `/bare/`).
3. State the root cause, the evidence, and the smallest fix. Make the fix only if the user agrees, then re-run the smoke test.
