import json;
import os;
import plistlib;
import re;
import shlex;
import stat;
import subprocess;
import sys;
import tempfile;
import from dataclasses { dataclass }
import from pathlib { Path }

@dataclass(frozen=True)
class Registration {
    has source: str,
        kind: str,
        original: bytes,
        path: Path | None = None,
        domains: tuple[str, ...] = (),
        label: str = "",
        user: str | None = None,
        retained: bytes = b'';
}

def _run(argv: list[str], *, data: bytes | None = None) -> subprocess.CompletedProcess[bytes] {
    return subprocess.run(
        argv,
        input=data,
        capture_output=True,
        timeout=10,
        check=False,
        env={**dict(os.environ), "LC_ALL": "C"},
    );
}

def _checked(argv: list[str], *, data: bytes | None = None) -> bytes {
    result = _run(argv, data=data);
    if result.returncode {
        raise RuntimeError(f"{' '.join(argv)}: {result.stderr.decode(errors='replace').strip()}");
    }
    return result.stdout;
}

def _is_bridge(argv: list[str]) -> bool {
    if not argv {
        return False;
    }
    executable: str = Path(argv[0]).name;
    if executable in {"sh", "bash", "zsh"} and len(argv) == 3 and (argv[1] in {"-c", "-lc"}) {
        try {
            argv = shlex.split(argv[2]);
        } except ValueError {
            return False;
        }
        executable = Path(argv[0]).name if argv else "";
    }
    if executable != "claude" or len(argv) != 3 or argv[1] not in {"-p", "--print"} {
        return False;
    }
    prompt = argv[2];
    if not prompt.startswith("Run the memU bridging pipeline.")
        or "hosts/claude-code/jobs/" not in prompt
    {
        return False;
    }
    return all(
        (re.search(f"(?<![\\w-])memu-claude-code\\s+{verb}(?=\\s|$)", prompt)
        for verb in ("prepare", "commit")),
    );
}

def _related(text: str) -> bool {
    return any(
        (name in text
        for name in ("memu-claude-code", "memu-remember-claude-code", "memu-bridging-claude-code")),
    );
}

def _read_file(path: Path) -> bytes {
    if path.is_symlink() {
        raise ValueError(f"Refusing scheduler symlink: {path}");
    }
    return path.read_bytes();
}

def _locations -> list[tuple[Path, tuple[str, ...]]] {
    user_domains = (f"gui/{os.getuid()}", f"user/{os.getuid()}");
    return [
        (Path.home() / "Library/LaunchAgents", user_domains),
        (Path("/Library/LaunchAgents"), user_domains),
        (Path("/Library/LaunchDaemons"), ("system",)),
    ];
}

def _cron_users -> tuple[str | None, ...] {
    return (None,) if os.getuid() == 0 else (None, "root");
}

def _system_crontab -> Path {
    return Path("/etc/crontab");
}

def _read_cron(user: str | None) -> bytes {
    argv = ["/usr/bin/crontab", *(["-u", user] if user else []), "-l"];
    result = _run(argv);
    if result.returncode == 1 and b'no crontab for' in result.stderr.lower() {
        return b'';
    }
    if result.returncode {
        raise RuntimeError(f"{' '.join(argv)}: {result.stderr.decode(errors='replace').strip()}");
    }
    return result.stdout;
}

def _select_cron(data: bytes, *, system: bool = False) -> tuple[bytes, int, list[str]] {
    kept: list[bytes] = [];
    matched = 0;
    uncertain: list[str] = [];
    for (number, line) in enumerate(data.splitlines(keepends=True), 1) {
        text = line.decode("utf-8");
        stripped = text.strip();
        if not stripped or stripped.startswith("#") or re.match("[\\w]+\\s*=", stripped) {
            kept.append(line);
            continue;
        }
        fields = stripped.split(None, (1 if stripped.startswith("@") else 5) + int(system));
        command = fields[-1];
        try {
            action = shlex.split(command) if len(fields) > 1 and "%" not in command else [];
        } except ValueError {
            action = [];
        }
        if _is_bridge(action) {
            matched += 1;
        } else {
            kept.append(line);
            if _related(command) {
                uncertain.append(f"line {number}: unrecognized Claude bridge action (preserved)");
            }
        }
    }
    return (b''.join(kept), matched, uncertain);
}

