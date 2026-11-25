import hashlib;

import json;

import from pathlib { Path }

def _hash_file(path: Path) -> str {
    return hashlib.sha256(path.read_bytes()).hexdigest();
}

def _iter_tracked(base_dir: Path, subdirs: list[str]) -> Generator[any, any, any] {
    for subdir in subdirs {
        `root: any = base_dir / subdir;
        if not `root.is_dir() {
            continue;
        }
        for path in sorted(`root.rglob("*")) {
            if path.is_file() {
                yield (path.relative_to(base_dir).as_posix(), path);
            }
        }
    }
}

def snapshot_tracked(base_dir: Path, subdirs: list[str], manifest_path: Path) {
    manifest: any = {key: _hash_file(path) for (key, path) in _iter_tracked(base_dir, subdirs)};
    manifest_path.parent.mkdir(parents=True, exist_ok=True);
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8");
}

def diff_tracked(base_dir: Path, subdirs: list[str], manifest_path: Path) -> list[Path] {
    baseline: any = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest_path.exists()
        else {};

    changed: list[Path] = [];
    for (key, path) in _iter_tracked(base_dir, subdirs) {
        if baseline.get(key) != _hash_file(path) {
            changed.append(path);
        }
    }
    return changed;
}
