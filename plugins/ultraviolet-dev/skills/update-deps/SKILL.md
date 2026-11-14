---
name: update-deps
description: Update Ultraviolet-App's proxy dependencies (@titaniumnetwork-dev/ultraviolet, @tomphttp/bare-server-node, ultraviolet-static) and Express safely, then verify nothing broke. Trigger with "update ultraviolet", "bump dependencies", "new UV release", "npm audit", or "update the frontend".
argument-hint: "[package name, or 'all']"
---

# /update-deps

Update dependencies one at a time and verify after each. Scope is `$1` (default: `all`).

## Know the dependencies

| Package                            | Source                                          | Risk                                                                                                                                                                                |
| ---------------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@titaniumnetwork-dev/ultraviolet` | npm                                             | **High.** Its config keys and file names (`uv.bundle.js`, `sw.js`, …) must match what `ultraviolet-static`'s `uv.config.js` and `register-sw.js` expect.                            |
| `@tomphttp/bare-server-node`       | npm                                             | **High.** The Bare protocol version must be one the UV client speaks. `createBareServer`, `shouldRoute`, `routeRequest`, `routeUpgrade` and `close` are all used in `src/index.js`. |
| `ultraviolet-static`               | `github:titaniumnetwork-dev/Ultraviolet-Static` | **Medium.** Not versioned; the lockfile pins a commit. Updating means moving to the latest commit on GitHub.                                                                        |
| `express`                          | npm                                             | Low within 4.x. A 5.x upgrade is a separate, deliberate change.                                                                                                                     |

## Steps

1. Record the current state: `npm ls --depth=0`, and run the smoke test so you have a baseline.
2. For each package in scope:
   - Read its changelog or releases (use `~~source control` if connected) for breaking changes, especially major versions.
   - Update it: `npm install <pkg>@<version>`, or `npm install github:titaniumnetwork-dev/Ultraviolet-Static` for the static frontend.
   - If the UV major version changed, check that `uv.config.js` in the new static package still lists files that exist in `uvPath`:
     `ls $(node -e "import('@titaniumnetwork-dev/ultraviolet').then(m=>console.log(m.uvPath))")`
   - Restart the server and run the `smoke-test` skill. If it fails, revert that one package (`git checkout package.json package-lock.json && npm ci`) and report why.
3. Run `npx eslint src`.
4. Summarize as a table: package, old version, new version, notable changes, smoke-test result.
5. Commit `package.json` and `package-lock.json` together, one commit per package if any were risky.

Never run `npm audit fix --force` here; it can jump major versions of the proxy packages and break the protocol pairing.
