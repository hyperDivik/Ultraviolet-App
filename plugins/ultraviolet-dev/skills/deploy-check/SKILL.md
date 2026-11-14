---
name: deploy-check
description: Pre-deploy checklist for Ultraviolet-App on Docker, docker-compose, Heroku, Railway, Koyeb, Replit, or a VPS behind nginx/Caddy. Trigger with "deploy this", "is it ready to ship?", "deploying to <platform>", "set up a reverse proxy", or "docker build is failing".
argument-hint: "[target: docker | heroku | railway | koyeb | replit | vps]"
---

# /deploy-check

Get a deploy right the first time. Target is `$1`; if none is given, ask which platform.

## 1. Universal checks (always run)

- [ ] `npm ci --omit=dev` succeeds. The lockfile is in sync with `package.json`; CI and Docker both use `--frozen-lockfile`.
- [ ] `npx eslint src` is clean (the repo has an ESLint workflow).
- [ ] The app reads **`PORT`** from the environment and does not hard-code it. Most platforms inject `PORT`.
- [ ] The start command is `npm start` (that is, `node src/index.js`).
- [ ] The public URL will be **HTTPS**. Without it the service worker will not register and the proxy will not work, except on localhost.
- [ ] Smoke test passes locally (`smoke-test` skill).

## 2. Target-specific checks

**Docker / compose**

- Build: `docker compose build` (uses `docker/Dockerfile` with `NPM_BUILD=npm ci --omit=dev --frozen-lockfile`).
- The release image copies **only** `src/index.js`, `package.json` and `node_modules`. If the user added new source files or a local `public/` folder, the `COPY --from=devel` lines must be extended or those files will be missing in production.
- The container exposes 8080 and has a curl health check on `/`. If `PORT` is changed, update `EXPOSE`, the health check and the compose `ports` mapping together.
- CI (`.github/workflows/docker-image.yml`) builds for `linux/amd64,linux/arm64` and needs `DOCKERUSERNAME`/`DOCKERPASSWORD` secrets to push.

**Heroku / Railway / Koyeb**

- No Procfile is needed: `npm start` is detected. Make sure the Node version on the platform is 16 or newer.
- These platforms terminate TLS and support WebSockets. Confirm WebSocket support is not disabled for the service.

**Replit**

- `.replit` and `replit.nix` already exist. Use the HTTPS `*.repl.co` / `*.replit.dev` URL, not the internal port.

**VPS behind a reverse proxy**

- The proxy must forward **everything**, including `/bare/` and `/uv/service/`, and must pass WebSocket upgrades. For nginx:
  ```nginx
  location / {
      proxy_pass http://127.0.0.1:8080;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_buffering off;
  }
  ```
- Get TLS with Let's Encrypt (certbot or Caddy).
- Run under a process manager (systemd or pm2) that sends SIGTERM on stop; the app shuts down cleanly on it.

## 3. After deploy

Run the `smoke-test` skill against the public URL, then open it in a browser and load one site through it. Report results as a checklist with ✅/❌ and a fix for each ❌.
