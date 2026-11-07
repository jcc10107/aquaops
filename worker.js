/**
 * Aqua Ops — Free FCM Push Notification Worker
 * Runs natively in Cloudflare Workers using WebCrypto RS256
 *
 * Called directly by the Flutter app right after a write that should
 * notify someone, for real-time delivery instead of GitHub Actions'
 * ~15-min poll. Request body:
 *   { recipientId, title, messageText, conversationId?, data? }         - one user
 *   { recipientIds: [...], title, messageText, ... }                    - several specific users
 *   { broadcastRoles: ['staff','owner'], title, messageText, ... }      - everyone with these roles
 * Exactly one of recipientId / recipientIds / broadcastRoles is required.
 */

// The app calls this worker directly from the browser (Flutter web) with a
// custom Authorization header, which makes every request a CORS "preflight"
// one — the browser sends an OPTIONS request first and silently blocks the
// real POST if this worker doesn't answer it with the right headers. There's
// no cookie/credential involved (auth is the shared-secret header, checked
// below), so a wide-open '*' origin is fine here.
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
      });
    }

    try {
      // 1. Verify Shared Secret Key
      const authHeader = request.headers.get('Authorization') || '';
      const secret = authHeader.replace('Bearer ', '').trim();
      if (secret !== env.WORKER_SECRET) {
        return new Response(JSON.stringify({ error: 'Unauthorized request' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
        });
      }

      const body = await request.json();
      const { recipientId, recipientIds, broadcastRoles, title, messageText, conversationId, data } = body;

      if (!messageText) {
        return new Response(JSON.stringify({ error: 'Missing messageText' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
        });
      }
      if (!recipientId && !recipientIds && !broadcastRoles) {
        return new Response(JSON.stringify({ error: 'Provide recipientId, recipientIds, or broadcastRoles' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
        });
      }

      // 2. One OAuth2 token, scoped for both FCM sends and authenticated
      // Firestore REST reads — a service-account Bearer token reads
      // Firestore directly via Google Cloud IAM, bypassing security rules
      // the same way the Admin SDK does, so this works even though the
      // users collection requires isSignedIn() for normal client reads.
      const accessToken = await getGoogleOAuth2Token(
        env.FIREBASE_CLIENT_EMAIL,
        env.FIREBASE_PRIVATE_KEY,
      );
      const firestoreHeaders = { Authorization: `Bearer ${accessToken}` };

      // 3. Resolve the target uid(s) to FCM tokens.
      let uids;
      if (broadcastRoles) {
        uids = await queryUidsByRole(env.FIREBASE_PROJECT_ID, firestoreHeaders, broadcastRoles);
      } else {
        uids = recipientIds ?? [recipientId];
      }

      const tokens = (
        await Promise.all(uids.map((uid) => getFcmToken(env.FIREBASE_PROJECT_ID, firestoreHeaders, uid)))
      ).filter(Boolean);

      if (tokens.length === 0) {
        return new Response(JSON.stringify({ message: 'No registered FCM token(s) found for the given recipient(s)' }), {
          status: 200,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
        });
      }

      // 4. Send FCM Push Notification(s) via Google HTTP v1, in parallel.
      const results = await Promise.all(
        tokens.map((token) => sendFcm(env.FIREBASE_PROJECT_ID, accessToken, token, title, messageText, conversationId, data)),
      );

      return new Response(JSON.stringify({ success: true, sent: results.length, results }), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
      });

    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
      });
    }
  },
};

async function getFcmToken(projectId, firestoreHeaders, uid) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`,
    { headers: firestoreHeaders },
  );
  if (!res.ok) return null;
  const data = await res.json();
  return data.fields?.fcmToken?.stringValue ?? null;
}

async function queryUidsByRole(projectId, firestoreHeaders, roles) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
    {
      method: 'POST',
      headers: { ...firestoreHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'users' }],
          where: {
            fieldFilter: {
              field: { fieldPath: 'role' },
              op: 'IN',
              value: { arrayValue: { values: roles.map((r) => ({ stringValue: r })) } },
            },
          },
        },
      }),
    },
  );
  if (!res.ok) return [];
  const rows = await res.json();
  return rows
    .filter((row) => row.document)
    .map((row) => row.document.name.split('/').pop());
}

async function sendFcm(projectId, accessToken, token, title, messageText, conversationId, extraData) {
  const fcmPayload = {
    message: {
      token,
      notification: {
        title: title || 'Aqua Ops Message',
        body: messageText,
      },
      data: {
        ...(extraData ?? {}),
        ...(conversationId ? { conversationId } : {}),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
  };

  const fcmRes = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmPayload),
    },
  );
  return fcmRes.json();
}

// ── Native RS256 JWT & OAuth 2.0 Generator ───────────────────────────
async function getGoogleOAuth2Token(clientEmail, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  const strHeader = btoa(JSON.stringify(header));
  const strClaim = btoa(JSON.stringify(claim));
  const unsignedToken = `${strHeader}.${strClaim}`;

  const pem = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\\n/g, '')
    .replace(/\s+/g, '');

  const binaryDer = Uint8Array.from(atob(pem), c => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsignedToken)
  );

  const base64Signature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const signedJwt = `${unsignedToken}.${base64Signature}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedJwt}`,
  });

  const data = await res.json();
  return data.access_token;
}