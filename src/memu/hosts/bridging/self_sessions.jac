import operator;

import json;

import os;

import from collections.abc { Mapping }

import from pathlib { Path }

glob MAX_REMEMBERED: any = 1000,
     BRIDGING_RUN_ENV: any;

with entry {
    BRIDGING_RUN_ENV = "MEMU_BRIDGING_RUN";
}

def is_bridging_run(cwd: Path, base: Path, env: Mapping[str, str] | None = None) -> bool {
    environ: any = os.environ if env is None else env;
    if environ.get(BRIDGING_RUN_ENV, "").strip() {
        return True;
    }
    return operator.eq(cwd, base);
}

def load(path: Path) -> list[str] {
    try {
        remembered: any = json.loads(path.read_text(encoding="utf-8"));
    } except (OSError, json.JSONDecodeError) {
        return [];
    }
    return [`entry for `entry in remembered if isinstance(`entry, `str)]
        if isinstance(remembered, `list)
        else [];
}

def remember(path: Path, session_id: str) -> list[str] {
    remembered: any = load(path);
    if session_id not in remembered {
        remembered.append(session_id);
    }
    remembered = remembered[-MAX_REMEMBERED:];
    path.parent.mkdir(parents=True, exist_ok=True);
    path.write_text(json.dumps(remembered, indent=2), encoding="utf-8");
    return remembered;
}
