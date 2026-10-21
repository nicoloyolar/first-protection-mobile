#include "device.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "display.h"
#include "gps.h"
#include "stm32f4xx_hal.h"

/* Cada componente del sistema se simula con un LED en los headers Arduino.
 * D2/D8 (USART1) son del GPS; el modem A7670 ira en USART6. */
#define LED_STATUS_PORT GPIOA /* LD2, en la placa */
#define LED_STATUS_PIN GPIO_PIN_5
#define LED_CORTE_PORT GPIOB /* D3 */
#define LED_CORTE_PIN GPIO_PIN_3
#define LED_SIRENA_PORT GPIOB /* D4 */
#define LED_SIRENA_PIN GPIO_PIN_5
#define LED_HUMO_PORT GPIOB /* D5 */
#define LED_HUMO_PIN GPIO_PIN_4
#define LED_PROTOCOLO_PORT GPIOB /* D6 */
#define LED_PROTOCOLO_PIN GPIO_PIN_10
#define LED_ARMADO_PORT GPIOA /* D7 */
#define LED_ARMADO_PIN GPIO_PIN_8

#define BUTTON_PORT GPIOC /* B1 hace de boton oculto bajo el volante, activo en bajo */
#define BUTTON_PIN GPIO_PIN_13
#define IGNITION_PORT GPIOC /* D9: ignicion/ACC simulada, cable a GND = contacto */
#define IGNITION_PIN GPIO_PIN_7

#define TELEMETRY_PERIOD_MS 5000
#define STATUS_BLINK_MS 500
#define SIRENA_BLINK_MS 125
#define DEBOUNCE_MS 30
#define LONG_PRESS_MS 2000
#define RECENT_COMMANDS 8
#define FIELD_MAX 48
#define DISPLAY_REFRESH_MS 500
#define COMMAND_HIGHLIGHT_MS 3000

/* Mismo umbral que vehiculo_controller.dart. Se deja de considerar en movimiento
 * bajo 3 km/h para que el ruido del GPS cerca del umbral no lo haga oscilar. */
#define MOVING_START_KMH 5.0f
#define MOVING_STOP_KMH 3.0f

/* Ubicacion de prueba mientras el GPS no haya tenido fix nunca (la del simulador). */
#define DEFAULT_LAT -36.82699
#define DEFAULT_LNG -73.04977

typedef struct {
    bool humo;
    bool sirena;
    bool cortaCorriente;
    bool protocoloActivo;
    bool armed;
    bool ignition;
    bool movement;
    bool panicButton; /* se reporta en la siguiente telemetria y se limpia */
    uint32_t sequence;
} DeviceState;

typedef struct {
    const char *status;
    const char *errorCode;
    char message[64];
} CommandResult;

static DeviceState state;

static uint32_t lastTelemetryMs;
static uint32_t lastStatusBlinkMs;
static uint32_t lastSirenaBlinkMs;
static bool sirenaPhase;

static bool buttonPressed;
static bool buttonRaw;
static uint32_t buttonChangedMs;
static uint32_t buttonDownMs;
static bool longPressFired;

static bool ignitionRaw;
static uint32_t ignitionChangedMs;

static bool lastGpsFix;

static char recentCommands[RECENT_COMMANDS][FIELD_MAX];
static uint8_t recentNext;

/* Ultimo comando recibido de la nube, para mostrarlo en la OLED. */
static struct {
    bool present;
    uint32_t receivedMs;
    char origin[8];  /* APP o PANEL */
    char action[DISPLAY_COLS + 1];
    char outcome[DISPLAY_COLS + 1];
} lastCommand;

static uint32_t lastDisplayMs;

static bool updateMovement(void);

static const char *boolStr(bool v)
{
    return v ? "true" : "false";
}

