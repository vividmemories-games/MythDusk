export const DEFAULT_SEGMENTS = [
  { id: "f2p", name: "F2P", pace: 4.5, monthlyBudget: 0, buyRate: 0, color: "#a89bbd" },
  { id: "light", name: "Light", pace: 6.5, monthlyBudget: 120, buyRate: 18, color: "#67d8c7" },
  { id: "mid", name: "Mid", pace: 8.5, monthlyBudget: 350, buyRate: 36, color: "#b78cff" },
  { id: "high", name: "High", pace: 11, monthlyBudget: 950, buyRate: 62, color: "#e9ad5b" }
];

export const DEFAULT_CONFIG = {
  unlocks: [5, 25, 50],
  horizonWeeks: 12,
  weeklyCurrency: 450,
  startingCurrency: 600,
  currencyPerLevel: 75,
  summonsEnabled: true,
  summonUnlockLevel: 8,
  pullCost: 300,
  featuredRate: 2,
  pityPulls: 60,
  firstOfferLevel: 10,
  offersPerMonth: 2,
  packPrice: 79,
  packCurrency: 1800,
  segments: DEFAULT_SEGMENTS.map((segment) => ({ ...segment }))
};

export const PRESETS = {
  balanced: {},
  progression: {
    unlocks: [5, 20, 40], weeklyCurrency: 550, summonUnlockLevel: 12,
    pullCost: 300, featuredRate: 2.5, pityPulls: 50, firstOfferLevel: 14, offersPerMonth: 1
  },
  summon: {
    unlocks: [5, 30, 60], weeklyCurrency: 350, summonUnlockLevel: 6,
    pullCost: 300, featuredRate: 1.5, pityPulls: 70, firstOfferLevel: 8, offersPerMonth: 3
  }
};

export function clamp(value, min, max) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.min(max, Math.max(min, number)) : min;
}

export function normalizeConfig(input) {
  const c = { ...DEFAULT_CONFIG, ...input };
  const sortedUnlocks = (c.unlocks || DEFAULT_CONFIG.unlocks)
    .map((v, i) => clamp(v, i + 2, 100))
    .sort((a, b) => a - b);
  return {
    ...c,
    unlocks: sortedUnlocks,
    horizonWeeks: clamp(c.horizonWeeks, 4, 52),
    weeklyCurrency: clamp(c.weeklyCurrency, 0, 10000),
    startingCurrency: clamp(c.startingCurrency, 0, 10000),
    currencyPerLevel: clamp(c.currencyPerLevel, 0, 1000),
    summonUnlockLevel: clamp(c.summonUnlockLevel, 1, 99),
    pullCost: clamp(c.pullCost, 1, 5000),
    featuredRate: clamp(c.featuredRate, 0.1, 100),
    pityPulls: clamp(c.pityPulls, 1, 500),
    firstOfferLevel: clamp(c.firstOfferLevel, 1, 99),
    offersPerMonth: clamp(c.offersPerMonth, 0, 12),
    packPrice: clamp(c.packPrice, 1, 2000),
    packCurrency: clamp(c.packCurrency, 1, 50000),
    segments: (c.segments || DEFAULT_SEGMENTS).map((segment, i) => ({
      ...DEFAULT_SEGMENTS[i], ...segment,
      pace: clamp(segment.pace, 0.5, 30),
      monthlyBudget: clamp(segment.monthlyBudget, 0, 10000),
      buyRate: clamp(segment.buyRate, 0, 100)
    }))
  };
}

export function weeksToLevel(level, pace) {
  if (level <= 1) return 0;
  return (level - 1) / pace;
}

function offerWindows(config, segment, finalLevel) {
  if (!config.summonsEnabled || config.offersPerMonth <= 0 || finalLevel < config.firstOfferLevel) return 0;
  const firstEligibleWeek = weeksToLevel(config.firstOfferLevel, segment.pace);
  const eligibleWeeks = Math.max(0, config.horizonWeeks - firstEligibleWeek);
  return Math.max(1, Math.floor((eligibleWeeks / 4.345) * config.offersPerMonth) + 1);
}

