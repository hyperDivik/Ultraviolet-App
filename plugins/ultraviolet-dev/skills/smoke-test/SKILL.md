---
name: smoke-test
description: Smoke-test a running Ultraviolet-App instance by checking every route it depends on (frontend, UV bundle/config/sw, Bare server, 404 handler). Trigger with "is it working?", "test the deploy", "check the instance", after updating dependencies, or after any change to src/index.js.
argument-hint: "[base URL, default http://localhost:8080]"
---

# /smoke-test

Check that an instance is healthy. Use base URL `$1`, defaulting to `http://localhost:8080`.

## Run

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/smoke-test/scripts/smoke.sh" <base-url>
```

If the server is not running and the base URL is local, start it first with the `run-local` skill.

## What it checks

| Route                                                | Expect                    | Why it matters                               |
| ---------------------------------------------------- | ------------------------- | -------------------------------------------- |
| `/`                                                  | 200, HTML                 | Frontend from `ultraviolet-static` is served |
| `/uv/uv.config.js`                                   | 200, contains `bare:`     | The repo's config overrides the stock one    |
| `/uv/uv.bundle.js`                                   | 200                       | Ultraviolet package mounted at `/uv/`        |
| `/uv/uv.handler.js`, `/uv/uv.client.js`, `/uv/sw.js` | 200                       | Service worker can load                      |
| `/bare/`                                             | 200, JSON with `versions` | Bare server answers                          |
| `/this-should-404`                                   | 404                       | Fallback handler works                       |

## Reporting

Show a pass/fail table. For each failure, point to the likely cause:

- `/uv/*` failing → `debug-proxy` (mount order in `src/index.js`, or a broken install)
- `/bare/` failing → Bare server not routed (check `bare.shouldRoute`), or a reverse proxy not forwarding `/bare/`
- Everything failing → the server is not up, or the URL or port is wrong

The script does **not** check WebSockets or the browser-side service worker. Say that if the user is debugging those, and use `debug-proxy`.
