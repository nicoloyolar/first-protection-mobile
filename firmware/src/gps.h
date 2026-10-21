#ifndef GPS_H
#define GPS_H

#include <stdbool.h>
#include <stdint.h>

/*
 * GPS u-blox NEO-M8N (GY-GPSV3-NEO) por USART1 a 9600 baudios, NMEA:
 *   TX del GPS -> D2 (PA10), RX del GPS -> D8 (PA9, opcional).
 * Lee RMC (posicion, velocidad, rumbo) y GGA (satelites, HDOP), con
 * talker GP o GN (el M8N usa GN al combinar GPS + GLONASS/Galileo).
 */

typedef struct {
    bool receiving;  /* llegan bytes del modulo (cableado OK) */
    bool fix;        /* posicion valida reciente */
    bool hasEverFix; /* hubo fix alguna vez desde el arranque: lat/lng es la ultima conocida */
    double lat;
    double lng;
    float speedKmh;
    float courseDeg;
    uint8_t satellites;
    float hdop;
} GpsData;

void gps_init(void);
void gps_tick(uint32_t nowMs);
const GpsData *gps_data(void);

/* Inyecta una frase NMEA completa ("$GNRMC,...*hh"), para probar sin el modulo. */
void gps_feed_sentence(const char *sentence);

#endif
