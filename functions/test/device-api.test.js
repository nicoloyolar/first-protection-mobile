"use strict";

// Tests automatizados de la API local de dispositivo (docs/device-api-contract.md).
// Corren contra el servidor real (`startLocalServer`) en un puerto efimero.
// No requieren credenciales de Firebase: sin DEVICE_API_USE_FIREBASE=true
// (ni K_SERVICE/FUNCTIONS_EMULATOR), `getDb()` devuelve null y todo el
// estado vive en `memoryStore` — funciona igual con o sin `firebase-admin`
// instalado de verdad.
//
// Ejecutar con: npm test (ver package.json)

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  startLocalServer,
  memoryStore,
  signBody,
  DEFAULT_DEVICE_SECRET,
  buildHeartbeatMetadata,
  pickPendingCommand,
} = require("../index.js");

let server;
let baseUrl;

test.before(() => {
  server = startLocalServer(0);
  const { port } = server.address();
  baseUrl = `http://127.0.0.1:${port}`;
});

test.after(() => {
  server.close();
});

function nowSec() {
  return Math.floor(Date.now() / 1000);
}

/** Construye los headers de firma HMAC igual que lo haria el firmware real. */
function signedHeaders(deviceId, bodyText, { timestamp = nowSec(), secret = DEFAULT_DEVICE_SECRET } = {}) {
  return {
    "Content-Type": "application/json",
    "X-Device-Id": deviceId,
    "X-Device-Timestamp": String(timestamp),
    "X-Device-Signature": signBody(bodyText, timestamp, secret),
  };
}

function telemetryPayload(overrides = {}) {
  return {
    sequence: 1,
    timestamp: nowSec(),
    location: { lat: -36.82699, lng: -73.04977, speedKmh: 12 },
    power: { vehicleVoltage: 12.4 },
    ...overrides,
  };
}

async function postTelemetry(deviceId, payload) {
  const bodyText = JSON.stringify(payload);
  return fetch(`${baseUrl}/api/v1/devices/${deviceId}/telemetry`, {
    method: "POST",
    headers: signedHeaders(deviceId, bodyText),
    body: bodyText,
  });
}

test("OPTIONS responde 204 con headers CORS (preflight del panel/app)", async () => {
  const res = await fetch(`${baseUrl}/api/v1/devices/ANY/telemetry`, { method: "OPTIONS" });
  assert.equal(res.status, 204);
  assert.equal(res.headers.get("access-control-allow-origin"), "*");
});

test("ruta desconocida responde 404", async () => {
  const res = await fetch(`${baseUrl}/api/v1/devices`);
  assert.equal(res.status, 404);
});

test("telemetria: firma HMAC invalida se rechaza con 401", async () => {
  const deviceId = "TEST-SIG-BAD";
  const payload = telemetryPayload();
  const bodyText = JSON.stringify(payload);
  const res = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/telemetry`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Device-Id": deviceId,
      "X-Device-Timestamp": String(nowSec()),
      "X-Device-Signature": "0".repeat(64),
    },
    body: bodyText,
  });
  assert.equal(res.status, 401);
  assert.equal(memoryStore.devices.has(deviceId), false);
});

test("telemetria: timestamp fuera de la ventana de 5 minutos se rechaza con 401", async () => {
  const deviceId = "TEST-SIG-STALE";
  const payload = telemetryPayload();
  const bodyText = JSON.stringify(payload);
  const staleTimestamp = nowSec() - 600;
  const res = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/telemetry`, {
    method: "POST",
    headers: signedHeaders(deviceId, bodyText, { timestamp: staleTimestamp }),
    body: bodyText,
  });
  assert.equal(res.status, 401);
});

