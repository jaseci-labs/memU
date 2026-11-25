import math;

import re;

import time;

import from pathlib { Path }

import from typing { Any }

def memorize_status(path: Path) -> dict[str, Any] {
    `entry: dict[str, Any] = {"status": "worker_started", "log": `str(path)};
    stream: any;
    with path.open(encoding="utf-8", errors="replace") as stream {
        for line in stream {
            if `match := re.fullmatch(
                "(?:\\[[^\\]\\r\\n]+\\] )?=== MEMORIZE status=(started|busy|cooldown|succeeded|failed) ===\\s*",
                line,
            ) {
                `entry["status"] = `match[1];
            } elif `match := re.fullmatch("=== COOLDOWN until=(\\d+(?:\\.\\d+)?) ===\\s*", line) {
                until: any = `float(`match[1]);
                if math.isfinite(until) {
                    `entry["cooldown_until"] = until;
                }
            }
        }
    }
    if `entry["status"] == "cooldown" and "cooldown_until" in `entry {
        `entry["cooldown_remaining_minutes"] = math.ceil(
            max(0, `entry["cooldown_until"] - time.time()) / 60
        );
    }
    return `entry;
}
