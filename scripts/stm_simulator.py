#!/usr/bin/env python3
"""
First Protection STM simulator.

This script mimics the future physical device installed in a vehicle. It can
send telemetry, emit events, poll commands, and ACK command execution against
the proposed HTTP API contract.

It uses only Python's standard library so it can run in simple hardware/dev
workstations without extra dependencies.
"""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import math
import random
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from typing import Any


ACTUATOR_TARGETS = {"humo", "sirena", "cortaCorriente", "protocoloActivo"}


@dataclass
class SimulatorState:
    device_id: str
    base_lat: float
    base_lng: float
    firmware_version: str = "sim-0.1.0"
    hardware_version: str = "sim-rev-a"
    sequence: int = 0
    angle: float = 0.0
    speed_kmh: float = 0.0
    ignition: bool = False
    movement: bool = False
    panic_button: bool = False
    tamper: bool = False
    humo: bool = False
    sirena: bool = False
    corta_corriente: bool = False
    protocolo_activo: bool = False
    online: bool = True
    external_power: bool = True
    vehicle_voltage: float = 12.6
    backup_battery_percent: int = 94
    rssi: int = -71
    executed_commands: set[str] = field(default_factory=set)

    def tick(self, scenario: str) -> None:
        self.sequence += 1
        self.panic_button = False

        if scenario == "parked":
            self.speed_kmh = 0.0
            self.ignition = False
            self.movement = False
        elif scenario == "drive":
            self.angle += 0.025
            self.speed_kmh = 28 + random.uniform(-4, 4)
            self.ignition = True
            self.movement = True
        elif scenario == "carjacking":
            self.angle += 0.055
            self.speed_kmh = 48 + random.uniform(-8, 8)
            self.ignition = True
            self.movement = True
            if self.sequence == 3:
                self.panic_button = True
                self.protocolo_activo = True
                self.sirena = True
        elif scenario == "offline":
            self.online = self.sequence % 5 != 0
            self.speed_kmh = 0.0
            self.ignition = False
            self.movement = False

        if self.ignition:
            self.vehicle_voltage = 13.7 + random.uniform(-0.2, 0.2)
        else:
            self.vehicle_voltage = 12.3 + random.uniform(-0.2, 0.2)

        self.rssi = -71 + random.randint(-6, 5)

    @property
    def lat(self) -> float:
        radius = 0.002 if self.movement else 0.00004
        return self.base_lat + math.sin(self.angle) * radius

    @property
    def lng(self) -> float:
        radius = 0.002 if self.movement else 0.00004
        return self.base_lng + math.cos(self.angle) * radius

    @property
    def heading(self) -> float:
        return (math.degrees(self.angle) + 90) % 360

    def telemetry_payload(self) -> dict[str, Any]:
        now = int(time.time())
        return {
            "sequence": self.sequence,
            "timestamp": now,
            "location": {
                "lat": round(self.lat, 7),
                "lng": round(self.lng, 7),
                "accuracyMeters": round(random.uniform(5, 12), 1),
                "speedKmh": round(self.speed_kmh, 1),
                "heading": round(self.heading, 1),
                "gpsFix": True,
                "satellites": random.randint(7, 12),
            },
            "power": {
                "vehicleVoltage": round(self.vehicle_voltage, 2),
                "backupBatteryPercent": self.backup_battery_percent,
                "externalPower": self.external_power,
            },
            "signals": {
                "ignition": self.ignition,
                "movement": self.movement,
                "panicButton": self.panic_button,
                "tamper": self.tamper,
            },
            "actuators": {
                "humo": self.humo,
                "sirena": self.sirena,
                "cortaCorriente": self.corta_corriente,
            },
            "network": {
                "rssi": self.rssi,
                "operator": "simulated-carrier",
                "online": self.online,
            },
            "firmwareVersion": self.firmware_version,
            "hardwareVersion": self.hardware_version,
        }

    def event_payload(self, event_type: str, severity: str, metadata: dict[str, Any] | None = None) -> dict[str, Any]:
        return {
            "sequence": self.sequence,
            "timestamp": int(time.time()),
            "type": event_type,
            "severity": severity,
            "location": {
                "lat": round(self.lat, 7),
                "lng": round(self.lng, 7),
            },
            "metadata": metadata or {},
        }

    def apply_command(self, command: dict[str, Any]) -> tuple[str, dict[str, Any], str | None, str]:
        command_id = str(command.get("commandId") or command.get("id") or "")
        target = str(command.get("target") or "")
        value = command.get("value")

        if not command_id:
            return "rejected", {}, "missing_command_id", "Command has no id"

        if command_id in self.executed_commands:
            return "received", {}, None, "Command already processed"

        if target not in ACTUATOR_TARGETS:
            return "rejected", {"target": target}, "unknown_target", f"Unknown target {target}"

        bool_value = bool(value)
        if target == "humo":
            self.humo = bool_value
        elif target == "sirena":
            self.sirena = bool_value
        elif target == "cortaCorriente":
            self.corta_corriente = bool_value
        elif target == "protocoloActivo":
            self.protocolo_activo = bool_value
            self.sirena = bool_value

        self.executed_commands.add(command_id)
        return (
            "executed",
            {
                "target": target,
                "value": bool_value,
                "actuatorState": bool_value,
            },
            None,
            f"{target} set to {bool_value}",
        )


