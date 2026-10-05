const { chromium } = require("playwright");
const assert = require("node:assert/strict");

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1100 }, deviceScaleFactor: 1 });
  const errors = [];
  page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("http://127.0.0.1:4173", { waitUntil: "networkidle" });

  await page.screenshot({ path: "tests/mythdusk-desktop.png", fullPage: true });
  assert.equal(await page.locator("#outcomeRows tr").count(), 4, "renders all player segments");
  assert.equal(await page.locator("#milestoneStrip span").count(), 3, "keeps all level unlock milestones visible");
  assert.equal(await page.locator("#kpiGrid .kpi-card").count(), 4, "renders comparison KPIs");

  const previousPulls = await page.locator("#outcomeRows tr").first().locator("td").nth(3).textContent();
  await page.locator("#weeklyCurrency").fill("900");
  const nextPulls = await page.locator("#outcomeRows tr").first().locator("td").nth(3).textContent();
  assert.notEqual(nextPulls, previousPulls, "currency control updates simulation output");
  assert.match(await page.locator("#scenarioStatus").textContent(), /Modified/, "marks changed scenario");

  await page.locator("#summonsEnabled").uncheck();
  assert.match(await page.locator("#outcomeRows tr").first().locator("td").nth(3).textContent(), /^0/, "summon toggle clears pulls");
  assert.equal(await page.locator("#pullCost").isDisabled(), true, "summon controls disable when summons are off");

  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: "tests/mythdusk-mobile.png", fullPage: true });
  assert.ok((await page.locator("body").evaluate((element) => element.scrollWidth)) <= 390, "mobile view has no horizontal overflow");
  assert.deepEqual(errors, [], `page has no runtime errors: ${errors.join("; ")}`);

  await browser.close();
  console.log("Interactive and visual checks passed");
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
