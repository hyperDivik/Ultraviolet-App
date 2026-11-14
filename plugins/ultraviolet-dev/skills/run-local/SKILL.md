---
name: run-local
description: Install dependencies and start the Ultraviolet-App server locally, then confirm it is serving. Trigger with "run the app", "start the proxy", "spin it up locally", "npm start isn't working", or before any manual testing.
argument-hint: "[port]"
---

# /run-local

Start the app and prove it is up. Use port `$1` if given, otherwise `8080`.

## Steps

1. **Check Node.** `node -v` must be 16 or newer (see `engines` in `package.json`). If it is older, stop and say so.
2. **Install.** If `node_modules/` is missing or `package-lock.json` is newer than it, run `npm ci`.
   - `ultraviolet-static` is a GitHub dependency, so the install needs access to github.com. If it fails there, report it as a network problem, not a code problem.
3. **Start in the background.** Use `PORT=<port> npm start` as a background process so the session is not blocked. Never run it in the foreground.
4. **Wait for it.** Poll `curl -s -o /dev/null -w '%{http_code}' http://localhost:<port>/` until it returns 200 (give up after about 15 seconds). If startup fails with `EADDRINUSE`, pick the next free port and say so.
5. **Verify.** Run the `smoke-test` skill's script against the port.
6. **Report** the URL (`http://localhost:<port>`) and the smoke-test result. Remind the user that the proxy only works in a browser on `localhost`/`127.0.0.1` or over HTTPS, because of service-worker rules.

## When done

Leave the server running only if the user wants to keep using it. Otherwise stop it with SIGTERM: `src/index.js` handles that cleanly and closes the Bare server too.
