impl verify_resource_log(
    log: Path, resource_file: Path, max_resources: int = max_resources_default_
) -> int {
    valid: list[str] = [];
    seen: set[str] = set[any]();

    if log.is_file() {
        for raw in log.read_text(encoding="utf-8").splitlines() {
            path: any = raw.strip();
            if path in seen
                or not (path.startswith(("/", "~")) or PureWindowsPath(path).is_absolute())
            {
                continue;
            }
            seen.add(path);
            if os.path.isfile(os.path.expanduser(path)) {
                valid.append(path);
            }
            if len(valid) >= max_resources {
                break;
            }
        }
    }

    records: any = "".join(f"path: {path}\ndescription: \n---\n" for path in valid);
    resource_file.parent.mkdir(parents=True, exist_ok=True);
    resource_file.write_text(f"---\n{records}", encoding="utf-8");
    return len(valid);
}

impl read_resources(resource_file: Path) -> list[dict[str, Any]] {
    if not resource_file.exists() {
        return [];
    }

    records: list[dict[str, Any]] = [];
    path: str | None = None;
    for line in resource_file.read_text(encoding="utf-8").splitlines() {
        key: any;
        sep: any;
        value: any;
        (key, sep, value) = line.partition(":") as any;
        if not sep {
            continue;
        }
        key = key.strip();
        value = value.strip();
        if key == "path" {
            path = value;
        } elif key == "description" {
            if path and value and value.lower() != "null" {
                records.append({"path": path, "description": value});
            }
            path = None;
        }
    }
    return records;
}

impl prepare_resource_job(
    job_dir: Path,
    verify_command: str,
    resource_file: Path,
    job_index: int,
    *,
    template: str = template_default_,
) -> None {
    instruction: any = template.format(verify_command=verify_command, resource_file=resource_file);
    job_dir.mkdir(parents=True, exist_ok=True);
    (job_dir / f"{job_index}.txt").write_text(instruction, encoding="utf-8");
}
