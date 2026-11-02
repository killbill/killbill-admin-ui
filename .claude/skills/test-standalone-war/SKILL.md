---
name: test-standalone-war
description: Pre-release smoke test of the killbill-admin-ui-standalone WAR (Kaui) on the two supported runtimes - Java 11 + JRuby 9.4 + Tomcat 8.5 (standalone branch jruby9_old_branch) and Java 21 + JRuby 10 + Tomcat 11 (standalone branch master). Builds the WAR in Docker, boots MariaDB + Kill Bill + Tomcat, then drives the real UI (login, tenant/catalog, accounts, subscriptions, invoices, payments, settings pages, CSV exports). Use before cutting a Kaui / kaui-standalone release, after bumping gems or JRuby, or when asked to "test the WAR", "smoke test the release", "verify Tomcat 8 / Tomcat 11 / Java 11 / Java 21 compatibility".
---

# Test the killbill-admin-ui-standalone WAR before a release

Kaui is released in two pieces: this repo (the `kaui` engine gem) and
[killbill-admin-ui-standalone](https://github.com/killbill/killbill-admin-ui-standalone), whose
`release.yml` builds the deployable `killbill-admin-ui-standalone.war` with `build.sh` (Warbler) and publishes it to
Maven Central. The WAR is shipped for two runtime lines, so both are tested:

| Profile  | Build image (from `release.yml`)  | Runtime            | Standalone branch    | Host ports (Kaui / Kill Bill) |
|----------|-----------------------------------|--------------------|----------------------|-------------------------------|
| `java11` | `jruby:9.4.15.0-jdk11`            | `tomcat:8.5-jdk11` | `jruby9_old_branch`  | 18091 / 18081                 |
| `java21` | `jruby:10.0.6.0-jdk21`            | `tomcat:11.0-jdk21`| `master`             | 18092 / 18082                 |

> JRuby 9.4.**15**.0 is used for the legacy build, not 9.4.10.0: that is what `release.yml` on `jruby9_old_branch`
> uses, and its `build.sh` refuses JRuby < 9.4.11.0. The runtime JRuby is whatever the WAR bundles
> (`jruby-jars` pinned in the standalone `Gemfile`), independent of the build image. Override with
> `JRUBY_IMAGE=...` if you really need another one.

## Quick start

Needs Docker (with compose v2) and Node.js with `playwright` installed (otherwise the tests run in the official
Playwright Docker image automatically). Run from anywhere in this repo:

```bash
# both runtimes, bundling THIS checkout of the Kaui engine into each WAR (the default)
.claude/skills/test-standalone-war/scripts/run.sh all

# one runtime
.claude/skills/test-standalone-war/scripts/run.sh java11
.claude/skills/test-standalone-war/scripts/run.sh java21
```

First run: ~5-8 min per profile (pulls images, downloads gems into a cached Docker volume). Later runs: ~3-4 min.
Exit code is non-zero if any profile fails. Run it in the background / with a long timeout (>= 10 min per profile).

### What is under test (pick deliberately)

| You want to test...                                              | Use                                           |
|------------------------------------------------------------------|-----------------------------------------------|
| The Kaui engine code in this checkout, on both runtimes (default) | `run.sh all`                                  |
| The standalone branch exactly as it would release (released `kaui` gem) | `run.sh --kaui-gem all`                  |
| A local standalone checkout (uncommitted changes included)        | `run.sh --standalone-dir ../killbill-admin-ui-standalone java21` |
| Another standalone branch/tag                                    | `run.sh --standalone-ref my-branch java21`    |
| A kaui engine from somewhere else                                | `run.sh --kaui-dir /path/to/killbill-admin-ui all` |
| An already built WAR                                             | `run.sh --war /path/app.war java11`           |

Other options: `--skip-build` (reuse the WAR from the previous run), `--keep` (leave the stack up and print the URLs,
login `admin` / `password`; stop with `run.sh down <profile|all>`), `--clean-cache` (reset the gem cache volume),
`--playwright host|docker`, `--work-dir DIR` (or `KAUI_WAR_TEST_DIR`; default `$TMPDIR/kaui-war-test`).
`KILLBILL_IMAGE` (default `killbill/killbill:0.24.3`, same as the standalone CI), `DB_IMAGE`, `BOOT_TIMEOUT` are env vars.

When a profile's branch is the thing being released, make sure that branch is the one tested: the default clones the
profile's branch from GitHub (so unpushed standalone changes are NOT included - use `--standalone-dir` for those).
State in the final report which Kaui engine (`local checkout, version X` vs `released gem`) and which standalone commit
were tested; the script prints both.

## What the script does, per profile

1. **Source**: shallow-clones the standalone branch into `<work>/<profile>/src`. Unless `--kaui-gem`, copies this
   repo's engine (`app config db lib kaui.gemspec ...`) to `src/_kaui_local` and rewrites the Gemfile line
   `gem 'kaui'` to `gem 'kaui', path: '_kaui_local'` (Warbler then packages it under `WEB-INF/_kaui_local`).
2. **Build**: `docker/Dockerfile.builder` = the JRuby image + `build-essential`/`git` (the GitHub runner has a compiler;
   some gems, e.g. `prism` on the legacy branch, compile native extensions). Runs the standalone `build.sh` as in
   `release.yml`, with the gem cache kept in a named volume `kaui-war-gems-<profile>-<image>`. If a build fails the
   volume is dropped (a half-installed gem would otherwise break every following build).
3. **Stack** (`docker/docker-compose.yml`, project `kauiwar-<profile>`, bridge network, always started from empty DBs):
   `killbill/mariadb:0.24` (ships the `killbill` and `kaui` schemas) + Kill Bill + Tomcat with the WAR as `ROOT.war`,
   configured through `-Dkaui.*` system properties / `KAUI_DB_URL` exactly like a real deployment.
4. **UI tests** (`e2e/smoke.js`, Playwright), then logs are saved and the stack is removed.

## What the UI test covers (`e2e/smoke.js`, ~44 steps)

Login page, wrong-password rejection, login; create tenant; upload catalog (`SpyCarAdvanced.xml`); dashboard;
create/edit account; add `__EXTERNAL_PAYMENT__` payment method; create subscription (`sports-monthly`); subscriptions
list + bundle page; manual charge -> invoice -> automatic payment; account/all **invoices** lists, invoice details +
HTML view; account/all **payments** lists, payment details, new-payment form; accounts list; global search; account
timeline/tags/custom fields/queues/audit; tagging; tenant (clock), users, roles, tags, tag definitions, custom fields,
queues pages; CSV exports (accounts, invoices, payments - exercises the `csv` gem on both Rubies) + account JSON
export; sign out and redirect to login.

Login, tenant creation, catalog upload and account creation are prerequisites: if one fails the suite aborts
immediately instead of waiting out ~40 timeouts. A step **fails** if it throws, or if during the step: a same-origin request returned HTTP >= 400 (except where the
step expects it), the page raised a JS exception, Kaui showed an error flash (`#flash-error`/`#flash-alert`), or the
page text contains a stack trace / Rails or Tomcat error page. Subscription actions beyond creation (change plan,
cancel), overdue, plugins/KPM/Aviate screens are deliberately not covered - add steps to `smoke.js` if a release touches them
(each step is a small `await step(page, 'name', async () => {...})` block).

## Reading the results

* Console summary: one line per step, then `N/N steps passed` and a per-profile `PASS/FAIL` table.
* `<work>/<profile>/out/`: `results.txt` / `results.json` (per step: status, URL, problems), `screenshots/NN-step.png`
  (one per step, full page - open the failing ones first), `build.log`, `kaui.log` (Tomcat + Rails log),
  `stack.log` (all containers).
* The script also greps `kaui.log` for `ERROR`/`SEVERE` and prints a warning even when the UI looked fine.

On a failure: read the step's problem line, open its screenshot, then grep `kaui.log` around the failing request
(Rails errors carry `rId='<request id>'`). Use `--keep` to poke at the live stack manually.

## Known issues / gotchas

* **Cold-start race (pre-existing, reproduced with the released WAR):** on Java 11 / JRuby 9.4 / Tomcat 8.5, firing
  6 *concurrent first requests* at the login page right after the app finished deploying left it answering HTTP 500
  `Asset 'kaui/sign_in_background.svg' was not declared to be precompiled in production` in 2 of 3 fresh boots with the
  local-engine WAR and in 2 of 4 with the released-gem WAR (in one boot it never recovered until Tomcat was restarted;
  in the other it recovered after the first burst). Strictly serial first requests were fine (3/3 full runs).
  It was only checked on the Java 11 profile. The compose health probe is therefore deliberately serial (long timeout,
  so a slow probe is never killed and overlapped by the next one). If a boot nevertheless ends with 500s on the
  login page, suspect this bug rather than the change under test: restart, re-run, and report it.
* Behind a TLS-intercepting HTTPS proxy on localhost (some sandboxes/CI) the script automatically gives the build
  container `--network host`, the proxy variables, the CA bundle (`SSL_CERT_FILE`) and the Java truststore
  (`JAVA_TOOL_OPTIONS`) - needed because the `jar-dependencies` gem runs Maven (a JVM) during `bundle install`.
  Docker Hub anonymous pulls can answer `429`; just re-run.
* Nothing is published or pushed anywhere; everything stays in the work dir and Docker (images, the
  `kaui-war-gems-*` volumes, stacks removed after each run unless `--keep`).
* The Kill Bill version is pinned by default; if a release also changes the supported Kill Bill version, run with
  `KILLBILL_IMAGE=killbill/killbill:<version>` as well (and keep `DB_IMAGE` schema-compatible).

## Files

```
scripts/run.sh                    orchestrator (build -> stack -> tests -> logs -> teardown)
profiles/java11.env, java21.env   per-runtime settings (branch, images, ports)
docker/Dockerfile.builder         JRuby build image + build tools
docker/docker-compose.yml         MariaDB + Kill Bill + Tomcat(WAR)
e2e/smoke.js                      Playwright UI test (single file, only dependency: `playwright`)
e2e/fixtures/SpyCarAdvanced.xml   catalog uploaded through the UI (copy of test/fixtures/SpyCarAdvanced.xml)
```
