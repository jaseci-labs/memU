impl _split(
    source: TranscriptSource, path: Path, records: list[str]
) -> tuple[list[str], list[str]] {
    messages: list[str] = [];
    full: list[str] = [];
    for record in records {
        kind = source.classify(record);
        if kind is RecordKind.MESSAGE {
            clean = source.sanitize(path, record);
            messages.append(clean);
            full.append(clean);
        } elif kind is RecordKind.TOOL {
            full.append(source.sanitize(path, record));
        }
    }
    return (messages, full);
}

impl _last_timestamp(source: TranscriptSource, records: list[str]) -> str | None {
    for record in reversed(records) {
        if (stamp := source.timestamp(record)) {
            return stamp;
        }
    }
    return None;
}

impl prepare_transcripts(
    source: TranscriptSource,
    out_dir: Path,
    manifest_path: Path,
    max_jobs: int,
    pending_path: Path,
    skip_sessions: Collection[str] = (),
) -> int {
    manifest: any = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest_path.exists()
        else {};
    `skip = set(skip_sessions);
    pending: list[tuple[Path, str, TranscriptRead]] = [];
    observed: dict[str, dict[str, object]] = {};
    stopped_regions: set[str] = set();
    for path in source.discover() {
        region = source.scan_region(path);
        if region in stopped_regions {
            continue;
        }
        if source.session_id(path) in `skip {
            continue;
        }
        key = source.key(path);
        previous = manifest.get(key);
        try {
            read = source.read_incremental(path, previous);
        } except TranscriptReadError as exc {
            logger.warning("skipping unreadable transcript %s: %s", key, exc.cause);
            continue;
        }
        if read.changed
            and (
                not any(
                    (source.classify(record) is not RecordKind.OTHER
                    for record in read.records[read.start:]),
                )
            )
        {
            observed[key] = {
                **read.cursor,
                "last_timestamp": _last_timestamp(source, read.records),
            };
        } elif read.changed and len(pending) < max_jobs {
            pending.append((path, key, read));
        } elif not read.changed and previous is not None {
            stopped_regions.add(region);
        }
    }
    selected = pending[:max_jobs];
    selected.reverse();
    out_dir.mkdir(parents=True, exist_ok=True);
    for stale in out_dir.glob("*.jsonl") {
        stale.unlink();
    }
    for (idx, (path, key, read)) in enumerate(selected, 1) {
        (messages, full) = _split(source, path, read.records[read.start:]);
        (out_dir / f"{idx}.jsonl").write_text("\n".join(messages) + "\n", encoding="utf-8");
        (out_dir / f"{idx}_full.jsonl").write_text("\n".join(full) + "\n", encoding="utf-8");
        manifest[key] = {**read.cursor, "last_timestamp": _last_timestamp(source, read.records)};
    }
    manifest.update(observed);
    pending_path.parent.mkdir(parents=True, exist_ok=True);
    pending_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8");
    return len(selected);
}