def _plist_registration(path: Path, domains: tuple[str, ...]) -> Registration | None {
    original = _read_file(path);
    config = plistlib.loads(original);
    if not isinstance(config, dict) {
        raise TypeError("Plist root must be a dictionary");
    }
    args: any = config.get("ProgramArguments", []);
    label = config.get("Label", "");
    if not isinstance(args, list) or not all((isinstance(a, str) for a in args)) {
        raise TypeError("ProgramArguments must be strings");
    }
    if config.get("Program") {
        args = [config["Program"], *args[1:]];
    }
    if _is_bridge(args) {
        if not isinstance(label, str) or not label or "/" in label {
            raise ValueError("Invalid launchd label");
        }
        return Registration(str(path), "launchd", original, path, domains, label);
    }
    if _related(str(label) + " " + " ".join(args)) {
        raise ValueError(f"{path}: unrecognized Claude bridge action (preserved)");
    }
    return None;
}

def _inspect_launchd -> tuple[list[Registration], list[str]] {
    registrations: list[Registration] = [];
    errors: list[str] = [];
    for (directory, domains) in _locations() {
        try {
            files = sorted([p for p in directory.iterdir() if p.suffix == ".plist"])
                if directory.exists()
                else [];
            for path in files {
                try {
                    item = _plist_registration(path, domains);
                    if item is not None {
                        registrations.append(item);
                    }
                } except (OSError, ValueError, TypeError, plistlib.InvalidFileException) as exc {
                    errors.append(f"{path}: {exc}");
                }
            }
        } except OSError as exc {
            errors.append(f"{directory}: {exc}");
        }
    }
    return (registrations, errors);
}

def _inspect_system_cron -> tuple[list[Registration], list[str]] {
    path = _system_crontab();
    try {
        if not path.exists() {
            return ([], []);
        }
        original = _read_file(path);
        (retained, count, uncertain) = _select_cron(original, system=True);
        items = [Registration(str(path), "cron-file", original, path=path, retained=retained)]
            if count
            else [];
        return (items, [f"{path}: {message}" for message in uncertain]);
    } except (OSError, ValueError) as exc {
        return ([], [f"{path}: {exc}"]);
    }
}

def inspect -> tuple[list[Registration], list[str]] {
    (registrations, errors) = _inspect_launchd();
    for user in _cron_users() {
        source = f"crontab:{user or 'current-user'}";
        try {
            original = _read_cron(user);
            (retained, count, uncertain) = _select_cron(original);
            errors.extend([f"{source}: {message}" for message in uncertain]);
            if count {
                registrations.append(
                    Registration(source, "crontab", original, user=user, retained=retained)
                );
            }
        } except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc {
            errors.append(f"{source}: {exc}");
        }
    }
    (system_items, system_errors) = _inspect_system_cron();
    return (registrations + system_items, errors + system_errors);
}

def _job(target: str) -> bytes | None {
    result = _run(["/bin/launchctl", "print", target]);
    if result.returncode {
        if result.returncode == 113
            and any(
                (message in result.stderr.lower()
                for message in (b'could not find service', b'could not find domain')),
            )
        {
            return None;
        }
        raise RuntimeError(f"Inspect {target}: {result.stderr.decode(errors='replace').strip()}");
    }
    return result.stdout;
}

def _unload(target: str) {
    if _job(target) is None {
        return;
    }
    _checked(["/bin/launchctl", "disable", target]);
    state = _job(target);
    if state is not None and re.search(b'(?m)^\\s*pid = [1-9][0-9]*\\s*$', state) {
        raise RuntimeError(
            f"{target} is running; future launches disabled. Wait for natural exit and retry."
        );
    }
    if state is not None {
        _checked(["/bin/launchctl", "bootout", target]);
    }
    if _job(target) is not None {
        raise RuntimeError(f"launchd registration remains: {target}");
    }
}

