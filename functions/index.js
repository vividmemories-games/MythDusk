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

exports.ensureUser = onCall(async (request) => {
  const uid = requireAuth(request);
  const ref = getFirestore().doc(`users/${uid}`);
  const snap = await ref.get();
  if (snap.exists) {
    return {created: false, uid};
  }
  await ref.set({
    schemaVersion: SCHEMA_VERSION,
    displayName: 'Wanderer',
    coins: STARTING_COINS,
    gems: STARTING_GEMS,
    lives: MAX_LIVES,
    selectedHeroId: 'mage',
    completedNodeIds: [],
    claimedStarterPackIds: [],
    claimedCosmeticIds: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {created: true, uid};
});

exports.tickLives = onCall(async (request) => {
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

exports.refillLivesWithGems = onCall(async (request) => {
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
exports.submitBattleRun = onCall(async (request) => {
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
      return {
        alreadyProcessed: true,
        grantCoins: run.grantCoins ?? 0,
        completedNode: run.completedNode === true,
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
    const nodeId = run.nodeId;
    const completed = Array.isArray(user.completedNodeIds) ? user.completedNodeIds : [];
    const alreadyCleared = completed.includes(nodeId);
    const nextCompleted = won && nodeId && !alreadyCleared
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
      completedNode: won && !alreadyCleared,
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
      completedNode: won && !alreadyCleared,
    };
  });
});

/**
 * Emulator / QA receipts only. Production rejects until store secrets exist.
 * Never trust client-supplied coin/gem amounts — look up productId.
 */
exports.validateIapReceipt = onCall(async (request) => {
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
