"use strict";

// Test de humo end-to-end contra el wrapper REAL de Cloud Functions
// (`exports.deviceApi`), no contra `handleApiRequest`/`startLocalServer`
// directo como el resto de la suite en device-api.test.js.
//
// Pendiente documentado en docs/plan-de-trabajo.md: "Los tests automatizados
// de la API prueban `handleApiRequest` directo, nunca el wrapper real de
// Cloud Functions (`exports.deviceApi`)... sería valioso un test de humo
// contra `firebase emulators:start --only functions` automatizado en CI, no
// solo manual". Este script es justamente eso.
//
// Requiere el emulador de Functions corriendo (puerto fijado en
// firebase.json). Pensado para ejecutarse via:
//   firebase emulators:exec --project demo-first-protection --only functions \
//     "node test/emulator-smoke.js"
// (ver .github/workflows/ci.yml, job `functions-emulator-smoke`).
//
// No requiere credenciales reales de Firebase: un projectId con prefijo
// "demo-" hace que el emulador corra en modo offline/sin auth.

const assert = require("node:assert/strict");
const { signBody, DEFAULT_DEVICE_SECRET } = require("../index.js");

const PROJECT_ID = process.env.GCLOUD_PROJECT || "demo-first-protection";
const REGION = "us-central1";
const PORT = process.env.FUNCTIONS_EMULATOR_PORT || 5001;
const BASE_URL = `http://127.0.0.1:${PORT}/${PROJECT_ID}/${REGION}/deviceApi`;

function nowSec() {
  return Math.floor(Date.now() / 1000);
}

function signedHeaders(deviceId, bodyText, timestamp = nowSec()) {
  return {
    "Content-Type": "application/json",
    "X-Device-Id": deviceId,
    "X-Device-Timestamp": String(timestamp),
    "X-Device-Signature": signBody(bodyText, timestamp, DEFAULT_DEVICE_SECRET),
  };
}

async function waitForEmulator(maxAttempts = 30) {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      const res = await fetch(`${BASE_URL}/api/v1/devices/PING/telemetry`, { method: "OPTIONS" });
      if (res.status === 204) return;
    } catch (error) {
      // El emulador todavia no levanta el puerto, reintentar.
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`Functions emulator no respondio en ${BASE_URL} tras ${maxAttempts}s`);
}

async function main() {
  await waitForEmulator();

  const deviceId = "GPS-CI-SMOKE";

  // 1. Telemetria valida a traves del wrapper real (exports.deviceApi).
  const telemetry = {
    sequence: 1,
    timestamp: nowSec(),
    location: { lat: -36.82699, lng: -73.04977, speedKmh: 12 },
    power: { vehicleVoltage: 12.4 },
  };
  const telemetryBody = JSON.stringify(telemetry);
  const telemetryRes = await fetch(`${BASE_URL}/api/v1/devices/${deviceId}/telemetry`, {
    method: "POST",
    headers: signedHeaders(deviceId, telemetryBody),
    body: telemetryBody,
  });
  assert.equal(
    telemetryRes.status,
    200,
    `telemetria deberia responder 200, respondio ${telemetryRes.status}`,
  );
  const telemetryJson = await telemetryRes.json();
  assert.equal(telemetryJson.ok, true);

  // 2. Firma invalida debe seguir rechazandose contra el wrapper real (no
  // solo contra handleApiRequest en memoria, que es lo que ya cubre
  // device-api.test.js).
  const badRes = await fetch(`${BASE_URL}/api/v1/devices/${deviceId}/telemetry`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Device-Id": deviceId,
      "X-Device-Timestamp": String(nowSec()),
      "X-Device-Signature": "0".repeat(64),
    },
    body: telemetryBody,
  });
  assert.equal(badRes.status, 401);

  // 3. Ciclo de comando completo: crear -> next -> ack, tambien contra el
  // wrapper real. La creacion y el poll de "next" no requieren firma (los
  // hace la app/panel, no el dispositivo) — ver isDeviceWrite en index.js.
  const createBody = JSON.stringify({
    target: "humo",
    value: true,
    requestedBy: "ci-emulator-smoke",
    requestedByRole: "admin",
  });
  const createRes = await fetch(`${BASE_URL}/api/v1/devices/${deviceId}/commands`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: createBody,
  });
  assert.equal(
    createRes.status,
    201,
    `crear comando deberia responder 201, respondio ${createRes.status}`,
  );
  const created = await createRes.json();
  assert.equal(created.command.status, "pending");
  const commandId = created.command.commandId;
  assert.ok(commandId, "la respuesta deberia incluir commandId");

  const nextRes = await fetch(`${BASE_URL}/api/v1/devices/${deviceId}/commands/next`);
  assert.equal(nextRes.status, 200);
  const next = await nextRes.json();
  assert.equal(next.command.commandId, commandId);
  assert.equal(next.command.status, "received");

  const ackBody = JSON.stringify({ status: "executed", result: { target: "humo", actuatorState: true } });
  const ackRes = await fetch(`${BASE_URL}/api/v1/devices/${deviceId}/commands/${commandId}/ack`, {
    method: "POST",
    headers: signedHeaders(deviceId, ackBody),
    body: ackBody,
  });
  assert.equal(ackRes.status, 200);
  const acked = await ackRes.json();
  assert.equal(acked.command.status, "executed");

  console.log(
    "Emulator smoke test OK -- exports.deviceApi (wrapper real de Cloud Functions) responde correctamente end-to-end.",
  );
}

main().catch((error) => {
  console.error("Emulator smoke test FALLO:", error);
  process.exit(1);
});
