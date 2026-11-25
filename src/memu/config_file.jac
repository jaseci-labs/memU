import contextlib;
import os;
import tempfile;
import from collections.abc { Mapping }
import from pathlib { Path }

def config_path -> Path {
    return Path(os.path.expanduser(os.environ.get("MEMU_CONFIG_ENV", CONFIG_ENV)));
}

def read -> dict[str, str] {
    try {
        (text, _) = read_config(config_path());
    } except OSError {
        return {};
    }
    values: dict[str, str] = {};
    for raw in text.splitlines() {
        (key, value) = _split(raw);
        if key {
            values[key] = value.strip().strip("\"'");
        }
    }
    return values;
}

def write_values(updates: Mapping[str, str], *, comments: str = "") -> tuple[Path, bool] {
    path = config_path();
    path.parent.mkdir(parents=True, exist_ok=True, mode=448);
    try {
        (text, canonical) = read_config(path);
    } except FileNotFoundError {
        (text, canonical) = ("", True);
    }
    merged = _merged(text, dict(updates));
    if comments and comments.splitlines()[0] not in merged.splitlines() {
        merged += comments.rstrip() + "\n";
    }
    if merged == text and canonical and path.is_file() {
        _restrict(path);
        return (path, False);
    }
    (handle_fd, tmp_name) = tempfile.mkstemp(dir=path.parent, prefix=".config.env.");
    tmp = Path(tmp_name);
    try {
        with os.fdopen(handle_fd, "w", encoding="utf-8") as handle {
            handle.write(merged);
        }
        _restrict(tmp);
        os.replace(tmp, path);
    } except BaseException {
        with contextlib.suppress(OSError) {
            tmp.unlink();
        }
        raise;
    }
    return (path, True);
}

def permission_note -> str {
    return "chmod 600" if os.name == "posix" else "plaintext key; Windows ACLs inherited";
}

def _split(raw: str) -> tuple[str, str] {
    line = raw.strip();
    if not line or line.startswith("#") {
        return ("", "");
    }
    (key, sep, value) = line.partition("=");
    return ("", "") if not sep else (key.strip(), value);
}

def _merged(text: str, updates: dict[str, str]) -> str {
    lines = text.splitlines();
    written: set[str] = set();
    out: list[str] = [];
    for raw in lines {
        (key, _) = _split(raw);
        if key and key in updates {
            out.append(f"{key}={updates[key]}");
            written.add(key);
        } else {
            out.append(raw);
        }
    }
    out.extend([f"{key}={value}" for (key, value) in updates.items() if key not in written]);
    return "".join((f"{line}\n" for line in out));
}

def _restrict(path: Path) {
    if os.name != "posix" {
        return;
    }
    with contextlib.suppress(OSError) {
        path.chmod(384);
    }
}
