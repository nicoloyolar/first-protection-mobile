#!/usr/bin/env python3
"""
First Protection serial bridge.

Conecta el firmware real (firmware/, por USB serial) con la deviceApi mientras
el dispositivo no tenga modem propio. Cumple el rol que despues tendra el
A7670: reenvia TEL/EVT/ACK del STM a la API con firma HMAC y le entrega al STM
los comandos pendientes como lineas CMD. El protocolo serial esta descrito en
firmware/src/device.h.

Requiere pyserial (pip install pyserial).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from typing import Any

import serial

from stm_simulator import ApiClient


class Bridge:
    def __init__(self, port: serial.Serial, client: ApiClient, device_id: str, poll_interval: float) -> None:
        self.port = port
        self.client = client
        self.device_id = device_id
        self.poll_interval = poll_interval
        self.base_path = f"/api/v1/devices/{device_id}"
        # El STM todavia no guarda nada en flash: su sequence vuelve a 1 en cada
        # reinicio y el backend descarta sequences menores al ultimo recibido.
        # Mientras tanto el puente numera con un contador que arranca en la hora actual.
        self.sequence = int(time.time())
        self.last_location: dict[str, Any] | None = None
        self.next_poll = 0.0

    def next_sequence(self) -> int:
        self.sequence += 1
        return self.sequence

    def handle_line(self, line: str) -> None:
        kind, _, payload_text = line.partition(" ")
        if kind == "#":
            print(f"[stm] {payload_text}")
            return
        if kind not in ("TEL", "EVT", "ACK"):
            print(f"[stm?] {line}")
            return

        try:
            payload = json.loads(payload_text)
        except json.JSONDecodeError as exc:
            print(f"[warn] JSON invalido desde el STM ({exc}): {line}", file=sys.stderr)
            return

        if kind == "TEL":
            self.send_telemetry(payload)
        elif kind == "EVT":
            self.send_event(payload)
        else:
            self.send_ack(payload)

    def send_telemetry(self, telemetry: dict[str, Any]) -> None:
        telemetry["sequence"] = self.next_sequence()
        telemetry["timestamp"] = int(time.time())
        telemetry["network"] = {"online": True, "operator": "usb-bridge"}
        self.last_location = telemetry.get("location")

        response = self.client.post(f"{self.base_path}/telemetry", telemetry)
        actuators = telemetry.get("actuators", {})
        on = [name for name, value in actuators.items() if value] or ["ninguno"]
        print(f"[tel] seq={telemetry['sequence']} modo={telemetry.get('systemMode')} activos={','.join(on)} -> {response}")

        if response and response.get("pendingCommands"):
            self.next_poll = 0.0

    def send_event(self, event: dict[str, Any]) -> None:
        event["sequence"] = self.next_sequence()
        event["timestamp"] = int(time.time())
        if self.last_location:
            event["location"] = {"lat": self.last_location["lat"], "lng": self.last_location["lng"]}

        response = self.client.post(f"{self.base_path}/events", event)
        print(f"[evt] {event['type']} ({event.get('severity')}) -> {response}")

    def send_ack(self, ack: dict[str, Any]) -> None:
        command_id = ack.pop("commandId", None)
        if not command_id:
            print(f"[warn] ACK sin commandId: {ack}", file=sys.stderr)
            return
        ack["executedAt"] = int(time.time())

        response = self.client.post(f"{self.base_path}/commands/{command_id}/ack", ack)
        print(f"[ack] {command_id} {ack.get('status')} {ack.get('message')} -> {response}")

    def poll_commands(self) -> None:
        response = self.client.get(f"{self.base_path}/commands/next")
        command = response.get("command") if response else None
        if not command:
            return

        command_id = command.get("commandId") or command.get("id")
        line = json.dumps(
            {
                "commandId": command_id,
                "type": command.get("type", "setActuator"),
                "target": command.get("target"),
                "value": command.get("value"),
                "requestedByRole": command.get("requestedByRole", ""),
            },
            separators=(",", ":"),
        )
        print(f"[cmd] {command_id} {command.get('type')} {command.get('target')}={command.get('value')}")
        self.port.write(f"CMD {line}\r\n".encode("utf-8"))

    def run(self) -> None:
        print(f"Puente {self.port.port} <-> {self.client.base_url} como {self.device_id}. Ctrl+C para salir.")
        # Descarta una linea que haya quedado a medias al abrir el puerto, y pide
        # telemetria al arrancar para no esperar el siguiente ciclo del STM.
        self.port.reset_input_buffer()
        self.port.write(b"estado\r\n")
        while True:
            raw = self.port.readline()
            if raw:
                line = raw.decode("utf-8", errors="replace").strip()
                if line:
                    self.handle_line(line)

            if time.monotonic() >= self.next_poll:
                self.poll_commands()
                self.next_poll = time.monotonic() + self.poll_interval


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Conecta el STM por USB serial con la deviceApi de First Protection.")
    parser.add_argument("--port", default="COM8", help="Puerto serie del ST-Link (ej. COM8 o /dev/ttyACM0).")
    parser.add_argument("--base-url", default="http://localhost:5001", help="URL base de la deviceApi.")
    parser.add_argument("--device-id", default="GPS-NUCLEO01", help="deviceId con el que se presenta el STM.")
    parser.add_argument(
        "--secret",
        default=os.environ.get("FP_DEVICE_SECRET", "dev-secret"),
        help="Secreto HMAC. Por defecto la variable de entorno FP_DEVICE_SECRET (no lo pases por linea de comandos en produccion).",
    )
    parser.add_argument("--poll-interval", type=float, default=2.0, help="Segundos entre consultas de comandos.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    client = ApiClient(args.base_url, args.device_id, args.secret, dry_run=False)
    with serial.Serial(args.port, 115200, timeout=0.1) as port:
        try:
            Bridge(port, client, args.device_id, args.poll_interval).run()
        except KeyboardInterrupt:
            print("\nPuente detenido.")


if __name__ == "__main__":
    main()
