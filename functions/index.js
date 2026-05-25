"use strict";

const crypto = require("crypto");
const http = require("http");

let functions = null;
let admin = null;

try {
  functions = require("firebase-functions");
  admin = require("firebase-admin");
} catch (error) {
  // Local smoke tests can run without loading Firebase tooling.
}

const DEFAULT_DEVICE_SECRET = process.env.DEVICE_SIM_SECRET || "dev-secret";
const DEFAULT_PORT = Number(process.env.PORT || 5001);
const COMMAND_TTL_MS = 60 * 1000;

const memoryStore = {
  devices: new Map(),
  telemetry: new Map(),
  events: new Map(),
  commands: new Map(),
};

function nowMs() {
  return Date.now();
}

function nowSec() {
  return Math.floor(Date.now() / 1000);
}

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
      if (raw.length > 1024 * 1024) {
        reject(new Error("Payload too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve({
          body: JSON.parse(raw),
          rawBodyText: raw,
        });
      } catch (error) {
        reject(new Error("Invalid JSON body"));
      }
    });
    req.on("error", reject);
  });
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "Content-Type, X-Device-Id, X-Device-Timestamp, X-Device-Signature",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  });
  res.end(JSON.stringify(payload));
}

function normalizePath(pathname) {
  const apiIndex = pathname.indexOf("/api/v1/");
  return apiIndex >= 0 ? pathname.slice(apiIndex) : pathname;
}

function routeFor(req) {
  const url = new URL(req.url, "http://localhost");
  const path = normalizePath(url.pathname);
  const parts = path.split("/").filter(Boolean);

  if (parts[0] !== "api" || parts[1] !== "v1" || parts[2] !== "devices") {
    return null;
  }

  const deviceId = parts[3];
  const resource = parts[4];
  return {
    deviceId,
    resource,
    commandId: resource === "commands" ? parts[5] : null,
    commandAction: resource === "commands" ? parts[6] : null,
  };
}

function timingSafeEqual(a, b) {
  const left = Buffer.from(a || "", "hex");
  const right = Buffer.from(b || "", "hex");
  if (left.length !== right.length) return false;
  return crypto.timingSafeEqual(left, right);
}

function signBody(bodyText, timestamp, secret) {
  return crypto
    .createHmac("sha256", secret)
    .update(bodyText)
    .update(String(timestamp))
    .digest("hex");
}

function validateDeviceRequest(req, rawBodyText, deviceId) {
  if (process.env.DEVICE_API_SKIP_SIGNATURE === "true") return null;

  const headerDeviceId = req.headers["x-device-id"];
  const timestamp = req.headers["x-device-timestamp"];
  const signature = req.headers["x-device-signature"];

  if (!headerDeviceId || headerDeviceId !== deviceId) {
    return "Invalid X-Device-Id";
  }
  if (!timestamp || Math.abs(nowSec() - Number(timestamp)) > 300) {
    return "Invalid or expired X-Device-Timestamp";
  }
  if (!signature) {
    return "Missing X-Device-Signature";
  }

  const expected = signBody(rawBodyText || "{}", timestamp, DEFAULT_DEVICE_SECRET);
  if (!timingSafeEqual(signature, expected)) {
    return "Invalid X-Device-Signature";
  }

  return null;
}

function validateTelemetry(payload) {
  const location = payload.location || {};
  const lat = Number(location.lat);
  const lng = Number(location.lng);

  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    return "location.lat out of range";
  }
  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    return "location.lng out of range";
  }
  if (!Number.isFinite(Number(payload.sequence))) {
    return "sequence is required";
  }
  return null;
}

function compatibilityDeviceState(deviceId, telemetry) {
  const location = telemetry.location || {};
  const power = telemetry.power || {};
  const signals = telemetry.signals || {};
  const actuators = telemetry.actuators || {};
  const network = telemetry.network || {};

  return {
    id: deviceId,
    lastSeenAt: nowMs(),
    connectionState: network.online === false ? "offline" : "online",
    location,
    power,
    signals,
    actuators,
    firmwareVersion: telemetry.firmwareVersion || "",
    hardwareVersion: telemetry.hardwareVersion || "",
    latitud: Number(location.lat || 0),
    longitud: Number(location.lng || 0),
    velocidad: Number(location.speedKmh || 0),
    voltaje: Number(power.vehicleVoltage || 0),
    humo: actuators.humo === true,
    sirenaActiva: actuators.sirena === true,
    cortaCorriente: actuators.cortaCorriente === true,
    protocoloActivo: signals.panicButton === true,
    ultimaActualizacion: telemetry.timestamp || nowSec(),
  };
}

