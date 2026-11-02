#!/usr/bin/env bash
# Pre-release smoke test for the killbill-admin-ui-standalone WAR, on the two supported runtimes:
#
#   java11 : Java 11 + JRuby 9.4  + Tomcat 8.5   (standalone branch jruby9_old_branch)
#   java21 : Java 21 + JRuby 10.0 + Tomcat 11    (standalone branch master)
#
# For each profile: (1) build the WAR in a Docker JRuby image, (2) start MariaDB + Kill Bill + Tomcat(WAR) with
# docker compose, (3) run the curl smoke test (scripts/smoke.sh), (4) collect logs and tear everything down.
#
# Run `run.sh --help` for the options.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$SKILL_DIR/docker/docker-compose.yml"

# ---- defaults (all overridable via env) ----------------------------------------------------------------------------
STANDALONE_REPO_URL="${STANDALONE_REPO_URL:-https://github.com/killbill/killbill-admin-ui-standalone.git}"
KILLBILL_IMAGE="${KILLBILL_IMAGE:-killbill/killbill:0.24.3}"   # same as the standalone repo CI
DB_IMAGE="${DB_IMAGE:-killbill/mariadb:0.24}"                  # ships the killbill + kaui schemas
WORK_ROOT="${KAUI_WAR_TEST_DIR:-${TMPDIR:-/tmp}/kaui-war-test}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-600}"                            # seconds to wait for the stack to become healthy

KAUI_SOURCE="dir"                                              # dir | gem
KAUI_DIR="$(git -C "$SKILL_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
STANDALONE_DIR=""
STANDALONE_REF=""
WAR_OVERRIDE=""
SKIP_BUILD=0
KEEP=0
CLEAN_CACHE=0
PROFILES=()

usage() {
  cat <<EOF
Usage: run.sh [options] <java11|java21|all>

Profiles
  java11   Java 11 / JRuby 9.4 / Tomcat 8.5   (standalone branch: jruby9_old_branch)
  java21   Java 21 / JRuby 10  / Tomcat 11    (standalone branch: master)
  all      both, one after the other

What gets built
  --kaui-dir DIR        Kaui engine checkout to bundle into the WAR instead of the released 'kaui' gem.
                        Default: the repository this skill lives in ($KAUI_DIR).
  --kaui-gem            Use the released 'kaui' gem from rubygems (i.e. test the standalone branch as-is).
  --standalone-dir DIR  Use a local killbill-admin-ui-standalone checkout (working tree, uncommitted changes
                        included) instead of cloning the profile's branch from GitHub.
  --standalone-ref REF  Branch/tag to clone instead of the profile's default branch.
  --war FILE            Skip building; deploy this prebuilt WAR (single profile only).
  --skip-build          Re-use the WAR built by a previous run (in the work dir).
  --clean-cache         Drop the cached gem volume (kaui-war-gems-*) before building.

Running
  --keep                Leave the Docker stack running afterwards (URLs are printed). Stop it with:  run.sh down <profile|all>
  --work-dir DIR        Where sources, WARs and logs go (default: $WORK_ROOT).

Other commands
  run.sh down <java11|java21|all>   Stop and delete the compose stack(s) of a profile.

Env: KILLBILL_IMAGE ($KILLBILL_IMAGE)  DB_IMAGE ($DB_IMAGE)  STANDALONE_REPO_URL  BOOT_TIMEOUT ($BOOT_TIMEOUT)s
     JRUBY_IMAGE / TOMCAT_IMAGE / KB_PORT / KAUI_PORT override the values from profiles/<profile>.env
EOF
}

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ---- args ----------------------------------------------------------------------------------------------------------
COMMAND="test"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    down) COMMAND="down" ;;
    --kaui-dir) KAUI_SOURCE="dir"; KAUI_DIR="$(cd "${2:?--kaui-dir needs a value}" && pwd)"; shift ;;
    --kaui-gem) KAUI_SOURCE="gem" ;;
    --standalone-dir) STANDALONE_DIR="$(cd "${2:?--standalone-dir needs a value}" && pwd)"; shift ;;
    --standalone-ref) STANDALONE_REF="${2:?--standalone-ref needs a value}"; shift ;;
    --war) WAR_OVERRIDE="$(cd "$(dirname "${2:?--war needs a value}")" && pwd)/$(basename "$2")"; shift ;;
    --skip-build) SKIP_BUILD=1 ;;
    --clean-cache) CLEAN_CACHE=1 ;;
    --keep) KEEP=1 ;;
    --work-dir) mkdir -p "${2:?--work-dir needs a value}"; WORK_ROOT="$(cd "$2" && pwd)"; shift ;;
    java11|java21) PROFILES+=("$1") ;;
    all) PROFILES+=(java11 java21) ;;
    *) usage; die "Unknown argument: $1" ;;
  esac
  shift