test("telemetria: firma valida pero deviceId del header distinto al de la URL se rechaza con 401", async () => {
  const deviceId = "TEST-SIG-MISMATCH";
  const payload = telemetryPayload();
  const bodyText = JSON.stringify(payload);
  const res = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/telemetry`, {
    method: "POST",
    headers: signedHeaders("OTRO-DEVICE", bodyText),
    body: bodyText,
  });
  assert.equal(res.status, 401);
});

test("telemetria: lat/lng fuera de rango se rechaza con 422", async () => {
  const res = await postTelemetry("TEST-RANGO-LATLNG", telemetryPayload({
    location: { lat: 999, lng: -73.04977 },
  }));
  assert.equal(res.status, 422);
});

test("telemetria: sin sequence se rechaza con 422", async () => {
  const payload = telemetryPayload();
  delete payload.sequence;
  const res = await postTelemetry("TEST-SIN-SEQ", payload);
  assert.equal(res.status, 422);
});

test("telemetria: velocidad fuera de rango se rechaza con 422", async () => {
  const res = await postTelemetry("TEST-RANGO-VEL", telemetryPayload({
    location: { lat: -36.8, lng: -73.0, speedKmh: 5000 },
  }));
  assert.equal(res.status, 422);
});

test("telemetria: voltaje fuera de rango se rechaza con 422", async () => {
  const res = await postTelemetry("TEST-RANGO-VOLT", telemetryPayload({
    power: { vehicleVoltage: -5 },
  }));
  assert.equal(res.status, 422);
});

test("telemetria: payload valido se acepta y actualiza memoryStore", async () => {
  const deviceId = "TEST-TELEMETRIA-OK";
  const res = await postTelemetry(deviceId, telemetryPayload());
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.ok, true);
  assert.equal(body.pendingCommands, 0);

  const device = memoryStore.devices.get(deviceId);
  assert.ok(device, "el dispositivo deberia quedar registrado en memoryStore");
  assert.equal(device.latitud, -36.82699);
  assert.equal(device.longitud, -73.04977);
  assert.equal(device.velocidad, 12);
});

test("telemetria: sequence repetido o menor se ignora sin pisar el estado mas nuevo", async () => {
  const deviceId = "TEST-SEQUENCE-DEDUP";

  await postTelemetry(deviceId, telemetryPayload({ sequence: 5, location: { lat: -36.8, lng: -73.0, speedKmh: 50 } }));
  assert.equal(memoryStore.devices.get(deviceId).velocidad, 50);

  // Reintento tardio con sequence menor y un payload distinto: no debe
  // sobreescribir el estado ya confirmado con sequence=5.
  const res = await postTelemetry(deviceId, telemetryPayload({ sequence: 3, location: { lat: -36.8, lng: -73.0, speedKmh: 5 } }));
  assert.equal(res.status, 200, "se responde ok igual, es idempotente para el dispositivo");
  assert.equal(memoryStore.devices.get(deviceId).velocidad, 50, "el payload duplicado/viejo no debe pisar el estado");
});

test("eventos: se acepta y se guarda en memoryStore con firma valida", async () => {
  const deviceId = "TEST-EVENTOS";
  const payload = { type: "panicButtonPressed", severity: "critical", timestamp: nowSec() };
  const bodyText = JSON.stringify(payload);

  const res = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/events`, {
    method: "POST",
    headers: signedHeaders(deviceId, bodyText),
    body: bodyText,
  });

  assert.equal(res.status, 200);
  const eventos = memoryStore.events.get(deviceId) || [];
  assert.equal(eventos.some((e) => e.type === "panicButtonPressed"), true);
});

