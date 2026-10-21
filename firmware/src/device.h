#ifndef DEVICE_H
#define DEVICE_H

#include <stdint.h>

#define FW_VERSION "0.5.0"
#define HW_VERSION "nucleo-f401re"

/*
 * Protocolo por el puerto serie (una linea por mensaje).
 *
 * Dispositivo -> PC, mismos payloads que docs/device-api-contract.md; quien
 * reenvie a la nube agrega timestamp y firma:
 *   TEL {telemetria}
 *   EVT {evento}
 *   ACK {"commandId":..., "status":..., "result":..., "errorCode":..., "message":...}
 *   # texto     (log para humanos, se ignora)
 *
 * PC -> dispositivo:
 *   CMD {"commandId":..., "type":..., "target":..., "value":..., "requestedByRole":...}
 *   o comandos de texto para pruebas manuales (escribir "ayuda").
 */

void device_init(void);
void device_tick(uint32_t nowMs);
void device_handle_line(const char *line);

#endif
