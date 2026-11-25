impl PreparedMemorizeRun.init(
    transcript: MaterializedConversation | list[MaterializedConversation], jobs: list[Path]
) {
    transcripts = [transcript] if isinstance(transcript, MaterializedConversation) else transcript;
    if not transcripts {
        raise ValueError("at least one transcript is required");
    }
    builtins.object.__setattr__(self, "transcripts", transcripts);
    builtins.object.__setattr__(self, "jobs", jobs);
}

impl _numeric_path_key(path: Path) -> int {
    return int(path.stem);
}

impl _mirror_recall_files(backend: any, workspace: MemorizeWorkspace) {
    cursor: str | None = None;
    while True {
        result = await backend.list_all_recall_files(cursor=cursor);
        for recall_file in result["recall_files"] {
            subdir = TRACK_DIRS.get(recall_file.get("track"));
            if subdir is not None {
                write_recall_file(workspace.base, subdir, recall_file);
            }
        }
        cursor = result.get("next_cursor");
        if not cursor {
            return;
        }
    }
}

impl prepare_memorize(
    memorize_input: list[MemorizeInput] | MemorizeInput,
    workspace: MemorizeWorkspace,
    backend: any,
    *,
    verify_command: str,
) -> PreparedMemorizeRun {
    memorize_inputs = [memorize_input]
        if isinstance(memorize_input, MemorizeInput)
        else memorize_input;
    if not memorize_inputs {
        raise ValueError("at least one memorize input is required");
    }
    if workspace.active_run.exists() {
        raise RuntimeError("memorize workspace already has an active run");
    }
    workspace.base.mkdir(parents=True, exist_ok=True);
    transcripts = materialize_memorize_inputs(memorize_inputs, workspace.input);
    await _mirror_recall_files(backend, workspace);
    snapshot_tracked(workspace.base, workspace.track_dirs, workspace.manifest);
    workspace.resource_log.unlink(missing_ok=True);
    workspace.resources.unlink(missing_ok=True);
    num_sessions = len(memorize_inputs);
    prepare_instruction_jobs(
        job_dir=workspace.jobs,
        session_dir=workspace.input,
        memory_dir=workspace.memory,
        skill_dir=workspace.skill,
        resource_log=workspace.resource_log,
        num_sessions=num_sessions,
        memory_template=templates.resolve(templates.MEMORY_JOB, MEMORY_JOB_TEMPLATE),
        skill_template=templates.resolve(templates.SKILL_JOB, SKILL_JOB_TEMPLATE),
    );
    prepare_resource_job(
        job_dir=workspace.jobs,
        verify_command=verify_command,
        resource_file=workspace.resources,
        job_index=num_sessions * 2 + 1,
        template=templates.resolve(templates.RESOURCE_JOB, RESOURCE_JOB_TEMPLATE),
    );
    _atomic_write_text(
        workspace.active_run,
        json.dumps({"schema_version": memorize_inputs[0].schema_version}, separators=(",", ":"))
            + "\n",
    );
    jobs = sorted(workspace.jobs.glob("*.txt"), key=_numeric_path_key);
    return PreparedMemorizeRun(transcript=transcripts, jobs=jobs);
}

impl commit_memorize(workspace: MemorizeWorkspace, backend: any) -> dict[str, Any] {
    if not workspace.active_run.is_file() {
        raise RuntimeError("memorize workspace has no active run");
    }
    marker = json.loads(workspace.active_run.read_text(encoding="utf-8"));
    if marker.get("status") == "committed" {
        raise RuntimeError(
            "memorize run already committed; do not resubmit; discard the stopped run"
        );
    }
    subdir_track = {subdir: track for (track, subdir) in TRACK_DIRS.items()};
    changed = diff_tracked(workspace.base, workspace.track_dirs, workspace.manifest);
    recall_files = [
        read_recall_file(path, subdir_track[path.relative_to(workspace.base).parts[0]])
        for path in changed
    ];
    resources = read_resources(workspace.resources);
    result = await backend.commit_results(recall_files=recall_files, resource=resources);
    marker["status"] = "committed";
    try {
        _atomic_write_text(workspace.active_run, json.dumps(marker, separators=(",", ":")) + "\n");
    } except OSError as exc {
        raise RuntimeError(
            f"memorize run committed, but could not persist its committed status at {workspace.base}: {exc}; do not resubmit; discard the stopped run",
        ) from exc;
    }
    try {
        for (path, recall_file) in builtins.zip(changed, recall_files, strict=True) {
            finalize_recall_file(path, recall_file);
        }
        snapshot_tracked(workspace.base, workspace.track_dirs, workspace.manifest);
        for stale in workspace.jobs.glob("*.txt") {
            stale.unlink();
        }
        for stale in workspace.input.glob("*.jsonl") {
            stale.unlink();
        }
        workspace.resource_log.unlink(missing_ok=True);
        workspace.resources.unlink(missing_ok=True);
        workspace.active_run.unlink();
    } except OSError as exc {
        raise RuntimeError(
            f"memorize run committed, but cleanup failed at {workspace.base}: {exc}; do not resubmit; discard the stopped run",
        ) from exc;
    }
    return result;
}
