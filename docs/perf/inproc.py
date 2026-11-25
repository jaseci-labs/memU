"""In-process library workload: MemoryService on inmemory and sqlite, no HTTP.

Commits the benchmark payload, re-commits it, retrieves 30 (inmemory) / 10 (sqlite) queries, lists all
files. Results (normalized) go to stdout; per-phase seconds to stderr as JSON.
"""

import asyncio
import hashlib
import json
import random
import sys
import tempfile
import time
from pathlib import Path

import numpy as np

from memu.app import MemoryService

DIM = 256
PAYLOAD = json.loads((Path(__file__).parent / "payload.json").read_text(encoding="utf-8"))


def vec(text: str) -> list[float]:
    seed = int.from_bytes(hashlib.sha256(text.encode("utf-8")).digest()[:8], "little")
    v = np.random.default_rng(seed).standard_normal(DIM).astype(np.float32)
    return (v / np.linalg.norm(v)).tolist()


class Fake:
    async def embed(self, inputs: list[str]):
        return [vec(t) for t in inputs], None


def strip(v):
    if isinstance(v, dict):
        return {k: strip(x) for k, x in v.items() if k not in {"id", "created_at", "updated_at", "recall_file_id", "resource_id"}}
    if isinstance(v, list):
        return [strip(x) for x in v]
    if isinstance(v, float):
        return round(v, 6)
    return v


async def workload(db_config, phases, tag, n_queries):
    svc = MemoryService(database_config=db_config)
    svc._embedding_pool._cache["embedding"] = Fake()
    out = {}
    t = time.perf_counter()
    r = await svc.commit_results(recall_files=PAYLOAD["recall_files"], resource=PAYLOAD["resource"])
    phases[f"{tag}.commit"] = time.perf_counter() - t
    out["commit"] = [len(r["recall_files"]), len(r["resources"])]
    t = time.perf_counter()
    r = await svc.commit_results(recall_files=PAYLOAD["recall_files"], resource=PAYLOAD["resource"])
    phases[f"{tag}.recommit"] = time.perf_counter() - t
    out["recommit"] = [len(r["recall_files"]), len(r["resources"])]
    rnd = random.Random(7)
    words = "launch deploy coffee review python rust memory agent latency team design index vector query cache".split()
    queries = [" ".join(rnd.choice(words) for _ in range(5)) for _ in range(n_queries)]
    t = time.perf_counter()
    out["retrieve"] = [strip(await svc.progressive_retrieve(q)) for q in queries]
    phases[f"{tag}.retrieve{n_queries}"] = time.perf_counter() - t
    t = time.perf_counter()
    files, cursor = [], None
    while True:
        page = await svc.list_all_recall_files(cursor=cursor)
        files.extend(page["recall_files"])
        cursor = page.get("next_cursor")
        if not cursor:
            break
    phases[f"{tag}.list"] = time.perf_counter() - t
    out["list"] = strip(files)
    return out


async def main():
    phases = {}
    t0 = time.perf_counter()
    res = {"inmemory": await workload({"metadata_store": {"provider": "inmemory"}}, phases, "inmemory", 30)}
    with tempfile.TemporaryDirectory() as d:
        dsn = f"sqlite:///{d}/m.sqlite3"
        res["sqlite"] = await workload({"metadata_store": {"provider": "sqlite", "dsn": dsn}}, phases, "sqlite", 10)
    phases["total"] = time.perf_counter() - t0
    json.dump(res, sys.stdout, sort_keys=True)
    print(json.dumps(phases), file=sys.stderr)


asyncio.run(main())
