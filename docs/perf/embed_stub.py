"""Deterministic OpenAI-compatible /embeddings stub for offline benchmarking.

Each text maps to a fixed unit vector seeded from its SHA-256, so the original
and the Jac build see identical vectors and must rank identically.
"""

import base64
import hashlib
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np

DIM = 256


def vec(text: str) -> np.ndarray:
    seed = int.from_bytes(hashlib.sha256(text.encode("utf-8")).digest()[:8], "little")
    v = np.random.default_rng(seed).standard_normal(DIM).astype(np.float32)
    return v / np.linalg.norm(v)


class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):  # quiet
        pass

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        inputs = body["input"]
        if isinstance(inputs, str):
            inputs = [inputs]
        b64 = body.get("encoding_format") == "base64"
        data = []
        for i, t in enumerate(inputs):
            v = vec(t)
            emb = base64.b64encode(v.tobytes()).decode() if b64 else [float(x) for x in v]
            data.append({"object": "embedding", "index": i, "embedding": emb})
        out = json.dumps({
            "object": "list",
            "data": data,
            "model": body.get("model", "stub"),
            "usage": {"prompt_tokens": 0, "total_tokens": 0},
        }).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