static void writePin(GPIO_TypeDef *port, uint16_t pin, bool on)
{
    HAL_GPIO_WritePin(port, pin, on ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

static void updateLeds(void)
{
    writePin(LED_CORTE_PORT, LED_CORTE_PIN, state.cortaCorriente);
    writePin(LED_SIRENA_PORT, LED_SIRENA_PIN, state.sirena && sirenaPhase);
    writePin(LED_HUMO_PORT, LED_HUMO_PIN, state.humo);
    writePin(LED_PROTOCOLO_PORT, LED_PROTOCOLO_PIN, state.protocoloActivo);
    writePin(LED_ARMADO_PORT, LED_ARMADO_PIN, state.armed);
}

static void sendTelemetry(void)
{
    const GpsData *gps = gps_data();

    /* Sin fix se manda la ultima posicion conocida (o la de prueba si nunca hubo)
     * con gpsFix=false, y sin velocidad ni rumbo: un dato desconocido no es 0 km/h. */
    printf("TEL {\"sequence\":%lu,\"location\":{\"lat\":%.7f,\"lng\":%.7f,",
           ++state.sequence,
           gps->hasEverFix ? gps->lat : DEFAULT_LAT,
           gps->hasEverFix ? gps->lng : DEFAULT_LNG);
    if (gps->fix) {
        printf("\"speedKmh\":%.1f,\"heading\":%.1f,", gps->speedKmh, gps->courseDeg);
    }
    printf("\"gpsFix\":%s,\"satellites\":%u},", boolStr(gps->fix), (unsigned)gps->satellites);

    printf("\"power\":{\"vehicleVoltage\":%s,\"externalPower\":true},"
           "\"signals\":{\"ignition\":%s,\"movement\":%s,\"panicButton\":%s,\"tamper\":false},"
           "\"actuators\":{\"humo\":%s,\"sirena\":%s,\"cortaCorriente\":%s,\"protocoloActivo\":%s},"
           "\"systemMode\":\"%s\","
           "\"firmwareVersion\":\"" FW_VERSION "\",\"hardwareVersion\":\"" HW_VERSION "\"}\r\n",
           state.ignition ? "13.8" : "12.6",
           boolStr(state.ignition), boolStr(state.movement), boolStr(state.panicButton),
           boolStr(state.humo), boolStr(state.sirena), boolStr(state.cortaCorriente),
           boolStr(state.protocoloActivo),
           state.armed ? "armed" : "normal");
    state.panicButton = false;
    lastTelemetryMs = HAL_GetTick();
}

/* metadata debe ser un objeto JSON ya armado, por ejemplo "{}". */
static void sendEvent(const char *type, const char *severity, const char *metadata)
{
    printf("EVT {\"sequence\":%lu,\"type\":\"%s\",\"severity\":\"%s\",\"metadata\":%s}\r\n",
           ++state.sequence, type, severity, metadata);
}

static void sendActuatorChanged(const char *target, bool value)
{
    char metadata[64];
    snprintf(metadata, sizeof metadata, "{\"target\":\"%s\",\"value\":%s}", target, boolStr(value));
    sendEvent("actuatorStateChanged", "info", metadata);
}

/* ---- Parser JSON minimo: solo lo necesario para leer un comando plano. ---- */

/* Copia el valor de "key" (string sin comillas, o literal true/false/numero). */
static bool jsonGetField(const char *json, const char *key, char *out, size_t outLen)
{
    char pattern[FIELD_MAX + 3];
    snprintf(pattern, sizeof pattern, "\"%s\"", key);
    const char *p = strstr(json, pattern);
    if (!p) {
        return false;
    }
    p += strlen(pattern);
    while (*p == ' ') p++;
    if (*p != ':') {
        return false;
    }
    p++;
    while (*p == ' ') p++;

    size_t n = 0;
    if (*p == '"') {
        p++;
        while (*p && *p != '"' && n < outLen - 1) out[n++] = *p++;
        if (*p != '"') {
            return false;
        }
    } else {
        while (*p && *p != ',' && *p != '}' && *p != ' ' && n < outLen - 1) out[n++] = *p++;
    }
    out[n] = '\0';
    return n > 0;
}

static bool parseBool(const char *s, bool *out)
{
    if (strcmp(s, "true") == 0 || strcmp(s, "on") == 0 || strcmp(s, "1") == 0) {
        *out = true;
        return true;
    }
    if (strcmp(s, "false") == 0 || strcmp(s, "off") == 0 || strcmp(s, "0") == 0) {
        *out = false;
        return true;
    }
    return false;
}

/* ---- Logica de comandos ---- */

static void reject(CommandResult *r, const char *errorCode, const char *message)
{
    r->status = "rejected";
    r->errorCode = errorCode;
    snprintf(r->message, sizeof r->message, "%s", message);
}

static void setActuator(const char *target, bool value, CommandResult *r)
{
    bool *field;
    if (strcmp(target, "humo") == 0) {
        field = &state.humo;
    } else if (strcmp(target, "sirena") == 0) {
        field = &state.sirena;
    } else if (strcmp(target, "cortaCorriente") == 0) {
        /* Nunca cortar corriente con el vehiculo en movimiento (plan-de-trabajo.md seccion 9).
         * El firmware lo bloquea aunque el backend o la app dejen pasar el comando. */
        if (value && state.movement) {
            reject(r, "vehicle_moving", "Corte de corriente bloqueado: vehiculo en movimiento");
            return;
        }
        field = &state.cortaCorriente;
    } else if (strcmp(target, "protocoloActivo") == 0) {
        field = &state.protocoloActivo;
    } else {
        reject(r, "unknown_target", "Target desconocido");
        return;
    }

    if (*field != value) {
        *field = value;
        sendActuatorChanged(target, value);
    }
    /* El protocolo de emergencia arrastra la sirena, igual que scripts/stm_simulator.py. */
    if (field == &state.protocoloActivo && state.sirena != value) {
        state.sirena = value;
        sendActuatorChanged("sirena", value);
    }

    r->status = "executed";
    r->errorCode = NULL;
    snprintf(r->message, sizeof r->message, "%s set to %s", target, boolStr(value));
}

static void setSystemMode(const char *mode, CommandResult *r)
{
    bool armed;
    if (strcmp(mode, "armed") == 0) {
        /* Igual que vehiculo_controller.dart: no se arma con el vehiculo en movimiento. */
        if (state.movement) {
            reject(r, "vehicle_moving", "No se puede armar con el vehiculo en movimiento");
            return;
        }
        armed = true;
    } else if (strcmp(mode, "normal") == 0) {
        armed = false;
    } else {
        reject(r, "invalid_value", "systemMode debe ser armed o normal");
        return;
    }

    state.armed = armed;
    r->status = "executed";
    r->errorCode = NULL;
    snprintf(r->message, sizeof r->message, "systemMode set to %s", mode);
}

static void executeCommand(const char *type, const char *target, const char *value, CommandResult *r)
{
    bool boolValue;

    if (strcmp(type, "setActuator") == 0) {
        if (!parseBool(value, &boolValue)) {
            reject(r, "invalid_value", "value debe ser true o false");
            return;
        }
        setActuator(target, boolValue, r);
    } else if (strcmp(type, "setSystemMode") == 0) {
        setSystemMode(value, r);
    } else if (strcmp(type, "requestTelemetryNow") == 0) {
        r->status = "executed";
        r->errorCode = NULL;
        snprintf(r->message, sizeof r->message, "Telemetria enviada");
    } else {
        reject(r, "unsupported_command", "Comando no soportado por este firmware");
    }
}

static bool alreadyProcessed(const char *commandId)
{
    for (int i = 0; i < RECENT_COMMANDS; i++) {
        if (strcmp(recentCommands[i], commandId) == 0) {
            return true;
        }
    }
    return false;
}

static void rememberCommand(const char *commandId)
{
    snprintf(recentCommands[recentNext], FIELD_MAX, "%s", commandId);
    recentNext = (uint8_t)((recentNext + 1) % RECENT_COMMANDS);
}

static void sendAck(const char *commandId, const char *target, const char *value, const CommandResult *r)
{
    char result[96] = "{}";
    if (strcmp(r->status, "executed") == 0) {
        /* value se repite tal cual: true/false para actuadores, string para systemMode. */
        bool b;
        if (parseBool(value, &b)) {
            snprintf(result, sizeof result, "{\"target\":\"%s\",\"value\":%s,\"actuatorState\":%s}",
                     target, boolStr(b), boolStr(b));
        } else {
            snprintf(result, sizeof result, "{\"target\":\"%s\",\"value\":\"%s\"}", target, value);
        }
    }

    printf("ACK {\"commandId\":\"%s\",\"status\":\"%s\",\"result\":%s,", commandId, r->status, result);
    if (r->errorCode) {
        printf("\"errorCode\":\"%s\",", r->errorCode);
    } else {
        printf("\"errorCode\":null,");
    }
    printf("\"message\":\"%s\"}\r\n", r->message);
}

/* ---- Pantalla OLED ---- */

static const char *targetLabel(const char *target)
{
    if (strcmp(target, "humo") == 0) return "Humo";
    if (strcmp(target, "sirena") == 0) return "Sirena";
    if (strcmp(target, "cortaCorriente") == 0) return "Corte corriente";
    if (strcmp(target, "protocoloActivo") == 0) return "Protocolo";
    if (strcmp(target, "systemMode") == 0) return "Modo";
    return target;
}

static const char *valueLabel(const char *value)
{
    bool b;
    if (parseBool(value, &b)) return b ? "ON" : "OFF";
    if (strcmp(value, "armed") == 0) return "ARMADO";
    if (strcmp(value, "normal") == 0) return "NORMAL";
    return value;
}

static void recordCommand(const char *role, const char *type, const char *target, const char *value,
                          const CommandResult *r)
{
    lastCommand.present = true;
    lastCommand.receivedMs = HAL_GetTick();
    /* Roles de la app: client (app movil); admin/operator/technician (panel web). */
    snprintf(lastCommand.origin, sizeof lastCommand.origin, "%s", strcmp(role, "client") == 0 ? "APP" : "PANEL");

    if (strcmp(type, "requestTelemetryNow") == 0) {
        snprintf(lastCommand.action, sizeof lastCommand.action, "Pedir telemetria");
    } else {
        snprintf(lastCommand.action, sizeof lastCommand.action, "%s -> %s", targetLabel(target), valueLabel(value));
    }

    if (strcmp(r->status, "executed") == 0) {
        snprintf(lastCommand.outcome, sizeof lastCommand.outcome, "Ejecutado");
    } else if (r->errorCode && strcmp(r->errorCode, "vehicle_moving") == 0) {
        snprintf(lastCommand.outcome, sizeof lastCommand.outcome, "RECHAZADO: en marcha");
    } else {
        snprintf(lastCommand.outcome, sizeof lastCommand.outcome, "RECHAZADO: %s", r->errorCode ? r->errorCode : "?");
    }
}

/* Etiqueta y estado ON/OFF; el ON va en video inverso para que se note de lejos. */
static void drawFlag(uint8_t row, uint8_t col, const char *label, bool on)
{
    display_text(row, col, label, false);
    display_text(row, (uint8_t)(col + 7), on ? " ON" : "OFF", on);
}

static void renderDisplay(uint32_t nowMs)
{
    char line[DISPLAY_COLS + 1];

    display_clear();
    display_text(0, 0, "  FIRST PROTECTION", false);
    display_invert_row(0);

    snprintf(line, sizeof line, "Modo %-7s Ign %s", state.armed ? "ARMADO" : "NORMAL", state.ignition ? "ON" : "OFF");
    display_text(1, 0, line, false);

    const GpsData *gps = gps_data();
    if (gps->fix) {
        snprintf(line, sizeof line, "GPS OK %2usat %3.0fkm/h", (unsigned)gps->satellites, gps->speedKmh);
    } else if (gps->receiving) {
        snprintf(line, sizeof line, "GPS buscando %2usat", (unsigned)gps->satellites);
    } else {
        snprintf(line, sizeof line, "GPS sin datos");
    }
    display_text(2, 0, line, false);

    drawFlag(3, 0, "Humo", state.humo);
    drawFlag(3, 11, "Sirena", state.sirena);
    drawFlag(4, 0, "Corte", state.cortaCorriente);
    drawFlag(4, 11, "Protoc", state.protocoloActivo);

    if (!lastCommand.present) {
        display_text(6, 0, "Esperando comandos", false);
        display_text(7, 0, "de la app/panel...", false);
    } else {
        uint32_t ago = (nowMs - lastCommand.receivedMs) / 1000;
        char agoText[12];
        if (ago < 60) {
            snprintf(agoText, sizeof agoText, "%lus", ago);
        } else if (ago < 3600) {
            snprintf(agoText, sizeof agoText, "%lum", ago / 60);
        } else {
            snprintf(agoText, sizeof agoText, "%luh", ago < 99 * 3600 ? ago / 3600 : 99);
        }
        snprintf(line, sizeof line, "Desde %-5s hace %s", lastCommand.origin, agoText);
        display_text(5, 0, line, false);
        display_text(6, 0, lastCommand.action, false);
        display_text(7, 0, lastCommand.outcome, false);
        if (nowMs - lastCommand.receivedMs < COMMAND_HIGHLIGHT_MS) {
            display_invert_row(5);
            display_invert_row(6);
            display_invert_row(7);
        }
    }

    display_flush();
}

/* CMD {json}: comando que viene de la nube y debe responderse con ACK. */
static void handleRemoteCommand(const char *json)
{
    char commandId[FIELD_MAX], type[FIELD_MAX], target[FIELD_MAX], value[FIELD_MAX], role[FIELD_MAX];
    CommandResult r = {0};

    if (!jsonGetField(json, "commandId", commandId, sizeof commandId)) {
        printf("# CMD sin commandId, ignorado\r\n");
        return;
    }
    if (alreadyProcessed(commandId)) {
        r.status = "received";
        snprintf(r.message, sizeof r.message, "Command already processed");
        sendAck(commandId, "", "", &r);
        return;
    }
    /* target y value son opcionales (requestTelemetryNow puede venir sin ellos). */
    if (!jsonGetField(json, "type", type, sizeof type)) type[0] = '\0';
    if (!jsonGetField(json, "target", target, sizeof target)) target[0] = '\0';
    if (!jsonGetField(json, "value", value, sizeof value)) value[0] = '\0';
    if (!jsonGetField(json, "requestedByRole", role, sizeof role)) role[0] = '\0';

    executeCommand(type, target, value, &r);
    rememberCommand(commandId);
    recordCommand(role, type, target, value, &r);
    sendAck(commandId, target, value, &r);
    sendTelemetry();
    lastDisplayMs = 0; /* refrescar la pantalla en la proxima vuelta */
}

/* ---- Comandos de texto para pruebas manuales ---- */

static void printStatus(void)
{
    printf("# modo=%s motor=%s corte=%s sirena=%s humo=%s protocolo=%s oled=%s\r\n",
           state.armed ? "ARMADO" : "normal",
           state.ignition ? "encendido" : "apagado",
           state.cortaCorriente ? "ON" : "off",
           state.sirena ? "ON" : "off",
           state.humo ? "ON" : "off",
           state.protocoloActivo ? "ON" : "off",
           display_ready(HAL_GetTick()) ? "conectada" : "no detectada");

    const GpsData *gps = gps_data();
    if (gps->fix) {
        printf("# gps=fix lat=%.6f lng=%.6f vel=%.1fkm/h rumbo=%.0f sat=%u hdop=%.1f movimiento=%s\r\n",
               gps->lat, gps->lng, gps->speedKmh, gps->courseDeg, (unsigned)gps->satellites, gps->hdop,
               state.movement ? "si" : "no");
    } else {
        printf("# gps=%s sat=%u movimiento=%s\r\n", gps->receiving ? "buscando satelites" : "sin datos (revisar TX del GPS -> D2)",
               (unsigned)gps->satellites, state.movement ? "si" : "no");
    }
}

static void printHelp(void)
{
    printf("# Comandos: humo|sirena|corte|protocolo on|off, armar, desarmar, estado, ayuda\r\n");
    printf("# Boton azul (boton oculto): corto = alerta de panico, mantener 2 s = protocolo de emergencia\r\n");
    printf("# Ignicion: cable de D9 a GND = llave en contacto\r\n");
    printf("# GPS: TX del modulo -> D2. Para probar sin modulo: nmea $GNRMC,...*hh\r\n");
}

static void handleLocalCommand(const char *line)
{
    char name[FIELD_MAX] = {0};
    char arg[FIELD_MAX] = {0};
    CommandResult r = {0};
    const char *type = "setActuator";
    const char *target;
    const char *value = arg;

    if (strncmp(line, "nmea ", 5) == 0) {
        gps_feed_sentence(line + 5);
        return;
    }

    sscanf(line, "%47s %47s", name, arg);

    if (strcmp(name, "estado") == 0) {
        printStatus();
        return;
    }
    if (strcmp(name, "ayuda") == 0 || strcmp(name, "help") == 0) {
        printHelp();
        return;
    }

    if (strcmp(name, "humo") == 0) {
        target = "humo";
    } else if (strcmp(name, "sirena") == 0) {
        target = "sirena";
    } else if (strcmp(name, "corte") == 0) {
        target = "cortaCorriente";
    } else if (strcmp(name, "protocolo") == 0) {
        target = "protocoloActivo";
    } else if (strcmp(name, "armar") == 0 || strcmp(name, "desarmar") == 0) {
        type = "setSystemMode";
        target = "systemMode";
        value = name[0] == 'a' ? "armed" : "normal";
    } else {
        printf("# Comando desconocido: %s (escribe ayuda)\r\n", name);
        return;
    }

    executeCommand(type, target, value, &r);
    if (r.errorCode) {
        printf("# rechazado (%s): %s\r\n", r.errorCode, r.message);
    } else {
        printf("# ok: %s\r\n", r.message);
    }
    sendTelemetry();
}

void device_handle_line(const char *line)
{
    if (strncmp(line, "CMD ", 4) == 0) {
        handleRemoteCommand(line + 4);
    } else {
        handleLocalCommand(line);
    }
}

/* ---- Boton oculto bajo el volante (B1), segun physical-device-integration.md ---- */

/* Pulsacion corta: alerta. Solo marca el evento, no activa actuadores. */
static void onShortPress(uint32_t durationMs)
{
    char metadata[64];
    printf("# Boton de panico: alerta\r\n");
    state.panicButton = true;
    snprintf(metadata, sizeof metadata, "{\"source\":\"physical_button\",\"pressDurationMs\":%lu}", durationMs);
    sendEvent("panicButtonPressed", "critical", metadata);
    sendTelemetry();
}

/* Pulsacion larga: activa el protocolo de emergencia (arrastra la sirena). */
static void onLongPress(void)
{
    CommandResult r = {0};
    printf("# Boton de panico: protocolo de emergencia\r\n");
    state.panicButton = true;
    sendEvent("panicButtonPressed", "critical",
              "{\"source\":\"physical_button\",\"pressDurationMs\":2000,\"action\":\"protocoloActivo\"}");
    setActuator("protocoloActivo", true, &r);
    sendTelemetry();
}

static void handleButton(uint32_t nowMs)
{
    bool raw = HAL_GPIO_ReadPin(BUTTON_PORT, BUTTON_PIN) == GPIO_PIN_RESET;
    if (raw != buttonRaw) {
        buttonRaw = raw;
        buttonChangedMs = nowMs;
    }

    if (nowMs - buttonChangedMs >= DEBOUNCE_MS && buttonRaw != buttonPressed) {
        buttonPressed = buttonRaw;
        if (buttonPressed) {
            buttonDownMs = nowMs;
            longPressFired = false;
        } else if (!longPressFired) {
            onShortPress(nowMs - buttonDownMs);
        }
    }

    if (buttonPressed && !longPressFired && nowMs - buttonDownMs >= LONG_PRESS_MS) {
        longPressFired = true;
        onLongPress();
    }
}

/* ---- Ignicion/ACC (D9) ---- */

static void handleIgnition(uint32_t nowMs)
{
    bool raw = HAL_GPIO_ReadPin(IGNITION_PORT, IGNITION_PIN) == GPIO_PIN_RESET;
    if (raw != ignitionRaw) {
        ignitionRaw = raw;
        ignitionChangedMs = nowMs;
    }
    if (nowMs - ignitionChangedMs < DEBOUNCE_MS || ignitionRaw == state.ignition) {
        return;
    }

    state.ignition = ignitionRaw;
    printf("# Ignicion %s%s\r\n", state.ignition ? "ON" : "OFF",
           state.ignition && state.cortaCorriente ? " (corte activo: el motor no arranca)" : "");
    sendEvent(state.ignition ? "ignitionOn" : "ignitionOff", "info", "{}");
    updateMovement();
    sendTelemetry();
}

/* ---- GPS y movimiento ---- */

/* Devuelve true si cambio algo que amerite telemetria inmediata. */
static bool updateMovement(void)
{
    const GpsData *gps = gps_data();
    bool changed = false;

    if (gps->fix != lastGpsFix) {
        lastGpsFix = gps->fix;
        printf("# GPS %s\r\n", gps->fix ? "con fix" : "sin fix");
        sendEvent(gps->fix ? "gpsRecovered" : "gpsLost", gps->fix ? "info" : "warning", "{}");
        changed = true;
    }

    /* Con fix manda la velocidad real. Sin fix se usa el motor como aproximacion
     * (con corte activo el motor no anda aunque la llave este en contacto). */
    bool moving;
    if (gps->fix) {
        moving = gps->speedKmh >= (state.movement ? MOVING_STOP_KMH : MOVING_START_KMH);
    } else {
        moving = state.ignition && !state.cortaCorriente;
    }

    if (moving != state.movement) {
        state.movement = moving;
        printf("# Vehiculo %s\r\n", moving ? "en movimiento" : "detenido");
        if (moving && state.armed) {
            sendEvent("vehicleMovedWhileArmed", "critical", "{}");
        }
        changed = true;
    }
    return changed;
}

/* ---- API publica ---- */

void device_init(void)
{
    GPIO_InitTypeDef gpio = {0};

    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();

    gpio.Mode = GPIO_MODE_OUTPUT_PP;
    gpio.Pull = GPIO_NOPULL;
    gpio.Speed = GPIO_SPEED_FREQ_LOW;
    gpio.Pin = LED_STATUS_PIN | LED_ARMADO_PIN;
    HAL_GPIO_Init(GPIOA, &gpio);
    gpio.Pin = LED_CORTE_PIN | LED_SIRENA_PIN | LED_HUMO_PIN | LED_PROTOCOLO_PIN;
    HAL_GPIO_Init(GPIOB, &gpio);

    gpio.Mode = GPIO_MODE_INPUT;
    gpio.Pin = BUTTON_PIN;
    HAL_GPIO_Init(BUTTON_PORT, &gpio);
    gpio.Pull = GPIO_PULLUP;
    gpio.Pin = IGNITION_PIN;
    HAL_GPIO_Init(IGNITION_PORT, &gpio);

    updateLeds();

    printf("\r\n# First Protection firmware " FW_VERSION " (" HW_VERSION ")\r\n");
    printHelp();
    display_init();
    gps_init();
    sendTelemetry();
}

void device_tick(uint32_t nowMs)
{
    gps_tick(nowMs);
    handleButton(nowMs);
    handleIgnition(nowMs);
    if (updateMovement()) {
        sendTelemetry();
    }

    if (nowMs - lastStatusBlinkMs >= STATUS_BLINK_MS) {
        lastStatusBlinkMs = nowMs;
        HAL_GPIO_TogglePin(LED_STATUS_PORT, LED_STATUS_PIN);
    }
    if (nowMs - lastSirenaBlinkMs >= SIRENA_BLINK_MS) {
        lastSirenaBlinkMs = nowMs;
        sirenaPhase = !sirenaPhase;
    }
    /* HAL_GetTick() y no nowMs: si en este mismo tick ya se envio telemetria,
     * lastTelemetryMs es posterior a nowMs y la resta sin signo daria la vuelta. */
    if (HAL_GetTick() - lastTelemetryMs >= TELEMETRY_PERIOD_MS) {
        sendTelemetry();
    }
    if ((lastDisplayMs == 0 || nowMs - lastDisplayMs >= DISPLAY_REFRESH_MS) && display_ready(nowMs)) {
        lastDisplayMs = nowMs;
        renderDisplay(nowMs);
    }

    updateLeds();
}