function pushToMapList(map, key, value) {
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(value);
}

function getCommandQueue(deviceId) {
  if (!memoryStore.commands.has(deviceId)) {
    memoryStore.commands.set(deviceId, []);
  }
  return memoryStore.commands.get(deviceId);
}

async function getDb() {
  const shouldUseFirebase =
    process.env.DEVICE_API_USE_FIREBASE === "true" ||
    process.env.K_SERVICE ||
    process.env.FUNCTIONS_EMULATOR === "true";

  if (!shouldUseFirebase) return null;
  if (!admin) return null;
  if (!admin.apps.length) admin.initializeApp();
  return admin.database();
}

async function saveTelemetry(deviceId, telemetry) {
  const state = compatibilityDeviceState(deviceId, telemetry);
  memoryStore.devices.set(deviceId, state);
  pushToMapList(memoryStore.telemetry, deviceId, telemetry);

  const db = await getDb();
  if (!db) return;

  const sequence = String(telemetry.sequence);
  await db.ref().update({
    [`dispositivos/${deviceId}`]: state,
    [`device_telemetry/${deviceId}/${sequence}`]: telemetry,
    [`device_events/${deviceId}/${Date.now()}`]: {
      type: "heartbeat",
      severity: "info",
      timestamp: telemetry.timestamp || nowSec(),
      location: telemetry.location || null,
      metadata: {
        sequence: telemetry.sequence,
        speedKmh: telemetry.location && telemetry.location.speedKmh,
        vehicleVoltage: telemetry.power && telemetry.power.vehicleVoltage,
      },
    },
  });
}

async function saveEvent(deviceId, event) {
  pushToMapList(memoryStore.events, deviceId, event);

  const db = await getDb();
  if (!db) return;
  await db.ref(`device_events/${deviceId}`).push(event);
}

async function createCommand(deviceId, payload) {
  const command = {
    commandId: `cmd_${Date.now()}_${Math.floor(Math.random() * 10000)}`,
    type: payload.type || "setActuator",
    target: payload.target,
    value: payload.value,
    status: "pending",
    requestedBy: payload.requestedBy || "local-dev",
    requestedByRole: payload.requestedByRole || "admin",
    createdAt: nowMs(),
    expiresAt: nowMs() + Number(payload.ttlMs || COMMAND_TTL_MS),
  };

  getCommandQueue(deviceId).push(command);

  const db = await getDb();
  if (db) {
    await db.ref(`device_commands/${deviceId}/${command.commandId}`).set(command);
  }

  return command;
}

async function nextCommand(deviceId) {
  const queue = getCommandQueue(deviceId);
  const command = queue.find(
    (item) => item.status === "pending" && item.expiresAt > nowMs(),
  );
  if (!command) return null;

  command.status = "received";
  command.receivedAt = nowMs();

  const db = await getDb();
  if (db) {
    await db.ref(`device_commands/${deviceId}/${command.commandId}`).update({
      status: "received",
      receivedAt: command.receivedAt,
    });
  }

  return command;
}

async function ackCommand(deviceId, commandId, ack) {
  const queue = getCommandQueue(deviceId);
  const command = queue.find((item) => item.commandId === commandId);
  if (command) {
    command.status = ack.status;
    command.executedAt = ack.executedAt || nowSec();
    command.result = ack.result || {};
    command.errorCode = ack.errorCode || null;
    command.message = ack.message || "";
  }

  const event = {
    type: "commandAck",
    severity: ack.status === "executed" ? "info" : "warning",
    timestamp: ack.executedAt || nowSec(),
    metadata: {
      commandId,
      status: ack.status,
      result: ack.result || {},
      errorCode: ack.errorCode || null,
      message: ack.message || "",
    },
  };
  pushToMapList(memoryStore.events, deviceId, event);

  const db = await getDb();
  if (db) {
    await db.ref().update({
      [`device_commands/${deviceId}/${commandId}`]: command || ack,
      [`device_events/${deviceId}/${Date.now()}`]: event,
    });
  }

  return command || { commandId, ...ack };
}

