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
  async fetch(request, env, ctx) {
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

      // Cloudinary signed-upload request — a different request shape
      // sharing this same worker + shared-secret auth, so the Cloudinary
      // API secret needed to produce a valid signature never has to leave
      // the server (the client previously used an *unsigned* upload
      // preset, which anyone who extracted the cloud name/preset from the
      // compiled app could call directly, with no auth at all).
      if (body.cloudinarySign) {
        return handleCloudinarySign(body, env);
      }

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

      // 3. Resolve the target uid(s) to FCM tokens. Each uid may have
      // several tokens (one per device it's logged into) — keep uid
      // alongside each token so a bad one can be cleaned up afterward
      // without touching another device's registration.
      let uids;
      if (broadcastRoles) {
        uids = await queryUidsByRole(env.FIREBASE_PROJECT_ID, firestoreHeaders, broadcastRoles);
      } else {
        uids = recipientIds ?? [recipientId];
      }

      const perUidTokens = await Promise.all(
        uids.map(async (uid) => ({ uid, tokens: await getFcmTokens(env.FIREBASE_PROJECT_ID, firestoreHeaders, uid) })),
      );
      const pairs = perUidTokens.flatMap(({ uid, tokens }) => tokens.map((token) => ({ uid, token })));

      if (pairs.length === 0) {
        return new Response(JSON.stringify({ message: 'No registered FCM token(s) found for the given recipient(s)' }), {
          status: 200,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
        });
      }

      // 4. Send FCM Push Notification(s) via Google HTTP v1, in parallel, to
      // every device of every matched recipient.
      const results = await Promise.all(
        pairs.map(({ token }) => sendFcm(env.FIREBASE_PROJECT_ID, accessToken, token, title, messageText, conversationId, data)),
      );

      // 5. Best-effort cleanup — a device that's uninstalled the app or
      // whose token otherwise expired leaves a permanent dead entry
      // otherwise, since nothing else ever prunes it. Doesn't delay the
      // response; runs after it's already sent.
      const stale = pairs.filter((_, i) => isInvalidTokenError(results[i]));
      if (stale.length > 0) {
        const cleanup = Promise.all(
          stale.map(({ uid, token }) => removeFcmToken(env.FIREBASE_PROJECT_ID, firestoreHeaders, uid, token)),
        );
        if (ctx?.waitUntil) ctx.waitUntil(cleanup); else await cleanup;
      }

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

async function handleCloudinarySign(body, env) {
  const timestamp = Math.floor(Date.now() / 1000);
  const params = { timestamp };
  if (body.folder) params.folder = body.folder;

  // Cloudinary's signing rule: every param that will be sent with the
  // upload (except file/cloud_name/api_key/resource_type), sorted
  // alphabetically by key, joined as key=value with &, API secret appended,
  // then SHA-1 the whole string. Cloudinary recomputes this same thing
  // server-side and rejects the upload if it doesn't match.
  const toSign = `${Object.keys(params)
    .sort()
    .map((k) => `${k}=${params[k]}`)
    .join('&')}${env.CLOUDINARY_API_SECRET}`;

  const signature = await sha1Hex(toSign);

  return new Response(
    JSON.stringify({
      signature,
      timestamp,
      apiKey: env.CLOUDINARY_API_KEY,
      folder: body.folder ?? null,
    }),
    { status: 200, headers: { 'Content-Type': 'application/json', ...CORS_HEADERS } },
  );
}

async function sha1Hex(message) {
  const bytes = await crypto.subtle.digest('SHA-1', new TextEncoder().encode(message));
  return Array.from(new Uint8Array(bytes)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

function userDocUrl(projectId, uid) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`;
}

// Reads every token registered for this user (one per device) — falls back
// to the old single-token field too, so a user who hasn't re-logged-in since
// the fcmToken -> fcmTokens migration still gets notified on their one
// existing device.
async function getFcmTokens(projectId, firestoreHeaders, uid) {
  const res = await fetch(userDocUrl(projectId, uid), { headers: firestoreHeaders });
  if (!res.ok) return [];
  const data = await res.json();
  const multi = (data.fields?.fcmTokens?.arrayValue?.values ?? [])
    .map((v) => v.stringValue)
    .filter(Boolean);
  if (multi.length > 0) return multi;
  const legacy = data.fields?.fcmToken?.stringValue;
  return legacy ? [legacy] : [];
}

// FCM's HTTP v1 error shape for a token that's gone (app uninstalled, token
// rotated out, etc.) — safe to stop sending to it.
function isInvalidTokenError(fcmResult) {
  const status = fcmResult?.error?.status;
  const errorCode = fcmResult?.error?.details?.find((d) => d.errorCode)?.errorCode;
  return status === 'NOT_FOUND' || status === 'INVALID_ARGUMENT' || errorCode === 'UNREGISTERED';
}

async function removeFcmToken(projectId, firestoreHeaders, uid, badToken) {
  try {
    const url = userDocUrl(projectId, uid);
    const res = await fetch(url, { headers: firestoreHeaders });
    if (!res.ok) return;
    const data = await res.json();
    const remaining = (data.fields?.fcmTokens?.arrayValue?.values ?? [])
      .map((v) => v.stringValue)
      .filter((t) => t && t !== badToken);
    await fetch(`${url}?updateMask.fieldPaths=fcmTokens`, {
      method: 'PATCH',
      headers: { ...firestoreHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        fields: { fcmTokens: { arrayValue: { values: remaining.map((t) => ({ stringValue: t })) } } },
      }),
    });
  } catch (_) {
    // Best-effort — a missed cleanup just leaves one dead token behind.
  }
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