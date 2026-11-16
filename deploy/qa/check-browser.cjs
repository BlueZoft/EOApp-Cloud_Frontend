const assert = require('node:assert/strict');
const { chromium } = require('playwright');
const base = process.env.DEPLOY_BASE_URL;
const url = new URL(base);
assert.equal(url.protocol, 'https:');
assert.ok(['localhost', '127.0.0.1', '::1'].includes(url.hostname), 'This synthetic-data test is local-only');
const pin = process.env.DEPLOY_TEST_SPKI;
assert.match(pin, /^[A-Za-z0-9+/]{43}=$/);
// Trust only the generated test leaf key in Chromium. Node and Python separately
// verify its full CA chain and hostname; no global ignoreHTTPSErrors is used.
const browserArgs = ['--no-sandbox', '--ignore-certificate-errors-spki-list=' + pin];
async function main() {
  const browser = await chromium.launch({ headless: true,
    ...(process.env.CHROMIUM_EXECUTABLE ? { executablePath: process.env.CHROMIUM_EXECUTABLE } : {}), args: browserArgs });
  let page;
  try {
    page = await browser.newPage({ viewport: { width: 1200, height: 1800 } });
    const errors = [], failed = [], violations = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('requestfailed', request => failed.push(new URL(request.url()).pathname));
    await page.exposeFunction('__recordDeploymentCsp', directive => violations.push(directive));
    await page.addInitScript(() => {
      document.addEventListener('securitypolicyviolation', e => window.__recordDeploymentCsp(e.violatedDirective));
    });
    page.setDefaultTimeout(15000);
    async function tap(locator) {
      await locator.waitFor({ state: 'visible' });
      const box = await locator.boundingBox();
      assert.ok(box, 'Control bounds unavailable');
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    }
    await page.goto(base);
    await page.waitForSelector('flutter-view', { state: 'attached', timeout: 30000 });
    await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
    await tap(page.getByRole('button', { name: 'සිංහල', exact: true }));
    await tap(page.getByRole('button', { name: 'English', exact: true }));
    await tap(page.getByRole('button', { name: 'Get started', exact: true }));
    await tap(page.getByRole('button', { name: /My purpose is not listed/ }));
    async function fill(label, value) {
      const input = page.getByRole('textbox', { name: label, exact: true });
      // Focus must reach Flutter and its next semantics frame before input.
      // Filling the DOM immediately can precede the engine's input listener.
      await tap(input);
      await input.evaluate(element => new Promise(resolve => {
        requestAnimationFrame(() => requestAnimationFrame(() => resolve(element === document.activeElement)));
      })).then(focused => assert.ok(focused, label + ' did not gain focus'));
      await input.fill(value);
      await page.keyboard.press('Tab');
      assert.equal(await input.inputValue(), value, label + ' was not entered');
    }
    await fill('Name', 'Synthetic HTTPS Applicant');
    await fill('Age (18–99)', '30');
    await fill('National identity card number', '199012345678');
    await tap(page.getByRole('button', { name: 'Gender', exact: true }));
    await tap(page.getByRole('button', { name: 'Female', exact: true }));
    await fill('Telephone', '0771234567');
    await fill('Address', 'Synthetic deployment test address');
    await tap(page.getByRole('button', { name: 'Choose a preferred branch', exact: true }));
    await tap(page.getByText('අගලවත්ත', { exact: true }).or(page.locator('[aria-label="අගලවත්ත"]')).first());
    await tap(page.getByRole('checkbox', { name: 'I agree to these details being used to contact me about my inquiry.', exact: true }));
    const incoming = page.waitForResponse(r => r.url() === base + '/api/v1/inquiries' && r.request().method() === 'POST');
    await tap(page.getByRole('button', { name: 'Send inquiry', exact: true }));
    const response = await incoming;
    assert.equal(response.status(), 201);
    const receipt = await response.json();
    assert.equal(receipt.inquiry.status, 'received');
    const original = response.request();
    const payload = original.postData();
    const key = original.headers()['idempotency-key'];
    const replay = await page.evaluate(async ({ base, payload, key }) => {
      const result = await fetch(base + '/api/v1/inquiries', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Idempotency-Key': key }, body: payload });
      return { status: result.status, body: await result.json() };
    }, { base, payload, key });
    assert.equal(replay.status, 200); assert.equal(replay.body.inquiry.reference, receipt.inquiry.reference);
    // Return to the welcome page. Reloading retains no customer form data.
    await page.goto(base);
    const placeholder = page.locator('flt-semantics-placeholder');
    if (await placeholder.count()) await placeholder.evaluate(element => element.click());
    await tap(page.getByRole('button', { name: 'Officer inbox', exact: true }));
    // Staff labels are intentionally English regardless of customer locale.
    await fill('Staff email', 'officer@local.test');
    await fill('Password', process.env.DEPLOY_TEST_PASSWORD);
    await tap(page.getByRole('button', { name: 'Sign in', exact: true }));
    await page.getByRole('button', { name: /Synthetic HTTPS Applicant/ }).waitFor();
    const cookies = await page.context().cookies(base + '/api/v1/staff/session');
    assert.ok(cookies.some(c => c.name === 'eoapp_staff' && c.secure && c.httpOnly && c.sameSite === 'Strict'));
    const mutation = await page.evaluate(async reference => {
      const target = '/api/v1/staff/inquiries/' + reference;
      const missing = await fetch(target, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ version: 0, status: 'assigned' }) });
      const session = await (await fetch('/api/v1/staff/session')).json();
      const accepted = await fetch(target, { method: 'PATCH', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfToken }, body: JSON.stringify({ version: 0, status: 'assigned' }) });
      return { missingStatus: missing.status, acceptedStatus: accepted.status, inquiry: (await accepted.json()).inquiry };
    }, receipt.inquiry.reference);
    assert.equal(mutation.missingStatus, 403); assert.equal(mutation.acceptedStatus, 200);
    assert.equal(mutation.inquiry.status, 'assigned'); assert.equal(mutation.inquiry.version, 1);
    assert.equal(mutation.inquiry.nic, undefined); assert.equal(mutation.inquiry.address, undefined);
    await tap(page.getByRole('button', { name: 'Sign out', exact: true }));
    const signedOut = await page.evaluate(async () => (await fetch('/api/v1/staff/session')).status);
    assert.equal(signedOut, 401);
    assert.deepEqual(violations, []);
    assert.deepEqual(errors, []); assert.deepEqual(failed, []);
    // The edge must not treat missing static files/API errors as SPA HTML.
    const large = await fetch(base + '/api/v1/inquiries', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ message: 'x'.repeat(20000) }) });
    assert.equal(large.status, 413); assert.equal((await large.json()).error.code, 'BODY_TOO_LARGE');
    let limited = false;
    for (let i = 1; i <= 12; i++) {
      const attempt = await fetch(base + '/api/v1/inquiries', { method: 'POST', headers: {
        'Content-Type': 'application/json', 'Idempotency-Key': key, 'X-Forwarded-For': '203.0.113.' + i }, body: payload });
      if (attempt.status === 429) {
        assert.ok(attempt.headers.has('retry-after')); assert.equal((await attempt.json()).error.code, 'RATE_LIMITED'); limited = true; break;
      }
      assert.equal(attempt.status, 200);
    }
    assert.ok(limited, 'Forged forwarding headers must not bypass the edge limit');
    console.log('PASS: public HTTPS submission/replay, Secure staff cookies, CSRF-protected update, logout, CSP, oversized-body rejection and edge rate limits');
  } catch (error) {
    if (page) console.error('Visible controls:', await page.getByRole('button').evaluateAll(els => els.map(e => e.getAttribute('aria-label') || e.textContent)));
    if (page && process.env.DEPLOY_QA_SCREENSHOT) await page.screenshot({path: process.env.DEPLOY_QA_SCREENSHOT});
    if (page) console.error('Synthetic public form fields:', await page.getByRole('textbox').evaluateAll(els => els.filter(e => ['Name','Age (18–99)','National identity card number','Telephone','Address'].includes(e.getAttribute('aria-label'))).map(e => ({ label: e.getAttribute('aria-label'), value: e.value }))));
    if (page) console.error('Checkbox states:', await page.getByRole('checkbox').evaluateAll(els => els.map(e => ({ label: e.getAttribute('aria-label') || e.textContent, checked: e.getAttribute('aria-checked') }))));
    throw error;
  } finally { await browser.close(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
