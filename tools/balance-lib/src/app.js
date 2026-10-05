import { DEFAULT_CONFIG, PRESETS, evaluateSignals, normalizeConfig, simulate, weeksToLevel } from "./model.js";

const inputIds = [
  "unlock1", "unlock2", "unlock3", "horizonWeeks", "weeklyCurrency", "startingCurrency",
  "currencyPerLevel", "summonsEnabled", "summonUnlockLevel", "pullCost", "featuredRate",
  "pityPulls", "firstOfferLevel", "offersPerMonth", "packPrice", "packCurrency"
];
const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];
const deepCopy = (value) => JSON.parse(JSON.stringify(value));
const compact = new Intl.NumberFormat("en", { maximumFractionDigits: 1 });
const nok = new Intl.NumberFormat("en", { style: "currency", currency: "NOK", maximumFractionDigits: 0 });

let baseline = deepCopy(DEFAULT_CONFIG);
let activePreset = "balanced";
let toastTimer;

function renderSegmentEditor(segments) {
  $("#segmentEditor").innerHTML = `
    <div class="segment-grid segment-grid-head"><span>Segment</span><span>Levels / week</span><span>Budget / month</span><span>Buy rate</span></div>
    ${segments.map((segment) => `
      <div class="segment-grid" data-segment="${segment.id}">
        <strong><i style="--segment-color:${segment.color}"></i>${segment.name}</strong>
        <label><input data-key="pace" type="number" min="0.5" max="30" step="0.5" value="${segment.pace}" /><small>lv</small></label>
        <label><input data-key="monthlyBudget" type="number" min="0" max="10000" step="10" value="${segment.monthlyBudget}" /><small>NOK</small></label>
        <label><input data-key="buyRate" type="number" min="0" max="100" step="1" value="${segment.buyRate}" /><small>%</small></label>
      </div>`).join("")}
  `;
  $$("#segmentEditor input").forEach((input) => input.addEventListener("input", update));
}

function readConfig() {
  const value = (id) => Number($(`#${id}`).value);
  const segments = $$("#segmentEditor [data-segment]").map((row, index) => ({
    ...DEFAULT_CONFIG.segments[index],
    pace: Number(row.querySelector('[data-key="pace"]').value),
    monthlyBudget: Number(row.querySelector('[data-key="monthlyBudget"]').value),
    buyRate: Number(row.querySelector('[data-key="buyRate"]').value)
  }));
  return normalizeConfig({
    unlocks: [value("unlock1"), value("unlock2"), value("unlock3")],
    horizonWeeks: value("horizonWeeks"), weeklyCurrency: value("weeklyCurrency"),
    startingCurrency: value("startingCurrency"), currencyPerLevel: value("currencyPerLevel"),
    summonsEnabled: $("#summonsEnabled").checked, summonUnlockLevel: value("summonUnlockLevel"),
    pullCost: value("pullCost"), featuredRate: value("featuredRate"), pityPulls: value("pityPulls"),
    firstOfferLevel: value("firstOfferLevel"), offersPerMonth: value("offersPerMonth"),
    packPrice: value("packPrice"), packCurrency: value("packCurrency"), segments
  });
}

function writeConfig(config) {
  const c = normalizeConfig(config);
  ["unlock1", "unlock2", "unlock3"].forEach((id, index) => { $(`#${id}`).value = c.unlocks[index]; });
  ["horizonWeeks", "weeklyCurrency", "startingCurrency", "currencyPerLevel", "summonUnlockLevel",
    "pullCost", "featuredRate", "pityPulls", "firstOfferLevel", "offersPerMonth", "packPrice", "packCurrency"]
    .forEach((id) => { $(`#${id}`).value = c[id]; });
  $("#summonsEnabled").checked = c.summonsEnabled;
  renderSegmentEditor(c.segments);
  update();
}