async function handleApiRequest(req, res) {
  if (req.method === "OPTIONS") {
    sendJson(res, 204, {});
    return;
  }

  const route = routeFor(req);
  if (!route || !route.deviceId) {
    sendJson(res, 404, { ok: false, error: "Route not found" });
    return;
  }

  let body = {};
  let rawBodyText = "{}";
  if (req.method !== "GET") {
    try {
      const parsed = await parseJsonBody(req);
      body = parsed.body;
      rawBodyText = parsed.rawBodyText;
    } catch (error) {
      sendJson(res, 400, { ok: false, error: error.message });
      return;
    }
  }

  const signatureError = validateDeviceRequest(req, rawBodyText, route.deviceId);
  const isDeviceWrite =
    route.resource === "telemetry" ||
    route.resource === "events" ||
    route.commandAction === "ack";
  if (isDeviceWrite && signatureError) {
    sendJson(res, 401, { ok: false, error: signatureError });
    return;
  }

  try {
    if (req.method === "POST" && route.resource === "telemetry") {
      const validationError = validateTelemetry(body);
      if (validationError) {
        sendJson(res, 422, { ok: false, error: validationError });
        return;
      }
      await saveTelemetry(route.deviceId, body);
      sendJson(res, 200, {
        ok: true,
        serverTime: nowSec(),
        pendingCommands: getCommandQueue(route.deviceId).filter(
          (command) => command.status === "pending",
        ).length,
      });
      return;
    }

    if (req.method === "POST" && route.resource === "events") {
      await saveEvent(route.deviceId, body);
      sendJson(res, 200, { ok: true, serverTime: nowSec() });
      return;
    }

    if (
      req.method === "GET" &&
      route.resource === "commands" &&
      route.commandId === "next"
    ) {
      sendJson(res, 200, { ok: true, command: await nextCommand(route.deviceId) });
      return;
    }

    if (
      req.method === "POST" &&
      route.resource === "commands" &&
      route.commandId &&
      route.commandAction === "ack"
    ) {
      const command = await ackCommand(route.deviceId, route.commandId, body);
      sendJson(res, 200, { ok: true, command });
      return;
    }

    if (req.method === "POST" && route.resource === "commands" && !route.commandId) {
      const command = await createCommand(route.deviceId, body);
      sendJson(res, 201, { ok: true, command });
      return;
    }

    sendJson(res, 404, { ok: false, error: "Route not found" });
  } catch (error) {
    sendJson(res, 500, { ok: false, error: error.message });
  }
}

function startLocalServer(port = DEFAULT_PORT) {
  const server = http.createServer(handleApiRequest);
  server.listen(port, () => {
    console.log(`First Protection device API listening on http://localhost:${port}`);
  });
  return server;
}

async function smokeTest() {
  const req = {
    method: "POST",
    url: "/api/v1/devices/GPS-SMOKE/telemetry",
    headers: {
      "x-device-id": "GPS-SMOKE",
      "x-device-timestamp": String(nowSec()),
      "x-device-signature": "skip",
    },
    on() {},
  };
  const telemetry = {
    sequence: 1,
    timestamp: nowSec(),
    location: { lat: -36.82, lng: -73.04, speedKmh: 12 },
  };
  await saveTelemetry("GPS-SMOKE", telemetry);
  if (!memoryStore.devices.has("GPS-SMOKE")) {
    throw new Error("Smoke test failed");
  }
  console.log("Smoke test OK", req.url);
}

if (functions && admin) {
  exports.deviceApi = functions.https.onRequest(handleApiRequest);
}

if (require.main === module) {
  if (process.argv.includes("--smoke-test")) {
    smokeTest().catch((error) => {
      console.error(error);
      process.exit(1);
    });
  } else {
    startLocalServer();
  }
}

module.exports = {
  handleApiRequest,
  startLocalServer,
  memoryStore,
};
