"""
Hace de DFPlayer Mini en el PC mientras el modulo no este conectado: reproduce
por el parlante del computador los mensajes de voz que anuncia el firmware
("# Audio N: "texto"", ver firmware/src/audio.c).

Igual que en la microSD del DFPlayer, cada mensaje es un archivo numerado
(0001.wav, 0002.wav...). Se generan a partir del texto que manda el firmware y
se regeneran solos si cambia el texto o la voz. Si llega un mensaje mientras
suena otro, el nuevo lo corta, como en el modulo real.

Motores de voz:
- GoogleCloudVoice: voces neuronales latinoamericanas (es-US) de Google Cloud
  Text-to-Speech, con las credenciales ADC de gcloud y el proyecto
  first-protection. Ademas deja una copia MP3 en firmware/audio/mp3/, lista
  para la microSD del DFPlayer.
- WindowsVoice: la voz en espanol instalada en Windows, sin internet.

La reproduccion es solo Windows (winsound, sin dependencias extra).
"""

from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.request
from pathlib import Path

AUDIO_LINE = re.compile(r'^Audio (\d+): "(.*)"$')
CATALOG_LINE = re.compile(r'^AudioCatalogo (\d+): "(.*)"$')

DEFAULT_DIRECTORY = Path(__file__).resolve().parent.parent / "firmware" / "audio"
DEFAULT_GOOGLE_VOICE = "es-US-Chirp3-HD-Kore"
GCP_PROJECT = "first-protection"


class WindowsVoice:
    """Voz en espanol de Windows (System.Speech). Sin internet."""

    id = "windows"

    _SCRIPT = r"""
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voz = $s.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like 'es*' } | Select-Object -First 1
if ($voz) { $s.SelectVoice($voz.VoiceInfo.Name) }
$s.SetOutputToWaveFile($env:FP_TTS_OUT)
$s.Speak($env:FP_TTS_TEXT)
$s.Dispose()
"""

    def synthesize(self, text: str, wav: Path, mp3: Path | None) -> None:
        env = dict(os.environ, FP_TTS_TEXT=text, FP_TTS_OUT=str(wav))
        subprocess.run(
            ["powershell", "-NoProfile", "-NonInteractive", "-Command", self._SCRIPT],
            env=env,
            check=True,
            capture_output=True,
            timeout=30,
        )


class GoogleCloudVoice:
    """Voz neuronal de Google Cloud Text-to-Speech (requiere ADC de gcloud)."""

    _ENDPOINT = "https://texttospeech.googleapis.com/v1/text:synthesize"
    _TOKEN_TTL_S = 45 * 60

    def __init__(self, voice: str = DEFAULT_GOOGLE_VOICE) -> None:
        self.voice = voice
        self.language = "-".join(voice.split("-")[:2])
        self.id = f"google:{voice}"
        self._token: str | None = None
        self._token_time = 0.0

    def synthesize(self, text: str, wav: Path, mp3: Path | None) -> None:
        wav.write_bytes(self._request(text, "LINEAR16"))  # LINEAR16 llega con cabecera WAV
        if mp3 is not None:
            mp3.parent.mkdir(parents=True, exist_ok=True)
            mp3.write_bytes(self._request(text, "MP3"))

    def _request(self, text: str, encoding: str) -> bytes:
        body = json.dumps(
            {
                "input": {"text": text},
                "voice": {"languageCode": self.language, "name": self.voice},
                "audioConfig": {"audioEncoding": encoding},
            }
        ).encode("utf-8")
        request = urllib.request.Request(
            self._ENDPOINT,
            data=body,
            method="POST",
            headers={
                "Authorization": f"Bearer {self._access_token()}",
                "x-goog-user-project": GCP_PROJECT,
                "Content-Type": "application/json; charset=utf-8",
            },
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            return base64.b64decode(json.loads(response.read())["audioContent"])

    def _access_token(self) -> str:
        if self._token is None or time.time() - self._token_time > self._TOKEN_TTL_S:
            result = subprocess.run(
                "gcloud auth application-default print-access-token",
                shell=True,  # gcloud es un .cmd en Windows
                check=True,
                capture_output=True,
                text=True,
                timeout=60,
            )
            self._token = result.stdout.strip()
            self._token_time = time.time()
        return self._token


class PcAudioPlayer:
    def __init__(self, voice: WindowsVoice | GoogleCloudVoice, directory: Path = DEFAULT_DIRECTORY) -> None:
        self.voice = voice
        self.directory = directory
        self.available = sys.platform == "win32"
        self._lock = threading.Lock()
        self._synth_lock = threading.Lock()
        self._latest_request = 0

    def handle_log_line(self, text: str) -> bool:
        """Reproduce el mensaje si la linea es un anuncio de audio, o lo genera
        por adelantado si es una entrada del catalogo."""
        if not self.available:
            return False
        match = AUDIO_LINE.match(text)
        if match:
            self.play(int(match.group(1)), match.group(2))
            return True
        match = CATALOG_LINE.match(text)
        if match:
            self.preload(int(match.group(1)), match.group(2))
            return True
        return False

    def preload(self, number: int, text: str) -> None:
        """Genera el audio en segundo plano, sin reproducirlo."""
        threading.Thread(target=self._preload, args=(number, text), daemon=True).start()

    def _preload(self, number: int, text: str) -> None:
        try:
            self.prepare(number, text)
        except Exception as exc:
            print(f"[warn] no se pudo generar el audio {number}: {exc}", file=sys.stderr)

    def play(self, number: int, text: str) -> None:
        with self._lock:
            self._latest_request += 1
            request = self._latest_request
        threading.Thread(target=self._prepare_and_play, args=(request, number, text), daemon=True).start()

    def prepare(self, number: int, text: str) -> Path:
        """Genera (si hace falta) el audio del mensaje y devuelve el WAV."""
        wav = self.directory / f"{number:04d}.wav"
        source = wav.with_suffix(".txt")
        signature = f"{self.voice.id}\n{text}"
        with self._synth_lock:
            current = source.read_text(encoding="utf-8") if source.exists() else None
            if not wav.exists() or current != signature:
                self.directory.mkdir(parents=True, exist_ok=True)
                mp3 = self.directory / "mp3" / f"{number:04d}.mp3"
                self.voice.synthesize(text, wav, mp3)
                source.write_text(signature, encoding="utf-8")
        return wav

    def _prepare_and_play(self, request: int, number: int, text: str) -> None:
        try:
            wav = self.prepare(number, text)
        except Exception as exc:  # red, credenciales, PowerShell: el puente sigue igual
            print(f"[warn] no se pudo generar el audio {number}: {exc}", file=sys.stderr)
            return

        with self._lock:
            if request != self._latest_request:
                return  # llego otro mensaje mientras se generaba este: gana el ultimo

        import winsound

        # SND_ASYNC corta lo que este sonando, igual que una orden nueva al DFPlayer.
        winsound.PlaySound(str(wav), winsound.SND_FILENAME | winsound.SND_ASYNC)
        print(f"[audio] {number:04d} {text}")