function deltaMarkup(current, previous, formatter = compact.format) {
  const delta = current - previous;
  if (Math.abs(delta) < 0.05) return `<span class="delta neutral">No change</span>`;
  return `<span class="delta ${delta > 0 ? "up" : "down"}">${delta > 0 ? "↑" : "↓"} ${formatter(Math.abs(delta))} vs baseline</span>`;
}

function renderKpis(result, base) {
  const items = [
    { label: "F2P final hero", value: result.finalHeroWeeks <= result.config.horizonWeeks ? `Week ${compact.format(result.finalHeroWeeks)}` : `After week ${result.config.horizonWeeks}`, raw: -result.finalHeroWeeks, base: -base.finalHeroWeeks, help: `Level ${result.config.unlocks[2]} guaranteed unlock` },
    { label: "F2P free pulls", value: compact.format(result.f2p.freePulls), raw: result.f2p.freePulls, base: base.f2p.freePulls, help: `${Math.round((result.f2p.freePulls / result.config.pityPulls) * 100)}% of hard pity` },
    { label: "Light buyer windows", value: result.light.offerWindows, raw: result.light.offerWindows, base: base.light.offerWindows, help: `${result.light.expectedBuys.toFixed(1)} expected purchases` },
    { label: "Weighted spend", value: nok.format(result.weightedSpend), raw: result.weightedSpend, base: base.weightedSpend, format: nok.format, help: "Per modeled player mix" }
  ];
  $("#kpiGrid").innerHTML = items.map((item) => `
    <article class="kpi-card">
      <span>${item.label}</span><strong>${item.value}</strong><small>${item.help}</small>
      ${deltaMarkup(item.raw, item.base, item.format || compact.format)}
    </article>`).join("");
}

function renderChart(result) {
  const width = 760, height = 260, left = 44, right = 18, top = 20, bottom = 38;
  const plotW = width - left - right, plotH = height - top - bottom;
  const maxLevel = Math.min(100, Math.max(result.config.unlocks[2] + 10, ...result.segments.map((s) => s.finalLevel)));
  const x = (week) => left + (week / result.config.horizonWeeks) * plotW;
  const y = (level) => top + plotH - ((level - 1) / Math.max(1, maxLevel - 1)) * plotH;
  const gridLevels = [1, Math.round(maxLevel / 2), maxLevel];
  let svg = gridLevels.map((level) => `<g><line class="grid-line" x1="${left}" y1="${y(level)}" x2="${width-right}" y2="${y(level)}"/><text class="axis-label" x="${left-9}" y="${y(level)+4}" text-anchor="end">${level}</text></g>`).join("");
  svg += [0, Math.round(result.config.horizonWeeks/2), result.config.horizonWeeks].map((week) => `<text class="axis-label" x="${x(week)}" y="${height-10}" text-anchor="middle">W${week}</text>`).join("");
  result.config.unlocks.forEach((level, index) => {
    if (level <= maxLevel) svg += `<g><line class="milestone-line" x1="${left}" y1="${y(level)}" x2="${width-right}" y2="${y(level)}"/><text class="milestone-label" x="${width-right-4}" y="${y(level)-6}" text-anchor="end">H${index+2} · L${level}</text></g>`;
  });
  result.segments.forEach((segment) => {
    const points = Array.from({length: 13}, (_, i) => {
      const week = (i / 12) * result.config.horizonWeeks;
      const level = Math.min(100, 1 + week * segment.pace);
      return `${x(week)},${y(Math.min(level, maxLevel))}`;
    }).join(" ");
    svg += `<polyline class="progress-line" style="--line-color:${segment.color}" points="${points}"/><circle cx="${x(result.config.horizonWeeks)}" cy="${y(Math.min(segment.finalLevel,maxLevel))}" r="4" fill="${segment.color}"/>`;
  });
  $("#progressionChart").setAttribute("viewBox", `0 0 ${width} ${height}`);
  $("#progressionChart").innerHTML = svg;
  $("#chartLegend").innerHTML = result.segments.map((s) => `<span><i style="--legend-color:${s.color}"></i>${s.name}</span>`).join("");
  $("#milestoneStrip").innerHTML = result.config.unlocks.map((level, index) => `<span><i>Hero ${index + 2}</i><strong>Level ${level}</strong><small>F2P · week ${compact.format(weeksToLevel(level, result.config.segments[0].pace))}</small></span>`).join("");
}

