#!/usr/bin/env node
/*
 * End-to-end smoke test for a deployed killbill-admin-ui-standalone WAR.
 *
 * Drives the real UI with Playwright: login, tenant + catalog setup, account / payment method /
 * subscription / charge creation, and the common list + detail pages (accounts, invoices, payments, ...).
 *
 * A step FAILS when it throws, or when during the step any of these happened:
 *   - the server answered a same-origin request with HTTP >= 400 (unless the step expects it)
 *   - a JavaScript exception was raised in the page
 *   - Kaui rendered an error flash (#flash-error / #flash-alert) (unless the step expects it)
 *   - the page text contains a stack trace / Rails error page marker
 *
 * Config (env):  KAUI_URL (required)  OUT_DIR  KAUI_USER  KAUI_PASSWORD  HEADED=1
 * Output:        OUT_DIR/results.json, OUT_DIR/results.txt, OUT_DIR/screenshots/*.png
 * Exit code:     0 = all steps passed, 1 = at least one failed.
 */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const BASE = (process.env.KAUI_URL || '').replace(/\/+$/, '');
const OUT = process.env.OUT_DIR || path.join(process.cwd(), 'e2e-out');
const USER = process.env.KAUI_USER || 'admin';
const PASSWORD = process.env.KAUI_PASSWORD || 'password';
const CATALOG = path.join(__dirname, 'fixtures', 'SpyCarAdvanced.xml');
const RUN_ID = Date.now().toString(36);
const NAV_TIMEOUT = 60000;

if (!BASE) {
  console.error('KAUI_URL is required, e.g. KAUI_URL=http://127.0.0.1:18091');
  process.exit(2);
}
fs.mkdirSync(path.join(OUT, 'screenshots'), { recursive: true });

