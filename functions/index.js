'use strict';

const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');

initializeApp();

const SCHEMA_VERSION = 14;
const STARTING_COINS = 500;
const STARTING_GEMS = 50;
const MAX_LIVES = 5;
const LIFE_REGEN_MINUTES = 20;
const GEM_LIFE_REFILL_COST = 75;
const GEM_LIFE_REFILL_AMOUNT = 3;
const GEM_LIFE_REFILLS_PER_DAY = 3;

const IAP_GRANTS = {
  mythdusk_starter_pack: {coins: 400, gems: 40, cosmeticId: 'overlay_dusk_sash', entitlementId: 'starter_pack_001'},
  mythdusk_value_30d: {gems: 200, entitlementId: 'value_pack_30d', days: 30, dailyGems: 5},
  mythdusk_gems_small: {gems: 80},
  mythdusk_gems_medium: {gems: 250},
  mythdusk_prep_box: {prep: {vanguard_tonic: 2, aegis_flask: 1}},
};

// Gen2 callables are Cloud Run services. Without public invoker, clients get
// HTTP 401 before Firebase Auth is checked. Auth is still enforced in requireAuth.
const CALLABLE_OPTS = {invoker: 'public'};

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Sign in first.');
  }
  return request.auth.uid;
}

function utcDayKey(date) {
  return date.toISOString().slice(0, 10);
}

function applyLifeRegen(lives, lastLifeRegenAt, now) {
  if (lives >= MAX_LIVES) {
    return {lives: MAX_LIVES, lastLifeRegenAt: null};
  }
  const start = lastLifeRegenAt ? new Date(lastLifeRegenAt) : now;
  const gained = Math.floor((now.getTime() - start.getTime()) / (LIFE_REGEN_MINUTES * 60 * 1000));
  if (gained <= 0) {
    return {lives, lastLifeRegenAt};
  }
  const nextLives = Math.min(MAX_LIVES, lives + gained);
  if (nextLives >= MAX_LIVES) {
    return {lives: MAX_LIVES, lastLifeRegenAt: null};
  }
  const advanced = new Date(start.getTime() + gained * LIFE_REGEN_MINUTES * 60 * 1000);
  return {lives: nextLives, lastLifeRegenAt: advanced.toISOString()};
}

/**
 * One-time create bootstrap from local cache. Only applied when the user doc
 * does not exist yet — never overwrites an existing cloud profile.
 */
function clampBootstrap(boot) {
  const raw = boot && typeof boot === 'object' ? boot : {};
  const completed = Array.isArray(raw.completedNodeIds)
    ? raw.completedNodeIds
      .filter((id) => typeof id === 'string' && id.length > 0 && id.length < 64)
      .slice(0, 500)
    : [];
  const coins = Math.max(
    0,
    Math.min(1000000, Number.isFinite(Number(raw.coins)) ? Number(raw.coins) : STARTING_COINS),
  );
  const gems = Math.max(
    0,
    Math.min(100000, Number.isFinite(Number(raw.gems)) ? Number(raw.gems) : STARTING_GEMS),
  );
  const lives = Math.max(
    0,
    Math.min(MAX_LIVES, Number.isFinite(Number(raw.lives)) ? Number(raw.lives) : MAX_LIVES),
  );
  const displayName =
    typeof raw.displayName === 'string' && raw.displayName.trim().length > 0
      ? raw.displayName.trim().slice(0, 40)
      : 'Wanderer';
  const selectedHeroId =
    typeof raw.selectedHeroId === 'string' && raw.selectedHeroId.length > 0
      ? raw.selectedHeroId.slice(0, 63)
      : 'mage';
  return {completedNodeIds: completed, coins, gems, lives, displayName, selectedHeroId};
}

function publicProfile(data) {
  return {
    schemaVersion: data.schemaVersion ?? SCHEMA_VERSION,
    displayName: data.displayName ?? 'Wanderer',
    coins: data.coins ?? 0,
    gems: data.gems ?? 0,
    lives: data.lives ?? 0,
    lastLifeRegenAt: data.lastLifeRegenAt ?? null,
    gemLifeRefillDay: data.gemLifeRefillDay ?? '',
    gemLifeRefillCount: data.gemLifeRefillCount ?? 0,
    selectedHeroId: data.selectedHeroId ?? 'mage',
    completedNodeIds: Array.isArray(data.completedNodeIds) ? data.completedNodeIds : [],
    claimedStarterPackIds: Array.isArray(data.claimedStarterPackIds)
      ? data.claimedStarterPackIds
      : [],
    claimedCosmeticIds: Array.isArray(data.claimedCosmeticIds)
      ? data.claimedCosmeticIds
      : [],
  };
}

