#!/usr/bin/env bash
# Smoke-test an Ultraviolet-App instance. Usage: smoke.sh [base-url]
set -u
BASE="${1:-http://localhost:8080}"
BASE="${BASE%/}"
fail=0

check() { # path expected-status [must-contain]
  local path="$1" want="$2" needle="${3:-}" body code
  body=$(curl -s -m 10 -w $'\n%{http_code}' "$BASE$path") || true
  code="${body##*$'\n'}"
  body="${body%$'\n'*}"
  if [[ "$code" != "$want" ]]; then
    printf 'FAIL  %-22s got %s, want %s\n' "$path" "$code" "$want"; fail=1; return
  fi
  if [[ -n "$needle" && "$body" != *"$needle"* ]]; then
    printf 'FAIL  %-22s %s but missing "%s"\n' "$path" "$code" "$needle"; fail=1; return
  fi
  printf 'PASS  %-22s %s\n' "$path" "$code"
}

echo "Smoke-testing $BASE"
check /                  200 "<html"
check /uv/uv.config.js   200 "bare:"
check /uv/uv.bundle.js   200
check /uv/uv.handler.js  200
check /uv/uv.client.js   200
check /uv/sw.js          200
check /bare/             200 '"versions"'
check /this-should-404   404
exit $fail
