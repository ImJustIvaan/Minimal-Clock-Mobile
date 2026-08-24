// Verifies a Pro-unlock purchase server-to-server with Apple/Google before
// granting the entitlement — client-reported purchase state is never
// trusted alone, since it's trivially spoofable (e.g. a rooted/jailbroken
// device or a modified app binary could fake a "purchased" callback).
//
// Called from the app via SupabaseService.client.functions.invoke(
// 'verify-purchase', body: {...}), authenticated with the signed-in user's
// JWT (Supabase automatically forwards it as the Authorization header).
//
// Required secrets (set via `supabase secrets set`):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY  - auto-injected by Supabase
//   APPLE_APP_STORE_KEY_ID / APPLE_APP_STORE_ISSUER_ID / APPLE_APP_STORE_PRIVATE_KEY
//     - App Store Connect API key for the App Store Server API
//   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
//     - service account JSON (as a string) with access to the Play Console,
//       used to call the Google Play Developer API

import { createClient } from "npm:@supabase/supabase-js@2";

const PRO_PRODUCT_ID = "pro_unlock";

interface VerifyRequest {
  platform: "ios" | "android";
  productId: string;
  // iOS: a signed transaction (StoreKit2 JWS) or classic base64 receipt.
  // Android: the purchase token from Play Billing.
  token: string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Client the user is authenticated as, only used to resolve who's calling.
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Not authenticated" }), { status: 401 });
  }
  const userId = userData.user.id;

  let body: VerifyRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), { status: 400 });
  }

  if (body.productId !== PRO_PRODUCT_ID) {
    return new Response(JSON.stringify({ error: "Unknown product" }), { status: 400 });
  }

  let verified: boolean;
  try {
    verified = body.platform === "ios"
      ? await verifyAppleReceipt(body.token)
      : await verifyGooglePurchase(body.productId, body.token);
  } catch (err) {
    console.error("Receipt verification failed:", err);
    return new Response(JSON.stringify({ error: "Verification failed" }), { status: 502 });
  }

  if (!verified) {
    return new Response(JSON.stringify({ error: "Purchase could not be verified" }), {
      status: 402,
    });
  }

  // Service-role client bypasses RLS — this is the only writer of this table.
  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const { error: upsertError } = await adminClient
    .from("entitlements")
    .upsert({
      user_id: userId,
      is_pro: true,
      pro_source: body.platform,
      pro_purchased_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

  if (upsertError) {
    console.error("Failed to record entitlement:", upsertError);
    return new Response(JSON.stringify({ error: "Failed to record entitlement" }), {
      status: 500,
    });
  }

  return new Response(JSON.stringify({ is_pro: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});

/// Verifies a StoreKit purchase using the App Store Server API. Signs a
/// short-lived JWT with the App Store Connect API key (ES256, per Apple's
/// spec) and calls the transaction-info endpoint.
async function verifyAppleReceipt(signedTransaction: string): Promise<boolean> {
  const keyId = Deno.env.get("APPLE_APP_STORE_KEY_ID");
  const issuerId = Deno.env.get("APPLE_APP_STORE_ISSUER_ID");
  const privateKey = Deno.env.get("APPLE_APP_STORE_PRIVATE_KEY");
  if (!keyId || !issuerId || !privateKey) {
    throw new Error("Apple App Store Server API credentials not configured");
  }

  // The client sends the StoreKit2 signed transaction (JWS) directly; its
  // payload already carries the verified transaction details once we check
  // Apple's signature. Simplest robust approach: ask Apple's own
  // transaction-info endpoint to re-verify it by transaction id, rather
  // than re-implementing JWS signature verification here.
  const transactionId = decodeJwsPayload(signedTransaction)?.transactionId;
  if (!transactionId) return false;

  const jwt = await signAppleJwt(keyId, issuerId, privateKey);
  const resp = await fetch(
    `https://api.storekit.itunes.apple.com/inApps/v1/transactions/${transactionId}`,
    { headers: { Authorization: `Bearer ${jwt}` } },
  );
  if (!resp.ok) return false;
  const data = await resp.json();
  const transactionInfo = decodeJwsPayload(data.signedTransactionInfo);
  return transactionInfo?.productId === PRO_PRODUCT_ID && !transactionInfo?.revocationDate;
}

function decodeJwsPayload(jws: string): Record<string, unknown> | null {
  try {
    const [, payload] = jws.split(".");
    return JSON.parse(atob(payload.replace(/-/g, "+").replace(/_/g, "/")));
  } catch {
    return null;
  }
}

async function signAppleJwt(keyId: string, issuerId: string, privateKeyPem: string): Promise<string> {
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: issuerId,
    iat: now,
    exp: now + 300,
    aud: "appstoreconnect-v1",
  };

  const b64url = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const signingInput = `${b64url(header)}.${b64url(payload)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  return `${signingInput}.${sigB64}`;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

/// Verifies a Google Play purchase token via the Play Developer API,
/// authenticating with a service-account JSON key (OAuth2 JWT bearer flow).
async function verifyGooglePurchase(productId: string, purchaseToken: string): Promise<boolean> {
  const serviceAccountJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME") ?? "com.ImJustIvaan.MimClock";
  if (!serviceAccountJson) {
    throw new Error("Google Play service account not configured");
  }
  const serviceAccount = JSON.parse(serviceAccountJson);

  const accessToken = await getGoogleAccessToken(serviceAccount);
  const resp = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (!resp.ok) return false;
  const data = await resp.json();
  // purchaseState: 0 = purchased, 1 = canceled, 2 = pending.
  return data.purchaseState === 0;
}

async function getGoogleAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const b64url = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const signingInput = `${b64url(header)}.${b64url(claims)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(signingInput));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const assertion = `${signingInput}.${sigB64}`;

  const tokenResp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const tokenData = await tokenResp.json();
  return tokenData.access_token;
}