exports.ensureUser = onCall(CALLABLE_OPTS, async (request) => {
  const uid = requireAuth(request);
  const ref = getFirestore().doc(`users/${uid}`);
  const snap = await ref.get();
  if (snap.exists) {
    return {created: false, uid, profile: publicProfile(snap.data())};
  }
  const boot = clampBootstrap(request.data && request.data.bootstrap);
  const profile = {
    schemaVersion: SCHEMA_VERSION,
    displayName: boot.displayName,
    coins: boot.coins,
    gems: boot.gems,
    lives: boot.lives,
    selectedHeroId: boot.selectedHeroId,
    completedNodeIds: boot.completedNodeIds,
    claimedStarterPackIds: [],
    claimedCosmeticIds: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  await ref.set(profile);
  return {created: true, uid, profile: publicProfile(profile)};
});

exports.tickLives = onCall(CALLABLE_OPTS, async (request) => {
  const uid = requireAuth(request);
  const ref = getFirestore().doc(`users/${uid}`);
  const result = await getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Profile missing. Call ensureUser.');
    }
    const data = snap.data();
    const now = new Date();
    const next = applyLifeRegen(data.lives ?? 0, data.lastLifeRegenAt ?? null, now);
    tx.update(ref, {
      lives: next.lives,
      lastLifeRegenAt: next.lastLifeRegenAt,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return next;
  });
  return result;
});

exports.refillLivesWithGems = onCall(CALLABLE_OPTS, async (request) => {
  const uid = requireAuth(request);
  const ref = getFirestore().doc(`users/${uid}`);
  return getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Profile missing.');
    }
    const data = snap.data();
    const now = new Date();
    const day = utcDayKey(now);
    const count = data.gemLifeRefillDay === day ? (data.gemLifeRefillCount ?? 0) : 0;
    if (count >= GEM_LIFE_REFILLS_PER_DAY) {
      throw new HttpsError('resource-exhausted', 'Daily gem refill cap reached.');
    }
    if ((data.gems ?? 0) < GEM_LIFE_REFILL_COST) {
      throw new HttpsError('failed-precondition', 'Not enough gems.');
    }
    const lives = Math.min(MAX_LIVES, (data.lives ?? 0) + GEM_LIFE_REFILL_AMOUNT);
    tx.update(ref, {
      gems: data.gems - GEM_LIFE_REFILL_COST,
      lives,
      lastLifeRegenAt: lives >= MAX_LIVES ? null : (data.lastLifeRegenAt ?? now.toISOString()),
      gemLifeRefillDay: day,
      gemLifeRefillCount: count + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {lives, gems: data.gems - GEM_LIFE_REFILL_COST};
  });
});

/**
 * Idempotent PvE settlement. Client creates battle_runs/{runId} then calls
 * this with the same runId. Duplicate calls return the original grant.
 */
