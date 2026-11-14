---
name: customize-frontend
description: Customize the Ultraviolet-App frontend (homepage, branding, search engine, 404 page, styles) by overriding ultraviolet-static without breaking the proxy. Trigger with "change the homepage", "rebrand", "custom UI", "change the default search engine", "edit index.html", or "add my own CSS".
argument-hint: "<what to change>"
---

# /customize-frontend

Make the change described in `$1` while keeping the proxy working.

## Key fact

The frontend lives in `node_modules/ultraviolet-static/public/` and is served from its `publicPath`. **Never edit files in `node_modules`**: they are overwritten on every install and are not committed.

## Approach: local override folder

1. Create `public/` at the repository root and copy in only the files you are changing (for example `index.html`, `index.css`, `search.js`). Keep the original file names.
2. In `src/index.js`, mount the local folder **first**, so it wins over the package:

   ```js
   import { fileURLToPath } from "node:url";
   const localPublic = fileURLToPath(new URL("../public/", import.meta.url));

   app.use(express.static(localPublic)); // 1. your overrides
   app.use(express.static(publicPath)); // 2. stock frontend (fallback)
   app.use("/uv/", express.static(uvPath)); // 3. UV vendor files
   ```

3. If the Docker image is used, add `COPY --from=devel --chown=1000:1000 /app/public public` to the release stage of `docker/Dockerfile`; it does not copy `public/` otherwise.

## Don't break these

- The page must still load `/uv/uv.bundle.js`, `/uv/uv.config.js` and `register-sw.js`, and call `registerSW()` before navigating.
- Navigation must go to `__uv$config.prefix + __uv$config.encodeUrl(url)`.
- Overriding `uv/uv.config.js` is allowed, but `prefix` must stay consistent with the service-worker scope, and `bare` must match the Bare server path (`/bare/`).

## Common changes

- **Default search engine:** change the search template in `index.html` (the `uv-search-engine` input value).
- **Branding:** `index.html`, `index.css`, `uv.png`, `favicon.ico`.
- **404 page:** override `404.html`. The Express fallback serves `join(publicPath, "404.html")`, so point it at your local file too.

## Verify

Restart, run the `smoke-test` skill, then load a site through the new homepage in a browser.