export function simulateSegment(rawConfig, segment) {
  const config = normalizeConfig(rawConfig);
  const finalLevel = Math.min(100, Math.floor(1 + config.horizonWeeks * segment.pace));
  const coreHeroes = 1 + config.unlocks.filter((level) => level <= finalLevel).length;
  const windows = offerWindows(config, segment, finalLevel);
  const demandBuys = windows * (segment.buyRate / 100);
  const budgetBuys = config.packPrice > 0
    ? (segment.monthlyBudget * (config.horizonWeeks / 4.345)) / config.packPrice
    : 0;
  const expectedBuys = config.summonsEnabled ? Math.min(demandBuys, budgetBuys) : 0;
  const earnedCurrency = config.startingCurrency
    + config.weeklyCurrency * config.horizonWeeks
    + Math.max(0, finalLevel - 1) * config.currencyPerLevel;
  const summonEligible = config.summonsEnabled && finalLevel >= config.summonUnlockLevel;
  const freePulls = summonEligible ? Math.floor(earnedCurrency / config.pullCost) : 0;
  const paidPulls = summonEligible ? (expectedBuys * config.packCurrency) / config.pullCost : 0;
  const totalPulls = freePulls + paidPulls;
  const expectedFeatured = summonEligible
    ? Math.max(totalPulls * (config.featuredRate / 100), Math.floor(totalPulls / config.pityPulls))
    : 0;
  return {
    ...segment,
    finalLevel,
    coreHeroes,
    offerWindows: windows,
    expectedBuys,
    earnedCurrency,
    freePulls,
    paidPulls,
    totalPulls,
    expectedFeatured,
    spend: expectedBuys * config.packPrice
  };
}

export function simulate(rawConfig) {
  const config = normalizeConfig(rawConfig);
  const segments = config.segments.map((segment) => simulateSegment(config, segment));
  const totalSpend = segments.reduce((sum, segment) => sum + segment.spend, 0);
  const weightedSpend = segments.reduce((sum, segment, index) => sum + segment.spend * [0.6, 0.25, 0.1, 0.05][index], 0);
  const f2p = segments[0];
  const light = segments[1];
  const lastUnlock = config.unlocks[config.unlocks.length - 1];
  const finalHeroWeeks = weeksToLevel(lastUnlock, f2p.pace);
  return { config, segments, totalSpend, weightedSpend, f2p, light, finalHeroWeeks };
}

export function evaluateSignals(rawConfig, result = simulate(rawConfig)) {
  const config = result.config;
  const signals = [];
  const lastUnlock = config.unlocks[config.unlocks.length - 1];
  const firstPaidLevel = Math.min(config.summonUnlockLevel, config.firstOfferLevel);

  if (result.finalHeroWeeks > config.horizonWeeks) {
    signals.push({ tone: "warn", title: "Late core payoff", text: `F2P reaches about level ${result.f2p.finalLevel}; the level ${lastUnlock} hero sits beyond this ${config.horizonWeeks}-week view.` });
  } else {
    signals.push({ tone: "good", title: "Core path lands in-view", text: `A typical F2P player can reach all ${result.f2p.coreHeroes} core heroes in about ${result.finalHeroWeeks.toFixed(1)} weeks.` });
  }

  if (config.summonsEnabled && firstPaidLevel < config.unlocks[1]) {
    signals.push({ tone: "info", title: "Summons arrive between milestones", text: `Summons and offers begin near level ${firstPaidLevel}, before the level ${config.unlocks[1]} core hero—good for variety, but watch perceived pressure.` });
  } else if (config.summonsEnabled) {
    signals.push({ tone: "good", title: "Progression leads monetization", text: `Players earn two additional core heroes before the first summon-led purchase moment.` });
  } else {
    signals.push({ tone: "info", title: "Progression-only test", text: "Summons are disabled, so this scenario isolates pacing and guaranteed hero acquisition." });
  }

  const freePityRatio = config.summonsEnabled ? result.f2p.freePulls / config.pityPulls : 0;
  if (config.summonsEnabled && freePityRatio < 0.6) {
    signals.push({ tone: "warn", title: "Pity feels distant for F2P", text: `Free currency funds about ${result.f2p.freePulls} pulls—${Math.round(freePityRatio * 100)}% of hard pity during the test window.` });
  } else if (config.summonsEnabled) {
    signals.push({ tone: "good", title: "Visible F2P summon progress", text: `Free currency covers ${Math.round(freePityRatio * 100)}% of hard pity in the selected horizon.` });
  }

  if (result.light.offerWindows > 6 && result.light.expectedBuys < 1) {
    signals.push({ tone: "warn", title: "Offer fatigue risk", text: `${result.light.offerWindows} windows compete for fewer than one expected light-spender purchase. Reduce cadence or strengthen relevance.` });
  } else {
    signals.push({ tone: "info", title: "Purchase opportunity", text: `The light segment sees ${result.light.offerWindows} windows and about ${result.light.expectedBuys.toFixed(1)} expected purchases in this directional model.` });
  }
  return signals;
}
