#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdbool.h>
#include <stdint.h>

/*
 * OLED 1.3" 128x64 por I2C1: SCL = D15 (PB8), SDA = D14 (PB9), VCC = 3V3.
 * Texto en 8 filas de 21 caracteres (fuente 5x7 en celdas de 6x8).
 *
 * Las de 1.3" casi siempre traen controlador SH1106; las de 0.96", SSD1306.
 * Si la imagen se ve corrida 2 pixeles o con basura en un borde, cambiar
 * OLED_SH1106 a 0.
 */
#ifndef OLED_SH1106
#define OLED_SH1106 1
#endif

#define DISPLAY_ROWS 8
#define DISPLAY_COLS 21

void display_init(void);

/* Reintenta detectar la pantalla si no estaba (se puede conectar en caliente). */
bool display_ready(uint32_t nowMs);

void display_clear(void);
void display_text(uint8_t row, uint8_t col, const char *text, bool inverted);
/* Pinta una fila completa en video inverso (fondo encendido). */
void display_invert_row(uint8_t row);
void display_flush(void);

#endif
