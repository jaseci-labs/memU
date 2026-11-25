import os;

import from pathlib { Path, PureWindowsPath }

import from typing { Any }

glob MAX_RESOURCES: any = 50,
     RESOURCE_JOB_TEMPLATE: any = "You are the **resource-describe** pass for an agent's workspace. Your job is to\nannotate a list of files the agent recently touched with short, human-readable\ndescriptions of what each file is.\n\n## Step 1 — build the resource list\n\nRun this command with `bash`:\n\n    {verify_command}\n\nIt reads the raw log of touched files, keeps only the ones that still exist as\nreal files, dedups them, and writes the result to:\n\n    {resource_file}\n\nRead that file. It is a series of `---`-delimited records, each shaped like:\n\n    ---\n    path: <absolute path to a file>\n    description:\n    ---\n\nThe `description:` lines start empty — filling them in is your task.\n\n## Step 2 — describe each file\n\nFor every record, read the file at its `path` (with `bash`, e.g. `cat`) and\nwrite a **one to several sentence** description of what the file is and what it\ncontains onto its `description:` line.\n\nThis is **best-effort**. Put the literal value `null` on the `description:` line\ninstead when the file:\n\n  - cannot be read (permission denied, broken, or gone),\n  - is very large (don't try to read huge files), or\n  - is an unknown, binary, or uncommon format you can't meaningfully summarize.\n\nA `null` description is a perfectly good outcome — do not guess at content you\ncould not actually read.\n\n## Step 3 — write the result back\n\nRewrite `{resource_file}` in place, keeping the exact same `---`-delimited\nstructure and every `path:` line unchanged, with each `description:` line now\nholding either your summary or `null`. Keep each description on a single line.\n",
     max_resources_default_: any;

with entry {
    max_resources_default_ = MAX_RESOURCES;
}

def verify_resource_log(
    log: Path, resource_file: Path, max_resources: int = max_resources_default_
) -> int {
    valid: list[str] = [];
    seen: set[str] = set();

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

def read_resources(resource_file: Path) -> list[dict[str, Any]] {
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

glob template_default_: any;

with entry {
    template_default_ = RESOURCE_JOB_TEMPLATE;
}

def prepare_resource_job(
    job_dir: Path,
    verify_command: str,
    resource_file: Path,
    job_index: int,
    *,
    template: str = template_default_,
) {
    instruction: any = template.format(verify_command=verify_command, resource_file=resource_file);
    job_dir.mkdir(parents=True, exist_ok=True);
    (job_dir / f"{job_index}.txt").write_text(instruction, encoding="utf-8");
}
