impl prepare_instruction_jobs(
    job_dir: Path,
    session_dir: Path,
    memory_dir: Path,
    skill_dir: Path,
    resource_log: Path,
    num_sessions: int,
    *,
    memory_template: str = memory_template_default_,
    skill_template: str = skill_template_default_,
) -> None {
    job_dir.mkdir(parents=True, exist_ok=True);
    for stale in job_dir.glob("*.txt") {
        stale.unlink();
    }

    idx: any;
    for idx in range(1, num_sessions + 1) {
        instruction: any = memory_template.format(
            input_path=session_dir / f"{idx}.jsonl", track_dir=memory_dir
        );
        instruction += "\n## Empty memory submissions\n\nTo intentionally clear a memory, keep its name/description frontmatter, add exactly one `empty: true` field there, and leave the body blank. Blank memory bodies without this acknowledgement are rejected. Missing files do not clear the backend. Writing a non-empty body restores normal memory automatically; after a successful commit, any empty marker is removed.\n";
        (job_dir / f"{idx}.txt").write_text(instruction, encoding="utf-8");
    }

    for idx in range(1, num_sessions + 1) {
        instruction = skill_template.format(
            input_path=session_dir / f"{idx}_full.jsonl",
            track_dir=skill_dir,
            resource_log=resource_log,
        );
        (job_dir / f"{num_sessions + idx}.txt").write_text(instruction, encoding="utf-8");
    }
}
