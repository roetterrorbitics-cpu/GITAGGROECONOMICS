import crypto from "node:crypto";

function decodePayload(jws) {
  const parts = String(jws || "").split(".");
  if (parts.length !== 3) throw new Error("Invalid Apple transaction JWS.");
  return JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
}

function base64url(value) {
  return Buffer.from(value).toString("base64url");
}

function derToJose(signature) {
  let offset = 0;
  if (signature[offset++] !== 0x30) throw new Error("Invalid DER signature.");
  let sequenceLength = signature[offset++];
  if (sequenceLength & 0x80) {
    const count = sequenceLength & 0x7f;
    offset += count;
  }

  if (signature[offset++] !== 0x02) throw new Error("Invalid DER signature.");
  let rLength = signature[offset++];
  let r = signature.subarray(offset, offset + rLength);
  offset += rLength;

  if (signature[offset++] !== 0x02) throw new Error("Invalid DER signature.");
  let sLength = signature[offset++];
  let s = signature.subarray(offset, offset + sLength);

  while (r.length > 32 && r[0] === 0) r = r.subarray(1);
  while (s.length > 32 && s[0] === 0) s = s.subarray(1);
  if (r.length < 32) r = Buffer.concat([Buffer.alloc(32 - r.length), r]);
  if (s.length < 32) s = Buffer.concat([Buffer.alloc(32 - s.length), s]);

  return Buffer.concat([r, s]);
}

function appStoreJWT() {
  const privateKey = process.env.APPLE_API_PRIVATE_KEY;
  const keyId = process.env.APPLE_API_KEY_ID;
  const issuerId = process.env.APPLE_ISSUER_ID;
  const bundleId = process.env.APPLE_BUNDLE_ID || "com.roetterrorbitics.Rendert";

  if (!privateKey || !keyId || !issuerId) {
    throw new Error("Apple App Store Server API credentials are not configured.");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const payload = {
    iss: issuerId,
    iat: now,
    exp: now + 300,
    aud: "appstoreconnect-v1",
    bid: bundleId
  };

  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const input = encodedHeader + "." + encodedPayload;

  const signer = crypto.createSign("SHA256");
  signer.update(input);
  signer.end();

  return input + "." + base64url(derToJose(signer.sign(privateKey)));
}

async function getAppleTransaction(transactionId, environment) {
  const host = environment === "Sandbox"
    ? "https://api.storekit-sandbox.apple.com"
    : "https://api.storekit.apple.com";

  const response = await fetch(
    host + "/inApps/v1/transactions/" + encodeURIComponent(transactionId),
    {
      headers: {
        Authorization: "Bearer " + appStoreJWT(),
        Accept: "application/json"
      }
    }
  );

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.errorMessage || "Apple transaction lookup failed.");
  }
  return data;
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ message: "Method not allowed" });
  }

  const bearer = String(req.headers.authorization || "");
  const accessToken = bearer.startsWith("Bearer ") ? bearer.slice(7) : "";
  if (!accessToken) return res.status(401).json({ message: "Authentication required" });

  const supabaseUrl = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  const serviceRole = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const bundleId = process.env.APPLE_BUNDLE_ID || "com.roetterrorbitics.Rendert";

  if (!supabaseUrl || !anonKey || !serviceRole) {
    return res.status(500).json({ message: "Supabase server environment is incomplete." });
  }

  try {
    const authResponse = await fetch(supabaseUrl.replace(/\/$/, "") + "/auth/v1/user", {
      headers: {
        apikey: anonKey,
        Authorization: "Bearer " + accessToken
      }
    });
    if (!authResponse.ok) return res.status(401).json({ message: "Invalid session" });

    const user = await authResponse.json();
    const transactionJWS = req.body?.transactionJWS;
    const requestedProductID = req.body?.productID;

    const clientPayload = decodePayload(transactionJWS);
    if (!clientPayload.transactionId) {
      return res.status(400).json({ message: "Missing Apple transaction ID." });
    }

    const apple = await getAppleTransaction(clientPayload.transactionId, clientPayload.environment || "Production");
    const transaction = decodePayload(apple.signedTransactionInfo);

    if (transaction.bundleId !== bundleId) {
      return res.status(400).json({ message: "Apple bundle ID does not match this app." });
    }
    if (transaction.transactionId !== clientPayload.transactionId) {
      return res.status(400).json({ message: "Apple transaction mismatch." });
    }

    const creatorProduct = process.env.APPLE_PRODUCT_ID_CREATOR || "com.roetterrorbitics.rendert.creator";
    const proProduct = process.env.APPLE_PRODUCT_ID_PRO || "com.roetterrorbitics.rendert.pro";
    const planByProduct = {
      [creatorProduct]: "creator",
      [proProduct]: "pro"
    };
    const plan = planByProduct[transaction.productId];

    if (!plan || (requestedProductID && requestedProductID !== transaction.productId)) {
      return res.status(400).json({ message: "Unknown Apple subscription product." });
    }

    const record = {
      user_id: user.id,
      plan,
      provider: "apple",
      provider_subscription_id: transaction.transactionId,
      provider_transaction_id: transaction.transactionId,
      original_transaction_id: transaction.originalTransactionId || transaction.transactionId,
      status: "active",
      expires_at: transaction.expiresDate ? new Date(transaction.expiresDate).toISOString() : null,
      source_metadata: {
        environment: transaction.environment || clientPayload.environment || "Production",
        product_id: transaction.productId,
        transaction_type: transaction.type || null,
        purchase_date: transaction.purchaseDate || null
      },
      updated_at: new Date().toISOString()
    };

    const endpoint =
      supabaseUrl.replace(/\/$/, "") +
      "/rest/v1/subscriptions?on_conflict=original_transaction_id";

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        apikey: serviceRole,
        Authorization: "Bearer " + serviceRole,
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=representation"
      },
      body: JSON.stringify(record)
    });

    if (!response.ok) {
      throw new Error("Subscription persistence failed: " + await response.text());
    }

    return res.status(200).json({
      plan,
      productID: transaction.productId,
      transactionId: transaction.transactionId,
      originalTransactionId: transaction.originalTransactionId || transaction.transactionId,
      expiresDate: transaction.expiresDate || null
    });
  } catch (error) {
    return res.status(400).json({
      message: error instanceof Error ? error.message : "Apple subscription sync failed."
    });
  }
}