def _remove_launchd(item: Registration) {
    if item.path is not None and item.path.parent == Path("/Library/LaunchAgents") {
        raise RuntimeError(
            "Shared LaunchAgent requires all-user domain verification; preserved for manual cleanup"
        );
    }
    if item.path is None {
        raise ValueError("Expected a scheduler file path");
    }
    if _read_file(item.path) != item.original {
        raise RuntimeError(f"Registration changed; retry: {item.source}");
    }
    for domain in item.domains {
        _unload(f"{domain}/{item.label}");
    }
    if _read_file(item.path) != item.original {
        raise RuntimeError(f"Registration changed; retry: {item.source}");
    }
    item.path.unlink();
    if item.path.exists() {
        raise RuntimeError(f"Plist remains: {item.path}");
    }
}

def _replace_cron_file(item: Registration) {
    if item.path is None {
        raise ValueError("Expected a scheduler file path");
    }
    info = item.path.stat();
    if info.st_uid != os.getuid() {
        raise PermissionError(f"Run as the owner to change {item.path}");
    }
    if _read_file(item.path) != item.original {
        raise RuntimeError(f"Crontab changed; retry: {item.source}");
    }
    (fd, name) = tempfile.mkstemp(dir=item.path.parent, prefix=".memu-cron-");
    try {
        with os.fdopen(fd, "wb") as stream {
            os.fchmod(stream.fileno(), stat.S_IMODE(info.st_mode));
            stream.write(item.retained);
            stream.flush();
            os.fsync(stream.fileno());
        }
        if _read_file(item.path) != item.original {
            raise RuntimeError(f"Crontab changed; retry: {item.source}");
        }
        os.replace(name, item.path);
    } finally {
        Path(name).unlink(missing_ok=True);
    }
    if _read_file(item.path) != item.retained {
        raise RuntimeError(f"Crontab readback differs: {item.source}");
    }
}

def _remove_cron(item: Registration) {
    if _read_cron(item.user) != item.original {
        raise RuntimeError(f"Crontab changed; retry: {item.source}");
    }
    argv = ["/usr/bin/crontab", *(["-u", item.user] if item.user else []), "-"];
    _checked(argv, data=item.retained);
    if _read_cron(item.user) != item.retained {
        raise RuntimeError(f"Crontab readback differs: {item.source}");
    }
}

def _describe(item: Registration) -> dict[str, object] {
    value: dict[str, object] = {"source": item.source, "kind": item.kind};
    if item.kind == "launchd" {
        loaded: list[any] = [];
        running: list[any] = [];
        for domain in item.domains {
            state = _job(f"{domain}/{item.label}");
            if state is not None {
                loaded.append(domain);
                if re.search(b'(?m)^\\s*pid = [1-9][0-9]*\\s*$', state) {
                    running.append(domain);
                }
            }
        }
        value.update(
            label=item.label,
            checked_domains=item.domains,
            loaded_domains=loaded,
            running_domains=running,
        );
    }
    return value;
}

def cleanup(*, remove: bool = False) -> int {
    (registrations, errors) = inspect();
    removed: list[str] = [];
    details: list[dict[str, object]] = [];
    if not remove {
        for item in registrations {
            try {
                details.append(_describe(item));
            } except (OSError, RuntimeError, subprocess.TimeoutExpired) as exc {
                errors.append(f"{item.source}: {exc}");
            }
        }
    }
    if remove {
        for item in registrations {
            try {
                if item.kind == "launchd" {
                    _remove_launchd(item);
                } elif item.kind == "cron-file" {
                    _replace_cron_file(item);
                } else {
                    _remove_cron(item);
                }
                removed.append(item.source);
            } except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc {
                errors.append(f"{item.source}: {exc}");
            }
        }
    }
    print(
        json.dumps({
            "status": "failed"
                if errors
                else "registered" if registrations and (not remove) else "absent",
            "matched": [item.source for item in registrations],
            "removed": removed,
            "registrations": details,
            "errors": errors,
        }),
    );
    for error in errors {
        print(error, file=sys.stderr);
    }
    return int(bool(errors));
}