test("comandos: ciclo completo crear -> next -> ack (executed) actualiza el actuador", async () => {
  const deviceId = "TEST-COMANDOS-CICLO";

  const createRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ target: "humo", value: true, requestedBy: "uid-admin", requestedByRole: "admin" }),
  });
  const created = await createRes.json();
  assert.equal(createRes.status, 201);
  assert.equal(created.command.status, "pending");

  const nextRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands/next`);
  const next = await nextRes.json();
  assert.equal(next.command.commandId, created.command.commandId);
  assert.equal(next.command.status, "received");

  // Un segundo poll no debe volver a entregar el mismo comando: ya no esta
  // "pending", esta "received".
  const nextAgainRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands/next`);
  const nextAgain = await nextAgainRes.json();
  assert.equal(nextAgain.command, null);

  const ackPayload = { status: "executed", result: { target: "humo", actuatorState: true } };
  const ackBodyText = JSON.stringify(ackPayload);
  const ackRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands/${created.command.commandId}/ack`, {
    method: "POST",
    headers: signedHeaders(deviceId, ackBodyText),
    body: ackBodyText,
  });
  assert.equal(ackRes.status, 200);

  const device = memoryStore.devices.get(deviceId);
  assert.equal(device.humo, true, "el ACK ejecutado es el unico camino que debe tocar el actuador");
});

test("comandos: un ACK 'failed' no toca el actuador", async () => {
  const deviceId = "TEST-COMANDOS-FAILED";

  const createRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ target: "cortaCorriente", value: true }),
  });
  const created = await createRes.json();

  const ackPayload = { status: "failed", errorCode: "HW_FAULT", message: "Rele no responde" };
  const ackBodyText = JSON.stringify(ackPayload);
  await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands/${created.command.commandId}/ack`, {
    method: "POST",
    headers: signedHeaders(deviceId, ackBodyText),
    body: ackBodyText,
  });

  const device = memoryStore.devices.get(deviceId) || {};
  assert.notEqual(device.cortaCorriente, true, "un ACK failed no debe activar el corte de corriente");
});

