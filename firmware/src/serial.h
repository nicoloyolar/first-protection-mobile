#ifndef SERIAL_H
#define SERIAL_H

#include <stdbool.h>
#include <stddef.h>

/* USART2 a 115200 baudios (puerto virtual del ST-Link). printf sale por aqui. */
void serial_init(void);

/* Devuelve true cuando hay una linea completa (sin \r\n) en buf. No bloquea. */
bool serial_read_line(char *buf, size_t len);

#endif
