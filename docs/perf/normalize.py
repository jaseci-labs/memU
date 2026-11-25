"""Normalize CLI output for cross-implementation comparison.

Drops per-run values (uuids, timestamps, the ids that point at them) and rounds
scores to 6 places; everything else (texts, order, counts, scores) must match.
"""

import json
import re
import sys

VOLATILE = {"id", "created_at", "updated_at", "recall_file_id", "resource_id", "run_id", "workspace"}
UUID = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")


def walk(v):
    if isinstance(v, dict):
        return {k: walk(x) for k, x in v.items() if k not in VOLATILE}
    if isinstance(v, list):
        return [walk(x) for x in v]
    if isinstance(v, float):
        return round(v, 6)
    if isinstance(v, str):
        return UUID.sub("<uuid>", v)
    return v


raw = open(sys.argv[1], encoding="utf-8").read()
try:
    print(json.dumps(walk(json.loads(raw)), indent=1, sort_keys=True, ensure_ascii=False))
except json.JSONDecodeError:
    print(UUID.sub("<uuid>", raw))
