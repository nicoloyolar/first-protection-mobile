# First Protection

Aplicacion Flutter para monitoreo y gestion de dispositivos de seguridad vehicular First Protection.

El MVP considera dos superficies:

- Cliente movil: login, vinculacion de vehiculo, visualizacion en mapa y comandos remotos.
- Admin web: command center interno, inventario de dispositivos/clientes y acciones operativas.

## Stack

- Flutter / Dart
- Firebase Auth
- Firebase Realtime Database
- Google Maps
- Provider

## Modelo De Acceso

El panel web esta pensado primero para el equipo First Protection. Tambien queda preparado para crecer hacia empresas, familias o flotas compartidas mediante:

- `usuarios/{uid}/role`: `admin`, `operator`, `technician`, `client`
- `usuarios/{uid}/accountType`: `internal`, `company`, `family`, `individual`
- `usuarios/{uid}/organizationId`: por defecto `first-protection`
- `vehicles_meta/{vehicleId}/organizationId`
- `dispositivos/{deviceId}/organizationId`

Roles con acceso al admin web:

- `admin`
- `operator`
- `technician`

## Estructura De Datos Principal

```text
usuarios/{uid}
  email
  nombre
  role
  accountType
  organizationId
  mis_vehiculos/{vehicleId}: true

vehicles_meta/{vehicleId}
  idVehiculo
  idDispositivo
  idPropietario
  idDueno
  organizationId
  alias
  patente
  marca
  modelo
  anio
  color

dispositivos/{deviceId}
  id
  idVehiculo
  idPropietario
  organizationId
  alias
  patente
  latitud
  longitud
  velocidad
  voltaje
  cortaCorriente
  protocoloActivo
  humo
  ultimoComando

eventos/{deviceId}/{eventId}
  tipo
  campo
  valor
  actorUid
  actorRole
  timestamp
```

## Comandos

Los comandos criticos se escriben mediante `DatabaseService.actualizarComandoDispositivo`, que actualiza el dispositivo y deja una entrada en `eventos/{deviceId}`.

Campos operativos actuales:

- `cortaCorriente`
- `protocoloActivo`
- `humo`

## Integracion Con Dispositivo Fisico

El dispositivo STM instalado en el vehiculo sera la fuente oficial de telemetria vehicular. La ubicacion del telefono representa al usuario y no debe reemplazar la ubicacion del automovil.

Documentacion tecnica:

- [Integracion STM y arquitectura fisica](docs/physical-device-integration.md)
- [Contrato API para dispositivo](docs/device-api-contract.md)
- [Plan de trabajo hardware](docs/hardware-roadmap.md)
- [Simulador STM](docs/stm-simulator.md)
- [Checklist de integracion](docs/integration-checklist.md)

Resumen de responsabilidades:

- STM: reporta telemetria, recibe comandos, ejecuta humo/sirena/corta corriente y confirma resultados.
- Backend/API: valida identidad del dispositivo, registra eventos, crea comandos pendientes y sincroniza Firebase.
- App movil: solicita comandos autorizados, muestra estado del vehiculo y compara cercania usuario-vehiculo.
- Panel web: opera flota, monitorea alertas, envia comandos y da soporte.

Simulador rapido:

```bash
python scripts/stm_simulator.py --scenario carjacking --dry-run
```

API local de dispositivo:

```bash
cd functions
npm run serve:device-api
```

## Correr El Proyecto

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run -d chrome
```

## Checklist MVP

- Admin web exige Firebase Auth y rol autorizado.
- Cliente solo carga vehiculos asociados a su `uid`.
- Los comandos criticos tienen confirmacion en el panel admin.
- Las acciones de mando quedan auditadas en `eventos`.
- La ubicacion del telefono no sobreescribe la ubicacion del dispositivo por defecto.
- `flutter analyze` y `flutter test` deben pasar antes de una demo.

## Pendientes Antes De Produccion

- Publicar reglas estrictas de Realtime Database alineadas al esquema anterior.
- Restringir las API keys de Google Maps por dominio, paquete Android, SHA-1 y APIs permitidas.
- Definir proceso formal para crear usuarios admin y asignar roles.
- Reconstruir o eliminar `functions/` si se usaran Cloud Functions reales.
