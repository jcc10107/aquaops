/**
 * Aqua Ops — Free FCM Push Notification Worker
 * Runs natively in Cloudflare Workers using WebCrypto RS256
 */

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    try {
      // 1. Verify Shared Secret Key
      const authHeader = request.headers.get('Authorization') || '';
      const secret = authHeader.replace('Bearer ', '').trim();
      if (secret !== env.WORKER_SECRET) {
        return new Response(JSON.stringify({ error: 'Unauthorized request' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const body = await request.json();
      const { recipientId, title, messageText, conversationId } = body;

      if (!recipientId || !messageText) {
        return new Response(JSON.stringify({ error: 'Missing recipientId or messageText' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // 2. Query recipient's FCM token from Firestore REST API
      const tokenUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${recipientId}`;
      const userRes = await fetch(tokenUrl);
      if (!userRes.ok) {
        return new Response(JSON.stringify({ error: 'User record not found in Firestore' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const userData = await userRes.json();
      const fcmToken = userData.fields?.fcmToken?.stringValue;

      if (!fcmToken) {
        return new Response(JSON.stringify({ message: 'No registered FCM token found for user' }), {
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // 3. Obtain Google OAuth2 Access Token
      const accessToken = await getGoogleOAuth2Token(
        env.FIREBASE_CLIENT_EMAIL,
        env.FIREBASE_PRIVATE_KEY
      );

      // 4. Send FCM Push Notification via Google HTTP v1
      const fcmPayload = {
        message: {
          token: fcmToken,
          notification: {
            title: title || 'Aqua Ops Message',
            body: messageText,
          },
          data: {
            conversationId: conversationId || '',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      const fcmResult = await fcmRes.json();

      return new Response(JSON.stringify({ success: true, result: fcmResult }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });

    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  },
};

// ── Native RS256 JWT & OAuth 2.0 Generator ───────────────────────────
async function getGoogleOAuth2Token(clientEmail, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
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