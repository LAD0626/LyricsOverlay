#!/usr/bin/env python3

import json
import socket
import struct
import sys
from typing import Any, Dict, Optional


BRIDGE_TYPE = "playback_update"
TCP_HOST = "127.0.0.1"
TCP_PORT = 61337
SOCKET_TIMEOUT_SECONDS = 1.0


class NativeBridgeForwarder:
    def __init__(self, host: str, port: int) -> None:
        self.host = host
        self.port = port
        self.sock: Optional[socket.socket] = None

    def close(self) -> None:
        if self.sock is not None:
            try:
                self.sock.close()
            except OSError:
                pass
        self.sock = None

    def ensure_connection(self) -> bool:
        if self.sock is not None:
            return True

        try:
            sock = socket.create_connection(
                (self.host, self.port),
                timeout=SOCKET_TIMEOUT_SECONDS
            )
            sock.settimeout(SOCKET_TIMEOUT_SECONDS)
            self.sock = sock
            return True
        except OSError:
            self.close()
            return False

    def forward(self, message: Dict[str, Any]) -> bool:
        if not self.ensure_connection():
            return False

        payload = (json.dumps(message, separators=(",", ":")) + "\n").encode("utf-8")

        try:
            assert self.sock is not None
            self.sock.sendall(payload)
            return True
        except OSError:
            self.close()
            return False


def read_native_message() -> Optional[Dict[str, Any]]:
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        return None

    if len(raw_length) != 4:
        return None

    message_length = struct.unpack("<I", raw_length)[0]
    if message_length <= 0:
        return None

    message_data = sys.stdin.buffer.read(message_length)
    if len(message_data) != message_length:
        return None

    try:
        payload = json.loads(message_data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return {}

    return payload if isinstance(payload, dict) else {}


def is_valid_payload(payload: Dict[str, Any]) -> bool:
    try:
        message_type = payload["type"]
        title = str(payload["title"]).strip()
        artist = str(payload["artist"]).strip()
        current_time = float(payload["currentTime"])
        duration = float(payload["duration"])
        is_playing = payload["isPlaying"]
    except (KeyError, TypeError, ValueError):
        return False

    if message_type != BRIDGE_TYPE:
        return False

    if not title or not artist:
        return False

    if current_time < 0 or duration < 0:
        return False

    if not isinstance(is_playing, bool):
        return False

    return True


def main() -> int:
    forwarder = NativeBridgeForwarder(TCP_HOST, TCP_PORT)

    try:
        while True:
            message = read_native_message()
            if message is None:
                break

            if not message or not is_valid_payload(message):
                continue

            forwarder.forward(message)
    finally:
        forwarder.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