exports.submitBattleRun = onCall(CALLABLE_OPTS, async (request) => {
  const uid = requireAuth(request);
  const runId = request.data && request.data.runId;
  if (!runId || typeof runId !== 'string') {
    throw new HttpsError('invalid-argument', 'runId required.');
  }
  const db = getFirestore();
  const runRef = db.doc(`battle_runs/${runId}`);
  const userRef = db.doc(`users/${uid}`);

  return db.runTransaction(async (tx) => {
    const runSnap = await tx.get(runRef);
    if (!runSnap.exists) {
      throw new HttpsError('not-found', 'Submit the run document first.');
    }
    const run = runSnap.data();
    if (run.uid !== uid) {
      throw new HttpsError('permission-denied', 'Not your run.');
    }
    if (run.processed === true) {
      const userSnap = await tx.get(userRef);
      const user = userSnap.exists ? userSnap.data() : {};
      return {
        alreadyProcessed: true,
        grantCoins: run.grantCoins ?? 0,
        completedNode: run.completedNode === true,
        coins: user.coins ?? 0,
        lives: user.lives ?? 0,
        completedNodeIds: Array.isArray(user.completedNodeIds)
          ? user.completedNodeIds
          : [],
      };
    }

    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError('not-found', 'Profile missing.');
    }
    const user = userSnap.data();
    const won = run.won === true;
    const coinReward = Math.max(0, Math.min(5000, run.coinReward ?? 0));
    const grantCoins = won ? coinReward : 0;
    const nodeId = typeof run.nodeId === 'string' ? run.nodeId : '';
    const mode = typeof run.mode === 'string' ? run.mode : 'pve';
    const completed = Array.isArray(user.completedNodeIds) ? user.completedNodeIds : [];
    const trackCampaignNode = mode === 'pve' && nodeId.length > 0;
    const alreadyCleared = trackCampaignNode && completed.includes(nodeId);
    const nextCompleted = won && trackCampaignNode && !alreadyCleared
      ? [...completed, nodeId]
      : completed;

    let lives = user.lives ?? 0;
    let lastLifeRegenAt = user.lastLifeRegenAt ?? null;
    if (!won && run.mode !== 'pvp') {
      lives = Math.max(0, lives - 1);
      if (lives < MAX_LIVES && !lastLifeRegenAt) {
        lastLifeRegenAt = new Date().toISOString();
      }
    }

    tx.update(runRef, {
      processed: true,
      grantCoins,
      completedNode: won && trackCampaignNode && !alreadyCleared,
      processedAt: FieldValue.serverTimestamp(),
    });
    tx.update(userRef, {
      coins: (user.coins ?? 0) + grantCoins,
      completedNodeIds: nextCompleted,
      lives,
      lastLifeRegenAt,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return {
      alreadyProcessed: false,
      grantCoins,
      completedNode: won && trackCampaignNode && !alreadyCleared,
      coins: (user.coins ?? 0) + grantCoins,
      lives,
      completedNodeIds: nextCompleted,
    };
  });
});

/**
 * Emulator / QA receipts only. Production rejects until store secrets exist.
 * Never trust client-supplied coin/gem amounts — look up productId.
 */
exports.validateIapReceipt = onCall(CALLABLE_OPTS, async (request) => {
  const uid = requireAuth(request);
  const productId = request.data && request.data.productId;
  const receiptId = request.data && request.data.receiptId;
  const qaToken = request.data && request.data.qaToken;
  if (!productId || !receiptId) {
    throw new HttpsError('invalid-argument', 'productId and receiptId required.');
  }
  const grant = IAP_GRANTS[productId];
  if (!grant) {
    throw new HttpsError('not-found', 'Unknown product.');
  }

  const projectId = process.env.GCLOUD_PROJECT || '';
  const emulator = Boolean(process.env.FUNCTIONS_EMULATOR);
  if (!emulator && qaToken !== `qa-${projectId}`) {
    throw new HttpsError(
      'failed-precondition',
      'Store receipt validation is not configured. No client grants.',
    );
  }

  const db = getFirestore();
  const receiptRef = db.doc(`iap_receipts/${receiptId}`);
  const userRef = db.doc(`users/${uid}`);

  return db.runTransaction(async (tx) => {
    const existing = await tx.get(receiptRef);
    if (existing.exists && existing.data().processed === true) {
      return {alreadyProcessed: true, productId};
    }
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError('not-found', 'Profile missing.');
    }
    const user = userSnap.data();
    const claimed = Array.isArray(user.claimedStarterPackIds)
      ? user.claimedStarterPackIds
      : [];
    if (grant.entitlementId && claimed.includes(grant.entitlementId)) {
      tx.set(receiptRef, {
        uid,
        productId,
        processed: true,
        duplicateEntitlement: true,
        processedAt: FieldValue.serverTimestamp(),
      });
      return {alreadyProcessed: true, productId};
    }

    const patch = {
      coins: (user.coins ?? 0) + (grant.coins ?? 0),
      gems: (user.gems ?? 0) + (grant.gems ?? 0),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (grant.entitlementId) {
      patch.claimedStarterPackIds = [...claimed, grant.entitlementId];
    }
    if (grant.cosmeticId) {
      const cosmetics = Array.isArray(user.claimedCosmeticIds)
        ? user.claimedCosmeticIds
        : [];
      if (!cosmetics.includes(grant.cosmeticId)) {
        patch.claimedCosmeticIds = [...cosmetics, grant.cosmeticId];
      }
    }
    if (grant.prep) {
      const inv = {...(user.prepInventory || {})};
      for (const [key, amount] of Object.entries(grant.prep)) {
        inv[key] = (inv[key] ?? 0) + amount;
      }
      patch.prepInventory = inv;
    }

    tx.set(receiptRef, {
      uid,
      productId,
      processed: true,
      processedAt: FieldValue.serverTimestamp(),
    });
    tx.update(userRef, patch);
    return {alreadyProcessed: false, productId, grant};
  });
});
