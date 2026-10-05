import assert from "node:assert/strict";
import { DEFAULT_CONFIG, evaluateSignals, normalizeConfig, simulate, simulateSegment } from "../src/model.js";

const baseline = simulate(DEFAULT_CONFIG);
assert.equal(baseline.segments.length, 4, "models all four player segments");
assert.equal(baseline.f2p.coreHeroes, 4, "F2P reaches all default level heroes in 12 weeks");
assert.equal(baseline.f2p.spend, 0, "F2P never creates paid spend");
assert.ok(baseline.segments[3].spend > baseline.light.spend, "high spender spends more than light spender");
assert.ok(evaluateSignals(DEFAULT_CONFIG, baseline).length >= 3, "returns useful balance signals");

const noSummons = simulate({ ...DEFAULT_CONFIG, summonsEnabled: false });
for (const segment of noSummons.segments) {
  assert.equal(segment.totalPulls, 0, "disabled summons produce zero pulls");
  assert.equal(segment.offerWindows, 0, "disabled summons produce zero offer windows");
  assert.equal(segment.spend, 0, "disabled summons produce zero spend");
}

const lateUnlock = simulate({ ...DEFAULT_CONFIG, unlocks: [5, 25, 90] });
assert.equal(lateUnlock.f2p.coreHeroes, 3, "late hero remains locked for default F2P horizon");
assert.ok(evaluateSignals(lateUnlock.config, lateUnlock).some((s) => s.title === "Late core payoff"));

const zeroBudget = simulateSegment(DEFAULT_CONFIG, { ...DEFAULT_CONFIG.segments[2], monthlyBudget: 0 });
assert.equal(zeroBudget.expectedBuys, 0, "budget caps expected purchases");

const malformed = normalizeConfig({ ...DEFAULT_CONFIG, unlocks: [50, 5, 25], pullCost: 0 });
assert.deepEqual(malformed.unlocks, [5, 25, 50], "sorts unlock levels");
assert.equal(malformed.pullCost, 1, "prevents divide-by-zero pull cost");

console.log("Model tests passed");