done
[[ ${#PROFILES[@]} -gt 0 ]] || { usage; die "Pick a profile: java11, java21 or all"; }
command -v docker >/dev/null || die "docker is required"
docker info >/dev/null 2>&1 || die "The Docker daemon is not reachable (is it running?)"
[[ -z "$WAR_OVERRIDE" || ${#PROFILES[@]} -eq 1 ]] || die "--war can only be used with a single profile"

# ---- helpers -------------------------------------------------------------------------------------------------------
# User overrides must be captured ONCE: after the first profile is loaded these variables are set for every later one
USER_JRUBY_IMAGE="${JRUBY_IMAGE:-}"; USER_TOMCAT_IMAGE="${TOMCAT_IMAGE:-}"; USER_KB_PORT="${KB_PORT:-}"; USER_KAUI_PORT="${KAUI_PORT:-}"

load_profile() { # sets PROFILE_NAME, STANDALONE_BRANCH, JRUBY_IMAGE, TOMCAT_IMAGE, KB_PORT, KAUI_PORT
  # shellcheck disable=SC1090
  source "$SKILL_DIR/profiles/$1.env"
  JRUBY_IMAGE="${USER_JRUBY_IMAGE:-$JRUBY_IMAGE}"; TOMCAT_IMAGE="${USER_TOMCAT_IMAGE:-$TOMCAT_IMAGE}"
  KB_PORT="${USER_KB_PORT:-$KB_PORT}"; KAUI_PORT="${USER_KAUI_PORT:-$KAUI_PORT}"
}

compose() { # compose <profile> <args...>   (env must already be exported by export_stack_env)
  docker compose -f "$COMPOSE_FILE" "${@:2}"
}

export_stack_env() { # export_stack_env <war>
  export COMPOSE_PROJECT_NAME="kauiwar-$PROFILE_NAME" KILLBILL_IMAGE DB_IMAGE TOMCAT_IMAGE KB_PORT KAUI_PORT
  export WAR_PATH="$1"
  export KAUI_SECRET_KEY_BASE="${KAUI_SECRET_KEY_BASE:-$(LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 128)}"
}

# When Docker has to go through a (TLS intercepting) proxy on localhost we need host networking for the build
# container plus the proxy/CA settings. On a normal dev machine or CI none of this applies.
build_net_args() {
  BUILD_NET_ARGS=()
  local proxy="${HTTPS_PROXY:-${https_proxy:-}}"
  [[ -n "$proxy" ]] || return 0
  [[ "$proxy" =~ (127\.0\.0\.1|localhost) ]] && BUILD_NET_ARGS+=(--network host)
  BUILD_NET_ARGS+=(-e HTTPS_PROXY -e https_proxy -e NO_PROXY -e no_proxy)
  local ca="${SSL_CERT_FILE:-${CURL_CA_BUNDLE:-}}"
  [[ -n "$ca" && -f "$ca" ]] && BUILD_NET_ARGS+=(-v "$ca:/proxy-ca.crt:ro" -e SSL_CERT_FILE=/proxy-ca.crt)
  # Maven (used by the jar-dependencies gem for psych & co.) runs a JVM that needs the same proxy + truststore
  local ts
  ts="$(printf '%s' "${JAVA_TOOL_OPTIONS:-}" | sed -n 's/.*-Djavax.net.ssl.trustStore=\([^ ]*\).*/\1/p')"
  if [[ -n "$ts" && -f "$ts" ]]; then
    BUILD_NET_ARGS+=(-v "$ts:$ts:ro" -e JAVA_TOOL_OPTIONS)
  fi
}

prepare_sources() { # prepare_sources <src-dir>
  local src="$1"
  rm -rf "$src"; mkdir -p "$src"
  if [[ -n "$STANDALONE_DIR" ]]; then
    log "Using local standalone checkout $STANDALONE_DIR ($(git -C "$STANDALONE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git'))"
    tar -C "$STANDALONE_DIR" --exclude=.git --exclude=./log --exclude=./tmp --exclude='*.war' --exclude=./version.yml \
        --exclude=./Gemfile.lock --exclude=./public/assets -cf - . | tar -C "$src" -xf -
  else
    local ref="${STANDALONE_REF:-$STANDALONE_BRANCH}"
    log "Cloning $STANDALONE_REPO_URL @ $ref"
    GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 --branch "$ref" "$STANDALONE_REPO_URL" "$src"
  fi
  STANDALONE_COMMIT="$(git -C "$src" rev-parse --short HEAD 2>/dev/null || echo "${STANDALONE_DIR:+local-working-tree}")"
  [[ -f "$src/build.sh" && -f "$src/Gemfile" ]] || die "$src does not look like killbill-admin-ui-standalone (no build.sh / Gemfile)"

  if [[ "$KAUI_SOURCE" == "dir" ]]; then
    [[ -f "$KAUI_DIR/kaui.gemspec" ]] || die "--kaui-dir $KAUI_DIR has no kaui.gemspec"
    log "Bundling Kaui engine from $KAUI_DIR (branch $(git -C "$KAUI_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?'), version $(sed -n "s/.*VERSION = '\(.*\)'/\1/p" "$KAUI_DIR/lib/kaui/version.rb"))"
    mkdir -p "$src/_kaui_local"
    (cd "$KAUI_DIR" && tar --exclude='.git' -cf - app config db lib kaui.gemspec MIT-LICENSE Rakefile README.md 2>/dev/null) | tar -C "$src/_kaui_local" -xf -
    grep -Eq "^gem ['\"]kaui['\"]\s*$" "$src/Gemfile" || die "Could not find a plain \"gem 'kaui'\" line in the standalone Gemfile to override"
    sed -E "s|^gem ['\"]kaui['\"]\s*\$|gem 'kaui', path: '_kaui_local'|" "$src/Gemfile" > "$src/Gemfile.new" && mv "$src/Gemfile.new" "$src/Gemfile"
  else
    log "Using the released kaui gem (as pinned/resolved by the standalone Gemfile)"
  fi
}

build_war() { # build_war <profile-work-dir>  -> sets WAR
  local pdir="$1" src="$1/src" vol="kaui-war-gems-$PROFILE_NAME-$(printf '%s' "$JRUBY_IMAGE" | tr -c 'a-zA-Z0-9' '-')"
  build_net_args
  prepare_sources "$src"

  log "Building builder image ($JRUBY_IMAGE + build tools)"
  local bargs=(--build-arg "JRUBY_IMAGE=$JRUBY_IMAGE")
  [[ " ${BUILD_NET_ARGS[*]:-} " == *" --network host "* ]] && bargs+=(--network host --build-arg HTTPS_PROXY --build-arg https_proxy)
  docker build -q "${bargs[@]}" -t "kaui-war-builder:$PROFILE_NAME" -f "$SKILL_DIR/docker/Dockerfile.builder" "$SKILL_DIR/docker" >/dev/null

  [[ $CLEAN_CACHE -eq 1 ]] && docker volume rm "$vol" >/dev/null 2>&1 || true
  log "Building the WAR with build.sh inside $JRUBY_IMAGE (first build downloads gems: several minutes)"
  local rc=0
  docker run --rm "${BUILD_NET_ARGS[@]}" \
      -v "$vol:/usr/local/bundle" -v "$src:/app" -w /app \
      -e JRUBY_OPTS="-J-Xmx2g" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
      "kaui-war-builder:$PROFILE_NAME" \
      bash -c 'java -version 2>&1 | head -1; ruby -v; bash build.sh; rc=$?; chown -R "$HOST_UID:$HOST_GID" /app; exit $rc' \
      > "$pdir/out/build.log" 2>&1 || rc=$?
  if [[ $rc -ne 0 ]]; then
    tail -40 "$pdir/out/build.log" >&2
    docker volume rm "$vol" >/dev/null 2>&1 || true   # a half-installed gem in the cache would poison the next build
    die "WAR build failed (exit $rc). Full log: $pdir/out/build.log (gem cache volume was reset)"
  fi
  mkdir -p "$pdir/war"; cp "$src/killbill-admin-ui-standalone.war" "$pdir/war/"
  WAR="$pdir/war/killbill-admin-ui-standalone.war"
  echo "Built $WAR ($(du -h "$WAR" | cut -f1)); standalone @ ${STANDALONE_COMMIT:-?}"
  if command -v unzip >/dev/null; then
    local kv
    kv="$(unzip -p "$WAR" WEB-INF/_kaui_local/lib/kaui/version.rb 2>/dev/null | sed -n "s/.*VERSION = '\(.*\)'.*/\1/p" || true)"
    if [[ -n "$kv" ]]; then echo "Bundled Kaui engine: local checkout, version $kv"
    else echo "Bundled Kaui engine: $( { unzip -l "$WAR" 2>/dev/null | grep -Eo 'gems/kaui-[0-9.]+/' | head -1 | sed 's|^gems/||; s|/$||'; } || true ) (released gem)"; fi
  fi
}

wait_for_stack() {
  log "Starting stack (db, killbill $KILLBILL_IMAGE, kaui on $TOMCAT_IMAGE)"
  compose "$PROFILE_NAME" down -v --remove-orphans >/dev/null 2>&1 || true
  compose "$PROFILE_NAME" up -d --wait --wait-timeout "$BOOT_TIMEOUT" 2>&1 | tail -5 || return 1
}

run_tests() { # run_tests <profile-work-dir>
  local out="$1/out"
  log "Running smoke test against http://127.0.0.1:$KAUI_PORT"
  "$SKILL_DIR/scripts/smoke.sh" "http://127.0.0.1:$KAUI_PORT" 2>&1 | tee "$out/results.txt"
  return "${PIPESTATUS[0]}"
}

collect_logs() { # collect_logs <profile-work-dir>
  local out="$1/out"
  compose "$PROFILE_NAME" logs --no-color --timestamps > "$out/stack.log" 2>&1 || true
  compose "$PROFILE_NAME" logs --no-color kaui > "$out/kaui.log" 2>&1 || true
  # Surface real server-side trouble even when the UI looked fine (HTTP 5xx, swallowed Ruby/Java exceptions, Tomcat
  # SEVERE). Plain "ERROR" lines are NOT used: the killbill-client logs every 4xx from Kill Bill at ERROR/FATAL
  # (e.g. the expected 401 of the wrong-password step), which would make this warning noise.
  local pat='Completed 5[0-9][0-9]|ActionView::Template::Error|NoMethodError|NameError|ArgumentError|Java::[A-Za-z.]+|java\.lang\.[A-Za-z]+(Exception|Error)|SEVERE'
  LOG_ERRORS="$(grep -E "$pat" "$out/kaui.log" 2>/dev/null | head -10 || true)"
  LOG_ERROR_COUNT="$(grep -cE "$pat" "$out/kaui.log" 2>/dev/null || true)"
}

# ---- main loop -----------------------------------------------------------------------------------------------------
SUMMARY=()
OVERALL=0

for p in "${PROFILES[@]}"; do
  load_profile "$p"
  PDIR="$WORK_ROOT/$PROFILE_NAME"; mkdir -p "$PDIR/out"

  if [[ "$COMMAND" == "down" ]]; then
    export_stack_env "/dev/null"; log "Stopping $PROFILE_NAME stack"; compose "$PROFILE_NAME" down -v --remove-orphans; continue
  fi

  log "PROFILE $PROFILE_NAME  |  build: $JRUBY_IMAGE  |  runtime: $TOMCAT_IMAGE  |  work dir: $PDIR"
  RESULT="PASS"; DETAIL=""; LOG_ERRORS=""; LOG_ERROR_COUNT=0; STANDALONE_COMMIT=""

  if [[ -n "$WAR_OVERRIDE" ]]; then
    WAR="$WAR_OVERRIDE"; [[ -f "$WAR" ]] || die "WAR not found: $WAR"
  elif [[ $SKIP_BUILD -eq 1 ]]; then
    WAR="$PDIR/war/killbill-admin-ui-standalone.war"; [[ -f "$WAR" ]] || die "--skip-build but no previous WAR at $WAR"
  else
    build_war "$PDIR"
  fi

  export_stack_env "$WAR"
  if wait_for_stack; then
    if run_tests "$PDIR"; then RESULT="PASS"; else RESULT="FAIL"; DETAIL="smoke test failed (see $PDIR/out/results.txt)"; fi
  else
    RESULT="FAIL"; DETAIL="stack did not become healthy within ${BOOT_TIMEOUT}s"
    compose "$PROFILE_NAME" ps || true
  fi
  collect_logs "$PDIR"

  if [[ $KEEP -eq 1 ]]; then
    echo "Stack left running: Kaui http://127.0.0.1:$KAUI_PORT (admin/password), Kill Bill http://127.0.0.1:$KB_PORT"
  else
    compose "$PROFILE_NAME" down -v --remove-orphans >/dev/null 2>&1 || true
  fi

  [[ "${LOG_ERROR_COUNT:-0}" -gt 0 ]] && { warn "$LOG_ERROR_COUNT suspicious line(s) (HTTP 5xx / exceptions / SEVERE) in the Kaui log; first ones:"; echo "$LOG_ERRORS" | cut -c1-300; }
  [[ "$RESULT" == "FAIL" ]] && OVERALL=1
  SUMMARY+=("$(printf '%-7s %-5s %s' "$PROFILE_NAME" "$RESULT" "$DETAIL")  [logs: $PDIR/out]")
done

if [[ "$COMMAND" == "test" ]]; then
  log "SUMMARY"
  printf '%s\n' "${SUMMARY[@]}"
  exit "$OVERALL"
fi