const BAD_PAGE_MARKERS = [
  /Internal Server Error/i,
  /We're sorry, but something went wrong/i,
  /Action ?Controller::\w+/,
  /ActiveRecord::\w+/,
  /NoMethodError|NameError|undefined method|undefined local variable/,
  /org\.jruby\.|Java::\w+|java\.lang\.\w+Exception/,
  /\bat [\w./]+\.rb:\d+:in `/,
  /HTTP Status [45]\d\d/, // Tomcat error page
];

const state = { tenant: `smoke-${RUN_ID}`, accountId: null, accountName: `Smoke ${RUN_ID}`, bundleId: null, invoiceId: null, paymentId: null };
const results = [];
let current = null; // collects problems for the running step

// Thrown when a step everything else depends on (login, tenant, catalog, account) failed: no point in running
// ~40 more steps that each wait for their timeouts.
class SuiteAbort extends Error {}

function attachListeners(page) {
  page.on('response', (res) => {
    if (!current || res.status() < 400) return;
    const url = res.url();
    if (!url.startsWith(BASE)) return;
    if (current.allowStatus.includes(res.status())) return;
    current.problems.push(`HTTP ${res.status()} ${res.request().method()} ${url.replace(BASE, '')}`);
  });
  page.on('pageerror', (err) => current && current.problems.push(`JS exception: ${String(err.message).split('\n')[0]}`));
  page.on('console', (msg) => msg.type() === 'error' && current && current.consoleErrors.push(msg.text().slice(0, 200)));
}

async function step(page, name, fn, opts = {}) {
  current = { problems: [], consoleErrors: [], allowStatus: opts.allowStatus || [], expectFlashError: !!opts.expectFlashError };
  const started = Date.now();
  let error = null;
  try {
    await fn();
    await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});
    if (!current.expectFlashError) {
      const flash = await page.locator('#flash-error, #flash-alert').first().innerText({ timeout: 500 }).catch(() => null);
      if (flash) current.problems.push(`Error flash: ${flash.trim().replace(/\s+/g, ' ').slice(0, 200)}`);
    }
    const text = await page.locator('body').innerText({ timeout: 2000 }).catch(() => '');
    for (const re of BAD_PAGE_MARKERS) {
      const m = text.match(re);
      if (m) current.problems.push(`Page contains error marker: "${m[0]}"`);
    }
  } catch (e) {
    error = String(e.message || e).split('\n')[0];
  }
  const problems = [...(error ? [error] : []), ...current.problems];
  const status = problems.length ? 'FAIL' : 'PASS';
  const shot = `screenshots/${String(results.length + 1).padStart(2, '0')}-${name.replace(/[^a-z0-9]+/gi, '-').toLowerCase()}.png`;
  await page.screenshot({ path: path.join(OUT, shot), fullPage: true }).catch(() => {});
  results.push({ name, status, ms: Date.now() - started, url: page.url().replace(BASE, '') || '/', problems, consoleErrors: current.consoleErrors, screenshot: shot });
  console.log(`${status === 'PASS' ? '✅' : '❌'} ${name}${problems.length ? '\n     ' + problems.join('\n     ') : ''}`);
  current = null;
  if (status === 'FAIL' && opts.critical) throw new SuiteAbort(name);
}

// ---------------------------------------------------------------------------------------------------------------------

async function go(page, p) {
  const res = await page.goto(BASE + p, { waitUntil: 'domcontentloaded', timeout: NAV_TIMEOUT });
  return res;
}
const submitLast = (page) => page.locator('form button[type=submit]:visible').last();
async function submitAndWaitForUrlChange(page, button, notPathPart) {
  await Promise.all([page.waitForURL((u) => !u.pathname.includes(notPathPart), { timeout: NAV_TIMEOUT }), button.click()]);
}
async function expectText(page, ...texts) {
  const body = await page.locator('body').innerText();
  for (const t of texts) if (!body.includes(t)) throw new Error(`Expected page to contain "${t}"`);
}
async function expectTableRows(page, min = 1) {
  // DataTables are filled via ajax: wait for at least `min` real (non-"empty") rows
  const rows = page.locator('table tbody tr:has(td:not(.dataTables_empty))');
  await rows.first().waitFor({ timeout: 20000 });
  if ((await rows.count()) < min) throw new Error(`Expected at least ${min} table rows`);
}
async function expectDownload(ctx, p, contentTypeRe, minBytes = 20) {
  const res = await ctx.request.get(BASE + p, { timeout: NAV_TIMEOUT });
  if (res.status() !== 200) throw new Error(`GET ${p} -> HTTP ${res.status()}`);
  const ct = res.headers()['content-type'] || '';
  if (!contentTypeRe.test(ct)) throw new Error(`GET ${p} -> unexpected content-type "${ct}"`);
  const body = await res.body();
  if (body.length < minBytes) throw new Error(`GET ${p} -> body too small (${body.length} bytes)`);
}

(async () => {
  const browser = await chromium.launch({ headless: !process.env.HEADED });
  const ctx = await browser.newContext({ viewport: { width: 1400, height: 1000 }, acceptDownloads: true });
  ctx.setDefaultTimeout(30000);
  const page = await ctx.newPage();
  attachListeners(page);

  try {
  // ---- Authentication ----------------------------------------------------------------------------------------------
  await step(page, 'Login page renders', async () => {
    await go(page, '/users/sign_in');
    await page.locator('#user_kb_username').waitFor();
    await page.locator('#user_password').waitFor();
  });

  await step(page, 'Login with a wrong password is rejected', async () => {
    await go(page, '/users/sign_in');
    await page.fill('#user_kb_username', USER);
    await page.fill('#user_password', 'definitely-wrong');
    await page.click('button[type=submit]');
    await page.waitForLoadState('networkidle');
    await page.locator('#flash-alert, #flash-error').first().waitFor({ timeout: 10000 });
    if (!page.url().includes('sign_in')) throw new Error(`Expected to stay on the sign-in page, got ${page.url()}`);
  }, { expectFlashError: true, allowStatus: [401] });

  await step(page, 'Login as admin', async () => {
    await go(page, '/users/sign_in');
    await page.fill('#user_kb_username', USER);
    await page.fill('#user_password', PASSWORD);
    await submitAndWaitForUrlChange(page, page.locator('button[type=submit]'), 'sign_in');
    await expectText(page, 'Signed in successfully');
  }, { critical: true });

  // ---- Tenant + catalog --------------------------------------------------------------------------------------------
  await step(page, 'Create tenant', async () => {
    await go(page, '/admin_tenants/new');
    await page.getByLabel('Name').fill(state.tenant);
    await page.getByLabel('API Key').fill(`${state.tenant}-key`);
    await page.getByLabel('API Secret').fill(`${state.tenant}-secret`);
    await submitAndWaitForUrlChange(page, page.getByRole('button', { name: 'Save Tenant' }), 'new');
    await expectText(page, 'Tenant was successfully configured', state.tenant);
  }, { critical: true });

  await step(page, 'Upload catalog (advanced XML)', async () => {
    const tenantId = (page.url().match(/admin_tenants\/(\d+)/) || [])[1] || '1';
    await go(page, `/admin_tenants/${tenantId}/new_catalog`);
    await page.getByText('Advanced Configuration').click();
    await page.setInputFiles('#fileInput', CATALOG);
    await submitAndWaitForUrlChange(page, page.getByRole('button', { name: 'Upload XML' }), 'new_catalog');
    await expectText(page, 'Catalog was successfully uploaded');
  }, { critical: true });

  await step(page, 'Home dashboard', async () => {
    await go(page, '/home');
    await expectText(page, 'Get Started', 'Accounts', 'Invoices', 'Payments', 'Settings');
  });

  // ---- Account, payment method, subscription, charge ---------------------------------------------------------------
  await step(page, 'Create account', async () => {
    await go(page, '/accounts/new');
    await page.getByLabel('User name').fill(state.accountName);
    await page.getByLabel('Email').fill(`smoke-${RUN_ID}@example.com`);
    await submitAndWaitForUrlChange(page, submitLast(page), 'accounts/new');
    await page.waitForURL(/\/accounts\/[0-9a-f-]{36}/);
    state.accountId = page.url().match(/accounts\/([0-9a-f-]{36})/)[1];
    await expectText(page, 'Account was successfully created', state.accountName);
  }, { critical: true });

  await step(page, 'Account page shows details', async () => {
    await go(page, `/accounts/${state.accountId}`);
    await expectText(page, state.accountName, `smoke-${RUN_ID}@example.com`, 'Payment Methods', 'Billing Information');
  });

  await step(page, 'Edit account', async () => {
    await go(page, `/accounts/${state.accountId}/edit`);
    await page.getByLabel('Company').fill('Smoke Inc');
    await submitAndWaitForUrlChange(page, submitLast(page), '/edit');
    await expectText(page, 'Account successfully updated');
  });

  await step(page, 'Add external payment method', async () => {
    await go(page, `/payment_methods/new?account_id=${state.accountId}`);
    await page.fill('#payment_method_plugin_name', '__EXTERNAL_PAYMENT__');
    await page.check('#payment_method_is_default');
    await submitAndWaitForUrlChange(page, page.getByRole('button', { name: 'Save Method' }), 'payment_methods/new');
    await expectText(page, 'Payment method was successfully created', 'EXTERNAL');
  });

  await step(page, 'Create subscription (sports-monthly)', async () => {
    await go(page, `/subscriptions/new?account_id=${state.accountId}&product_category=BASE`);
    await page.locator('#plan_name').waitFor();
    await page.selectOption('#plan_name', 'sports-monthly');
    await submitAndWaitForUrlChange(page, submitLast(page), 'subscriptions/new');
    await expectText(page, 'Subscription was successfully created');
  });

  await step(page, 'Subscriptions list shows the new subscription', async () => {
    await go(page, `/accounts/${state.accountId}/bundles`);
    await expectText(page, 'Bundle ID', 'sports-monthly');
    const m = (await page.locator('body').innerText()).match(/Bundle ID\s+([0-9a-f-]{36})/);
    state.bundleId = m && m[1];
  });

  await step(page, 'Subscription / bundle details', async () => {
    if (!state.bundleId) throw new Error('bundle id not captured by previous step');
    await go(page, `/bundles/${state.bundleId}`);
    await expectText(page, 'sports-monthly');
  });

  await step(page, 'Create manual charge (generates invoice + payment)', async () => {
    await go(page, `/accounts/${state.accountId}/charges/new?currency=USD`);
    await page.check('#auto_commit');
    await page.fill('#charge_amount', '25');
    await page.fill('#invoice_item_description', 'Smoke charge');
    await page.fill('#comment', 'smoke test');
    await submitAndWaitForUrlChange(page, submitLast(page), 'charges/new');
    await expectText(page, 'Charge was successfully created');
    state.invoiceId = page.url().match(/invoices\/([0-9a-f-]{36})/)?.[1];
  });

  // ---- Invoices ----------------------------------------------------------------------------------------------------
  await step(page, 'Account invoices list', async () => {
    await go(page, `/accounts/${state.accountId}/invoices`);
    await expectTableRows(page, 1);
  });

  await step(page, 'Invoice details', async () => {
    if (!state.invoiceId) throw new Error('invoice id not captured by previous step');
    await go(page, `/accounts/${state.accountId}/invoices/${state.invoiceId}`);
    await expectText(page, 'Smoke charge');
  });

  await step(page, 'Invoice HTML rendering', async () => {
    await go(page, `/invoices/${state.invoiceId}/show_html`);
    await expectText(page, 'Smoke');
  });

  await step(page, 'All invoices list', async () => {
    await go(page, '/invoices');
    await expectTableRows(page, 1);
  });

  // ---- Payments ----------------------------------------------------------------------------------------------------
  await step(page, 'Account payments list', async () => {
    await go(page, `/accounts/${state.accountId}/payments`);
    await expectTableRows(page, 1);
    const href = await page.locator(`a[href*="/accounts/${state.accountId}/payments/"]`).first().getAttribute('href');
    state.paymentId = href && href.match(/payments\/([0-9a-f-]{36})/)?.[1];
  });

  await step(page, 'Payment details', async () => {
    if (!state.paymentId) throw new Error('payment id not captured by previous step');
    await go(page, `/accounts/${state.accountId}/payments/${state.paymentId}`);
    await expectText(page, state.paymentId);
  });

  await step(page, 'All payments list', async () => {
    await go(page, '/payments');
    await expectTableRows(page, 1);
  });

  await step(page, 'New payment form (for the invoice)', async () => {
    await go(page, `/accounts/${state.accountId}/payments/new?invoice_id=${state.invoiceId}`);
    await expectText(page, 'payment');
    await page.locator('form button[type=submit], form input[type=submit]').last().waitFor();
  });

  // ---- Accounts list / search --------------------------------------------------------------------------------------
  await step(page, 'All accounts list', async () => {
    await go(page, '/accounts');
    await expectTableRows(page, 1);
    await expectText(page, state.accountName);
  });

  await step(page, 'Global search finds the account', async () => {
    // Kaui requires a search type prefix, e.g. "Account: <term>"
    await go(page, `/home/search?q=${encodeURIComponent('Account: ' + state.accountName)}`);
    await page.waitForURL((u) => u.pathname.includes(state.accountId), { timeout: 30000 });
    await expectText(page, state.accountName);
  });

  // ---- Account sub-pages -------------------------------------------------------------------------------------------
  for (const [label, p] of [
    ['Account timeline', 'timeline'],
    ['Account tags', 'account_tags'],
    ['Account custom fields', 'custom_fields'],
    ['Account queues', 'queues'],
    ['Account audit logs', 'audit_logs'],
  ]) {
    await step(page, label, async () => {
      await go(page, `/accounts/${state.accountId}/${p}`);
      await expectText(page, state.accountName);
    });
  }

  await step(page, 'Tag the account (edit tags page)', async () => {
    await go(page, `/accounts/${state.accountId}/account_tags/edit`);
    await page.getByLabel('TEST', { exact: true }).check();
    await Promise.all([
      page.waitForURL((u) => !u.pathname.endsWith('/edit'), { timeout: NAV_TIMEOUT }),
      page.locator('form input[type=submit][value=Update], form button[type=submit]:visible').last().click(),
    ]);
    await expectText(page, 'TEST');
  });

  // ---- Settings / admin pages --------------------------------------------------------------------------------------
  for (const [label, p, text] of [
    ['Tenant settings page', '/admin_tenants/1', state.tenant],
    ['Tenant page shows Kill Bill clock', '/admin_tenants/1', 'Current date/time'],
    ['Users page', '/admin_allowed_users', 'admin'],
    ['Roles page', '/role_definitions', 'Roles'],
    ['Tags page', '/tags', 'Tags'],
    ['Tag definitions page', '/tag_definitions', 'AUTO_PAY_OFF'],
    ['Custom fields page', '/custom_fields', 'Custom Fields'],
    ['Queues page', '/queues', 'Queues'],
  ]) {
    await step(page, label, async () => {
      await go(page, p);
      await expectText(page, text);
    });
  }

  // ---- CSV exports (exercise the csv gem on both Rubies) -----------------------------------------------------------
  const CSV = /csv|octet-stream|text\/plain/i;
  await step(page, 'CSV export: accounts', () => expectDownload(ctx, '/accounts/download?allFieldsChecked=true', CSV));
  await step(page, 'CSV export: invoices', () => expectDownload(ctx, '/invoices/download?allFieldsChecked=true', CSV));
  await step(page, 'CSV export: payments', () => expectDownload(ctx, '/payments/download?allFieldsChecked=true', CSV));
  await step(page, 'JSON export: account', () => expectDownload(ctx, `/accounts/export/${state.accountId}`, /.*/, 50));

  // ---- Sign out ----------------------------------------------------------------------------------------------------
  await step(page, 'Sign out', async () => {
    await go(page, '/home');
    await Promise.all([page.waitForURL(/sign_in/, { timeout: NAV_TIMEOUT }), page.locator('a[href$="/users/sign_out"]').first().click()]);
    await page.locator('#user_kb_username').waitFor();
  });

  await step(page, 'Protected pages redirect to login after sign out', async () => {
    await go(page, '/accounts');
    if (!page.url().includes('sign_in')) throw new Error(`Expected redirect to sign_in, got ${page.url()}`);
  }, { expectFlashError: true }); // "You need to sign in before continuing" is the expected flash

  } catch (e) {
    if (!(e instanceof SuiteAbort)) throw e;
    console.log(`\n⛔ Aborting the suite: "${e.message}" is a prerequisite for every remaining step.`);
    results.push({ name: `(suite aborted after "${e.message}" - remaining steps not run)`, status: 'FAIL', ms: 0, url: '', problems: ['prerequisite step failed'], consoleErrors: [], screenshot: '' });
  }

  await browser.close();

  // ---- Report ------------------------------------------------------------------------------------------------------
  const failed = results.filter((r) => r.status === 'FAIL');
  const lines = results.map((r) => `${r.status}  ${r.name}${r.problems.length ? '\n        ' + r.problems.join('\n        ') : ''}`);
  const summary = `${results.length - failed.length}/${results.length} steps passed against ${BASE}`;
  fs.writeFileSync(path.join(OUT, 'results.txt'), lines.join('\n') + '\n\n' + summary + '\n');
  fs.writeFileSync(path.join(OUT, 'results.json'), JSON.stringify({ base: BASE, summary, state, results }, null, 2));
  console.log(`\n${summary}`);
  process.exit(failed.length ? 1 : 0);
})().catch((e) => {
  console.error('Fatal error in smoke test:', e);
  process.exit(3);
});
