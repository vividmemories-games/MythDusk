'use strict';

const {google} = require('googleapis');
const jwt = require('jsonwebtoken');

const PACKAGE_NAME = 'com.vividmemories.mythdusk';
const BUNDLE_ID = 'com.vividmemories.mythdusk';

function decodeJwsPayload(jws) {
  if (!jws || typeof jws !== 'string') return null;
  const parts = jws.split('.');
  if (parts.length < 2) return null;
  const payload = Buffer.from(parts[1], 'base64url').toString('utf8');
  try {
    return JSON.parse(payload);
  } catch (_) {
    return null;
  }
}

async function verifyAndroidPurchase({productId, purchaseToken, serviceAccountJson}) {
  if (!serviceAccountJson) {
    throw new Error('PLAY_SERVICE_ACCOUNT_JSON secret is not configured.');
  }
  let credentials;
  try {
    credentials = JSON.parse(serviceAccountJson);
  } catch (_) {
    throw new Error('PLAY_SERVICE_ACCOUNT_JSON is not valid JSON.');
  }
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const androidpublisher = google.androidpublisher({version: 'v3', auth});
  const res = await androidpublisher.purchases.products.get({
    packageName: PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });
  const data = res.data || {};
  // 0 = purchased, 1 = canceled
  if (data.purchaseState !== 0 && data.purchaseState !== undefined) {
    throw new Error('Android purchase is not in purchased state.');
  }
  return {
    platform: 'android',
    orderId: data.orderId || purchaseToken,
    productId,
  };
}

function makeAppleJwt({keyP8, keyId, issuerId}) {
  if (!keyP8 || !keyId || !issuerId) {
    throw new Error('Apple IAP secrets are not fully configured.');
  }
  return jwt.sign({}, keyP8, {
    algorithm: 'ES256',
    expiresIn: '20m',
    audience: 'appstoreconnect-v1',
    issuer: issuerId,
    header: {alg: 'ES256', kid: keyId, typ: 'JWT'},
  });
}

async function fetchAppleTransaction({transactionId, token, sandbox}) {
  const host = sandbox
    ? 'api.storekit-sandbox.itunes.apple.com'
    : 'api.storekit.itunes.apple.com';
  const res = await fetch(
    `https://${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
    {headers: {Authorization: `Bearer ${token}`}},
  );
  return res;
}

async function verifyApplePurchase({
  productId,
  transactionId,
  verificationData,
  keyP8,
  keyId,
  issuerId,
}) {
  // Prefer JWS payload when the store sends a signed transaction directly.
  const local = decodeJwsPayload(verificationData);
  if (local && local.productId && local.bundleId) {
    if (local.bundleId !== BUNDLE_ID) {
      throw new Error('Apple bundleId mismatch.');
    }
    if (local.productId !== productId) {
      throw new Error('Apple productId mismatch.');
    }
    return {
      platform: 'ios',
      orderId: String(local.transactionId || transactionId),
      productId,
    };
  }

  const token = makeAppleJwt({keyP8, keyId, issuerId});
  const id = transactionId || (local && local.transactionId);
  if (!id) {
    throw new Error('Apple transaction id missing.');
  }

  let res = await fetchAppleTransaction({
    transactionId: id,
    token,
    sandbox: true,
  });
  if (res.status === 404) {
    res = await fetchAppleTransaction({
      transactionId: id,
      token,
      sandbox: false,
    });
  }
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Apple transaction lookup failed (${res.status}): ${text}`);
  }
  const body = await res.json();
  const payload = decodeJwsPayload(body.signedTransactionInfo);
  if (!payload) {
    throw new Error('Apple signedTransactionInfo missing.');
  }
  if (payload.bundleId !== BUNDLE_ID) {
    throw new Error('Apple bundleId mismatch.');
  }
  if (payload.productId !== productId) {
    throw new Error('Apple productId mismatch.');
  }
  return {
    platform: 'ios',
    orderId: String(payload.transactionId || id),
    productId,
  };
}

module.exports = {
  PACKAGE_NAME,
  BUNDLE_ID,
  verifyAndroidPurchase,
  verifyApplePurchase,
  decodeJwsPayload,
};