test("comandos: uno ya expirado no se entrega via next", async () => {
  const deviceId = "TEST-COMANDOS-EXPIRADO";

  const createRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ target: "sirena", value: true, ttlMs: -1000 }),
  });
  const created = await createRes.json();
  assert.equal(created.command.status, "pending");

  const nextRes = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands/next`);
  const next = await nextRes.json();
  assert.equal(next.command, null, "un comando ya expirado no debe entregarse al dispositivo");
});

async function createCommand(deviceId, payload) {
  return fetch(`${baseUrl}/api/v1/devices/${deviceId}/commands`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
}

test("comandos: target desconocido se rechaza con 422", async () => {
  const res = await createCommand("TEST-CMD-TARGET-INVALIDO", { target: "bocina", value: true });
  assert.equal(res.status, 422);
});

test("comandos: setActuator con target no-actuador (systemMode) se rechaza con 422", async () => {
  const res = await createCommand("TEST-CMD-TARGET-NO-ACTUADOR", { target: "systemMode", value: true });
  assert.equal(res.status, 422);
});

test("comandos: setActuator con value no booleano se rechaza con 422", async () => {
  const res = await createCommand("TEST-CMD-VALUE-INVALIDO", { target: "cortaCorriente", value: "si" });
  assert.equal(res.status, 422);
});

test("comandos: type desconocido se rechaza con 422", async () => {
  const res = await createCommand("TEST-CMD-TYPE-INVALIDO", { type: "borrarTodo", target: "humo", value: true });
  assert.equal(res.status, 422);
});

test("comandos: rate limit por dispositivo devuelve 429 al superar el limite en la ventana", async () => {
  const deviceId = "TEST-CMD-RATE-LIMIT";

  for (let i = 0; i < 5; i += 1) {
    const res = await createCommand(deviceId, { target: "humo", value: true });
    assert.equal(res.status, 201, `comando ${i + 1} deberia pasar, todavia bajo el limite`);
  }

  const sixthRes = await createCommand(deviceId, { target: "humo", value: true });
  assert.equal(sixthRes.status, 429);

  // Otro dispositivo no deberia verse afectado por el limite del anterior.
  const otherDeviceRes = await createCommand("TEST-CMD-RATE-LIMIT-OTRO", { target: "humo", value: true });
  assert.equal(otherDeviceRes.status, 201);
});

// Regresion real: el Admin SDK de Firebase rechaza cualquier `undefined`
// en un update() ("values argument contains undefined"). Se encontro
// probando el emulador de Functions contra la base de datos real —
// telemetria sin `power` o sin `location.speedKmh` (ambos opcionales en
// el contrato) rompia el guardado, algo que memoryStore nunca detecta
// porque no valida la forma de los datos como Firebase real.
test("buildHeartbeatMetadata: nunca deja valores undefined, con o sin power/speedKmh", () => {
  const soloSequence = buildHeartbeatMetadata({ sequence: 5, location: {} });
  assert.deepEqual(soloSequence, { sequence: 5 });
  assert.equal(Object.values(soloSequence).includes(undefined), false);

  const conSpeed = buildHeartbeatMetadata({
    sequence: 6,
    location: { speedKmh: 42 },
  });
  assert.deepEqual(conSpeed, { sequence: 6, speedKmh: 42 });

  const conVoltaje = buildHeartbeatMetadata({
    sequence: 7,
    location: {},
    power: { vehicleVoltage: 12.4 },
  });
  assert.deepEqual(conVoltaje, { sequence: 7, vehicleVoltage: 12.4 });

  const conAmbos = buildHeartbeatMetadata({
    sequence: 8,
    location: { speedKmh: 10 },
    power: { vehicleVoltage: 12.4 },
  });
  assert.deepEqual(conAmbos, {
    sequence: 8,
    speedKmh: 10,
    vehicleVoltage: 12.4,
  });
});

// Bug real encontrado el 2026-08-19 (ver docs/plan-de-trabajo.md): la app y
// el panel escriben los comandos DIRECTO en `device_commands/{deviceId}` via
// el SDK de Firebase, nunca a traves de POST /commands de este archivo.
// nextCommand/ackCommand antes solo leian de `memoryStore`, que jamas se
// entera de esas escrituras — en produccion, un comando creado por la app
// nunca le llegaba al dispositivo real. Estos tests cubren la funcion pura
// que reemplaza esa lectura (`pickPendingCommand`) contra la MISMA forma de
// datos que llega de Realtime Database (un objeto {commandId: value}, sin
// `commandId` embebido en el value — ver DeviceCommand.toMap() en Dart),
// sin necesitar un emulador de RTDB corriendo para probarlo.
test("pickPendingCommand: sin comandos (null o vacio) devuelve null", () => {
  assert.equal(pickPendingCommand(null, Date.now()), null);
  assert.equal(pickPendingCommand({}, Date.now()), null);
});

test("pickPendingCommand: encuentra un comando pendiente escrito directo en RTDB (sin campo commandId en el value)", () => {
  const now = Date.now();
  const commandsById = {
    cmdAbc: {
      type: "setActuator",
      target: "humo",
      value: true,
      status: "pending",
      requestedBy: "uid-cliente",
      requestedByRole: "client",
      createdAt: now,
      expiresAt: now + 60000,
    },
  };
  const result = pickPendingCommand(commandsById, now);
  assert.equal(result.commandId, "cmdAbc");
  assert.equal(result.target, "humo");
  assert.equal(result.status, "pending");
});

test("pickPendingCommand: ignora comandos ya no pendientes o expirados", () => {
  const now = Date.now();
  const commandsById = {
    cmdViejo: {
      status: "received",
      expiresAt: now + 60000,
      createdAt: now - 1000,
    },
    cmdExpirado: {
      status: "pending",
      expiresAt: now - 1000,
      createdAt: now - 2000,
    },
  };
  assert.equal(pickPendingCommand(commandsById, now), null);
});

test("pickPendingCommand: con varios pendientes, devuelve el mas antiguo (FIFO)", () => {
  const now = Date.now();
  const commandsById = {
    cmdNuevo: { status: "pending", expiresAt: now + 60000, createdAt: now },
    cmdViejo: { status: "pending", expiresAt: now + 60000, createdAt: now - 5000 },
  };
  const result = pickPendingCommand(commandsById, now);
  assert.equal(result.commandId, "cmdViejo");
});

test("DEVICE_API_SKIP_SIGNATURE=true permite saltar la firma (solo pensado para desarrollo local)", async () => {
  const deviceId = "TEST-SKIP-SIGNATURE";
  process.env.DEVICE_API_SKIP_SIGNATURE = "true";
  try {
    const payload = telemetryPayload();
    const res = await fetch(`${baseUrl}/api/v1/devices/${deviceId}/telemetry`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    assert.equal(res.status, 200);
  } finally {
    delete process.env.DEVICE_API_SKIP_SIGNATURE;
  }
});
