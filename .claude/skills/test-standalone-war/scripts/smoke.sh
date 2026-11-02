#!/usr/bin/env bash
# Minimal smoke test of a running Kaui: "does the WAR boot and serve the main pages without crashing?"
# Only needs curl. Checks: login page, login, tenant setup, /home, /accounts, /invoices, /payments and the JSON
# endpoints that feed those lists (these call Kill Bill, so they also prove Kaui <-> Kill Bill <-> DB work).
#
# Usage: smoke.sh <kaui-base-url> [user] [password]       e.g. smoke.sh http://127.0.0.1:18091
# Exit code: 0 = all checks passed, 1 = at least one failed.
set -u

BASE="${1:?usage: smoke.sh <kaui-base-url> [user] [password]}"; BASE="${BASE%/}"
USERNAME="${2:-admin}"; PASSWORD="${3:-password}"
TENANT="smoke-$(date +%s)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
JAR="$WORK/cookies"; BODY="$WORK/body"
FAILED=0

# Rails / Tomcat error pages and swallowed exceptions rendered into a page
BAD='Internal Server Error|something went wrong|ActionView::Template::Error|ActionController::|ActiveRecord::|NoMethodError|NameError|undefined method|Java::[A-Za-z]|java\.lang\.[A-Za-z]+(Exception|Error)|HTTP Status [45][0-9][0-9]|was not declared to be precompiled'

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n        %s\n' "$1" "$2"; FAILED=1; }

# get <path> [curl args...]  -> sets CODE and URL, body in $BODY
get() { local out; out="$(curl -s -m 120 -c "$JAR" -b "$JAR" -L -o "$BODY" -w '%{http_code} %{url_effective}' "$@" )" || out="000 curl-failed"; CODE="${out%% *}"; URL="${out#* }"; }
token() { sed -n 's/.*name="authenticity_token" value="\([^"]*\)".*/\1/p' "$BODY" | head -1; }

# page <name> <path> <expected text>
page() {
  get "$BASE$2"
  if [[ "$CODE" != 200 ]]; then fail "$1" "GET $2 -> HTTP $CODE"
  elif [[ "$URL" == *sign_in* ]]; then fail "$1" "GET $2 redirected to the login page (session lost)"
  elif m="$(grep -Eo "$BAD" "$BODY" | head -1)" && [[ -n "$m" ]]; then fail "$1" "page contains error text: $m"
  elif ! grep -q "$3" "$BODY"; then fail "$1" "page does not contain \"$3\""
  else pass "$1"; fi
}

# json <name> <method> <path>   (DataTables endpoints behind the lists)
json() {
  local csrf; csrf="$(sed -n 's/.*<meta name="csrf-token" content="\([^"]*\)".*/\1/p' "$BODY" | head -1)"
  get "$BASE$3" -X "$2" -H 'X-Requested-With: XMLHttpRequest' -H "X-CSRF-Token: $csrf" -d 'draw=1&start=0&length=10'
  if [[ "$CODE" != 200 ]]; then fail "$1" "$2 $3 -> HTTP $CODE"
  elif ! grep -q '"recordsTotal"' "$BODY"; then fail "$1" "$2 $3 did not return DataTables JSON: $(head -c 150 "$BODY")"
  else pass "$1"; fi
}

echo "Smoke test against $BASE"

# 1. login page
get "$BASE/users/sign_in"
if [[ "$CODE" == 200 ]] && grep -q 'user_kb_username' "$BODY" && ! grep -Eq "$BAD" "$BODY"; then pass "Login page"
else fail "Login page" "GET /users/sign_in -> HTTP $CODE ($(grep -Eo "$BAD" "$BODY" | head -1))"; fi
TOKEN="$(token)"

# 2. login
get "$BASE/users/sign_in" --data-urlencode "authenticity_token=$TOKEN" \
    --data-urlencode "user[kb_username]=$USERNAME" --data-urlencode "user[password]=$PASSWORD"
if [[ "$CODE" == 200 && "$URL" != *sign_in* ]]; then pass "Login as $USERNAME (landed on ${URL#"$BASE"})"
else fail "Login as $USERNAME" "HTTP $CODE, ended on $URL"; fi

# 3. a fresh Kill Bill has no tenant: Kaui sends us to the tenant form, create one (needed to browse accounts etc.)
if [[ "$URL" == *admin_tenants/new* ]]; then
  TOKEN="$(token)"
  get "$BASE/admin_tenants" --data-urlencode "authenticity_token=$TOKEN" --data-urlencode "tenant[name]=$TENANT" \
      --data-urlencode "tenant[api_key]=$TENANT-key" --data-urlencode "tenant[api_secret]=$TENANT-secret"
  if grep -q 'Tenant was successfully configured' "$BODY"; then pass "Create tenant"
  else fail "Create tenant" "HTTP $CODE, ended on $URL"; fi
fi

# 4. the pages
page "Home"      /home      "Get Started"
page "Accounts"  /accounts  "Accounts"
json "Accounts list data (Kaui -> Kill Bill)"  POST /accounts/pagination.json
page "Invoices"  /invoices  "Invoices"
json "Invoices list data (Kaui -> Kill Bill)"  GET  /invoices/pagination.json
page "Payments"  /payments  "Payments"
json "Payments list data (Kaui -> Kill Bill)"  GET  /payments/pagination.json

# 5. after some use the app must still hand out sessions: a brand new visitor has to be able to log in.
#    (The Java 21 / JRuby 10 / Tomcat 11 build stops issuing session cookies after a few dozen requests, so nobody
#    new can log in until Tomcat is restarted - a plain "does it boot" check does not notice.)
for _ in $(seq 1 25); do get "$BASE/home"; done
JAR="$WORK/cookies-new-visitor"
get "$BASE/users/sign_in"
if ! grep -q '_session' "$JAR"; then
  fail "New visitor can still log in after 25 more requests" "the login page no longer sets a session cookie, so login is impossible"
else
  TOKEN="$(token)"
  get "$BASE/users/sign_in" --data-urlencode "authenticity_token=$TOKEN" \
      --data-urlencode "user[kb_username]=$USERNAME" --data-urlencode "user[password]=$PASSWORD"
  if [[ "$CODE" == 200 && "$URL" != *sign_in* ]]; then pass "New visitor can still log in after 25 more requests"
  else fail "New visitor can still log in after 25 more requests" "login POST ended on $URL (HTTP $CODE): $(grep -Eo "$BAD" "$BODY" | head -1)"; fi
fi

echo
if [[ $FAILED -eq 0 ]]; then echo "ALL CHECKS PASSED against $BASE"; else echo "SOME CHECKS FAILED against $BASE"; fi
exit "$FAILED"