class ApiClient:
    def __init__(self, base_url: str, device_id: str, secret: str, dry_run: bool) -> None:
        self.base_url = base_url.rstrip("/")
        self.device_id = device_id
        self.secret = secret.encode("utf-8")
        self.dry_run = dry_run

    def post(self, path: str, payload: dict[str, Any]) -> dict[str, Any] | None:
        return self._request("POST", path, payload)

    def get(self, path: str) -> dict[str, Any] | None:
        return self._request("GET", path, None)

    def _request(self, method: str, path: str, payload: dict[str, Any] | None) -> dict[str, Any] | None:
        body = json.dumps(payload or {}, separators=(",", ":"), sort_keys=True).encode("utf-8")
        timestamp = str(int(time.time()))
        signature = hmac.new(self.secret, body + timestamp.encode("utf-8"), hashlib.sha256).hexdigest()

        url = f"{self.base_url}{path}"
        if self.dry_run:
            print(f"[dry-run] {method} {url}")
            if payload is not None:
                print(json.dumps(payload, indent=2, ensure_ascii=False))
            return None

        request = urllib.request.Request(
            url,
            data=body if method != "GET" else None,
            method=method,
            headers={
                "Content-Type": "application/json",
                "X-Device-Id": self.device_id,
                "X-Device-Timestamp": timestamp,
                "X-Device-Signature": signature,
            },
        )

        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                raw = response.read().decode("utf-8")
                return json.loads(raw) if raw else {}
        except urllib.error.URLError as exc:
            print(f"[warn] request failed: {exc}", file=sys.stderr)
            return None


def run(args: argparse.Namespace) -> None:
    state = SimulatorState(
        device_id=args.device_id,
        base_lat=args.lat,
        base_lng=args.lng,
    )
    client = ApiClient(args.base_url, args.device_id, args.secret, args.dry_run)

    for index in range(args.iterations):
        state.tick(args.scenario)
        telemetry = state.telemetry_payload()

        print(
            f"[{index + 1}/{args.iterations}] seq={state.sequence} "
            f"lat={telemetry['location']['lat']} lng={telemetry['location']['lng']} "
            f"speed={telemetry['location']['speedKmh']}km/h"
        )

        client.post(f"/api/v1/devices/{args.device_id}/telemetry", telemetry)

        if state.panic_button:
            client.post(
                f"/api/v1/devices/{args.device_id}/events",
                state.event_payload(
                    "panicButtonPressed",
                    "critical",
                    {"source": "physical_button", "pressDurationMs": 2200},
                ),
            )

        command_response = client.get(f"/api/v1/devices/{args.device_id}/commands/next")
        command = command_response.get("command") if command_response else None
        if command:
            status, result, error_code, message = state.apply_command(command)
            command_id = command.get("commandId") or command.get("id")
            client.post(
                f"/api/v1/devices/{args.device_id}/commands/{command_id}/ack",
                {
                    "status": status,
                    "executedAt": int(time.time()),
                    "result": result,
                    "errorCode": error_code,
                    "message": message,
                },
            )

        time.sleep(args.interval)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Simulate a First Protection STM device.")
    parser.add_argument("--base-url", default="http://localhost:5001", help="Backend/API base URL.")
    parser.add_argument("--device-id", default="GPS-SIM001", help="Simulated device id.")
    parser.add_argument("--secret", default="dev-secret", help="Device HMAC secret.")
    parser.add_argument("--scenario", choices=["parked", "drive", "carjacking", "offline"], default="drive")
    parser.add_argument("--lat", type=float, default=-36.82699, help="Base latitude.")
    parser.add_argument("--lng", type=float, default=-73.04977, help="Base longitude.")
    parser.add_argument("--iterations", type=int, default=10, help="Number of telemetry loops.")
    parser.add_argument("--interval", type=float, default=2.0, help="Seconds between telemetry loops.")
    parser.add_argument("--dry-run", action="store_true", help="Print requests without sending HTTP.")
    return parser.parse_args()


if __name__ == "__main__":
    run(parse_args())
