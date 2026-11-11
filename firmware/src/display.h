#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdbool.h>
#include <stdint.h>

/*
 * Pantalla LCD monocromatica 128x64 GM12864-03A, controlador ST7567, por SPI
 * (generado por software, ver display.c). Conexion en el conector derecho:
 *   CS -> D10, RST -> D11, A0 -> D12, SCK -> D15, SDA -> D14,
 *   GND -> GND, VDD -> 3V3. BA/BK (retroiluminacion) son opcionales.
 * Texto en 8 filas de 21 caracteres (fuente 5x7 en celdas de 6x8).
 */

#define DISPLAY_ROWS 8
#define DISPLAY_COLS 21

#define DISPLAY_CONTRAST_MAX 63

void display_init(void);

/* La LCD no responde por SPI, asi que no se puede detectar: siempre true.
 * Reenvia la configuracion cada pocos segundos para que funcione aunque se
 * conecte con la placa ya encendida, o despues de una interferencia. */
bool display_ready(uint32_t nowMs);

void display_clear(void);
void display_text(uint8_t row, uint8_t col, const char *text, bool inverted);
/* Pinta una fila completa en video inverso (fondo oscuro). */
void display_invert_row(uint8_t row);
void display_flush(void);

/* Ajustes en vivo; varian entre modulos y se aplican de inmediato. */
void display_set_contrast(uint8_t contrast);
uint8_t display_contrast(void);
/* girar = rotar 180 (invierte ambos ejes); espejo = invierte solo el horizontal. */
void display_toggle_flip(void);
void display_toggle_mirror(void);
const char *display_orientation(void);

#endif