function renderTable(result) {
  $("#outcomeRows").innerHTML = result.segments.map((segment) => `
    <tr>
      <td><strong class="segment-name"><i style="--segment-color:${segment.color}"></i>${segment.name}</strong></td>
      <td>${segment.finalLevel}</td><td>${segment.coreHeroes} / 4</td>
      <td>${compact.format(segment.totalPulls)} <small>${compact.format(segment.freePulls)} free</small></td>
      <td>${segment.offerWindows}</td><td>${segment.expectedBuys.toFixed(1)}</td><td>${nok.format(segment.spend)}</td>
    </tr>`).join("");
}

function renderInsights(result) {
  const signals = evaluateSignals(result.config, result);
  const warnings = signals.filter((signal) => signal.tone === "warn").length;
  $("#healthBadge").className = `health-badge ${warnings ? "watch" : "healthy"}`;
  $("#healthBadge").textContent = warnings > 1 ? `${warnings} pressure points` : warnings === 1 ? "1 pressure point" : "Healthy shape";
  $("#insights").innerHTML = signals.map((signal) => `
    <div class="insight ${signal.tone}"><span>${signal.tone === "good" ? "✓" : signal.tone === "warn" ? "!" : "i"}</span><div><strong>${signal.title}</strong><p>${signal.text}</p></div></div>`).join("");
}

function setSummonDisabled(disabled) {
  $$(".summon-fields input, #firstOfferLevel, #offersPerMonth, #packPrice, #packCurrency").forEach((el) => { el.disabled = disabled; });
  $(".summon-fields").classList.toggle("disabled", disabled);
}

function update() {
  const config = readConfig();
  const result = simulate(config);
  const base = simulate(baseline);
  setSummonDisabled(!config.summonsEnabled);
  renderKpis(result, base);
  renderChart(result);
  renderTable(result);
  renderInsights(result);
  const changed = JSON.stringify(config) !== JSON.stringify(normalizeConfig(baseline));
  $("#scenarioStatus").textContent = changed ? "Modified scenario" : "Matches baseline";
  $("#scenarioStatus").classList.toggle("changed", changed);
}

function showToast(message) {
  clearTimeout(toastTimer);
  $("#toast").textContent = message;
  $("#toast").classList.add("show");
  toastTimer = setTimeout(() => $("#toast").classList.remove("show"), 2400);
}

inputIds.forEach((id) => $(`#${id}`).addEventListener("input", update));
renderSegmentEditor(DEFAULT_CONFIG.segments);

$$("[data-preset]").forEach((button) => button.addEventListener("click", () => {
  activePreset = button.dataset.preset;
  $$("[data-preset]").forEach((item) => item.classList.toggle("active", item === button));
  writeConfig({ ...deepCopy(DEFAULT_CONFIG), ...PRESETS[activePreset] });
  showToast(`${button.textContent} preset applied`);
}));

$("#saveBaselineButton").addEventListener("click", () => {
  baseline = deepCopy(readConfig());
  update();
  showToast("Current setup saved as the comparison baseline");
});

$("#resetButton").addEventListener("click", () => {
  activePreset = "balanced";
  $$("[data-preset]").forEach((item) => item.classList.toggle("active", item.dataset.preset === "balanced"));
  baseline = deepCopy(DEFAULT_CONFIG);
  writeConfig(DEFAULT_CONFIG);
  showToast("Balanced defaults restored");
});

update();
