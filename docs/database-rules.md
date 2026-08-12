# Reglas De Realtime Database

Este documento explica el diseño de `database.rules.json` (raíz del repo) y,
sobre todo, el paso operativo que hay que hacer **antes** de desplegarlas.

## ⚠️ Antes De Desplegar: Sembrar El Primer Admin

Las reglas exigen que para tener rol admin/operator/technician, el nodo
`usuarios/{uid}/role` ya tenga ese valor — y **escribir ese nodo también
requiere ya ser admin**. Es el problema clásico de arranque en frío de
cualquier sistema de reglas basado en roles.

Antes de desplegar `database.rules.json` a un proyecto que todavía no tiene
ningún usuario con `role: admin`, hay que crear al menos uno manualmente
(Firebase Console → Realtime Database → editar datos directamente, o un
script con el Admin SDK) — ambos caminos ignoran las reglas por diseño.
Sin este paso, nadie podría entrar al panel admin después del deploy (no se
rompe la app ni tira error raro: simplemente `usuarioPuedeAccederAdmin`
devuelve `false` para todos, porque nadie tiene el rol seteado todavía).

Estructura mínima a crear en `usuarios/{uid}` para el primer admin:

```json
{
  "email": "correo@ejemplo.cl",
  "nombre": "Nombre Apellido",
  "role": "admin",
  "accountType": "internal",
  "organizationId": "first-protection",
  "active": true
}
```

Usar exactamente la clave `role` (no `rol`) — es la que usan tanto
`AppUserProfile.toMap()` como las reglas.

## Qué Resuelven Estas Reglas

Antes de este cambio, `firebase.json` no referenciaba ningún archivo de
reglas, así que la base estaba en modo abierto/dev — cualquiera con la
configuración del proyecto (pública en cualquier app cliente) podía leer o
escribir cualquier dato. Esto era el riesgo de seguridad más urgente
identificado en `docs/plan-de-trabajo.md`.

Principios del diseño:

- **Todo requiere autenticación.** No hay lectura ni escritura anónima en
  ningún nodo.
- **Separación cliente vs. interno.** `admin`, `operator` y `technician`
  (verificados vía `usuarios/{auth.uid}/role`) tienen acceso amplio de
  lectura/escritura, equivalente a lo que ya hace el panel admin. Un
  `client` solo puede leer/escribir lo relacionado a sus propios vehículos
  (`vehicles_meta/{id}/idPropietario === auth.uid`).
- **El cliente nunca toca el estado real del actuador.** En `dispositivos/
  {deviceId}` solo se permite escritura de campos de auto-registro (`alias`,
  `patente`, `id`, `idVehiculo`, `idPropietario`, `organizationId`,
  `ultimaVinculacion`, `ultimoComando`) al dueño del vehículo. Campos como
  `humo`, `cortaCorriente`, `protocoloActivo`, `location`, `power`, etc. no
  tienen ninguna regla de escritura para el cliente — solo el Admin SDK
  (backend en `functions/`, que ignora las reglas) puede tocarlos. Esto
  refuerza a nivel de base de datos el fix del Sprint 2 (comandos vía cola
  pendiente/ACK, no escritura directa).
- **Un cliente no puede falsificar su propio ACK.** En `device_commands/
  {deviceId}/{commandId}`, el dueño del vehículo solo puede **crear** un
  comando nuevo (`!data.exists()`) con `status: pending` y los campos
  mínimos del contrato. No puede modificar un comando ya existente — o sea,
  no puede marcar su propio comando como `executed` desde la app. Los roles
  admin/operator/technician sí pueden (heredado del permiso de escritura
  amplio en el nodo padre), consistente con que ya son roles de confianza
  con control total del dispositivo desde el panel.
- **Auditoría inmutable.** En `eventos/{deviceId}/{eventId}` solo se permite
  crear (`!data.exists()`), nunca editar ni borrar un evento ya registrado
  — ni siquiera un admin.

## Qué NO Cubre Todavía (simplificaciones a propósito, alcance MVP)

- **Sin aislación por `organizationId`.** El modelo de datos ya soporta
  multi-organización, pero las reglas de hoy no filtran por ella (un
  admin/operator/technician ve todas las organizaciones). Aceptable
  mientras exista una sola organización real (`first-protection`); revisar
  si el proyecto avanza a vender a múltiples empresas/flotas.
- **Sin `.validate` exhaustivo de tipos/rangos** en todos los campos (por
  ejemplo, no se valida que `patente` tenga el formato chileno correcto a
  nivel de reglas). Se priorizó asegurar el límite de seguridad importante
  (quién puede tocar qué) sobre la validación exhaustiva de forma de datos.
- **Sin probar contra el emulador de Firebase todavía.** Se verificó la
  sintaxis JSON y se revisó a mano cada flujo de escritura del código
  (`database_service.dart`, pantallas de admin y móvil) contra las reglas,
  pero no hay corrida automatizada en `firebase emulators:start` que lo
  confirme. Recomendado antes de una demo con datos reales.

## Cómo Desplegar

```bash
firebase deploy --only database
```

O probar primero en el emulador local (requiere Firebase CLI + Java):

```bash
firebase emulators:start --only database
```
