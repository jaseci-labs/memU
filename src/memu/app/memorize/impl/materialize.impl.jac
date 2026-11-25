impl _dump_item(item: SkillInputItem) -> dict[str, JsonValue] {
    optional_none = {
        name
        for (name, field) in type(item).model_fields.items()
        if getattr(item, name) is None and field.default is None
    };
    return item.model_dump(mode="json", exclude=optional_none);
}

impl _serialize_items(items: Sequence[SkillInputItem]) -> str {
    return "".join(
        (json.dumps(_dump_item(item), ensure_ascii=False, separators=(",", ":")) + "\n"
        for item in items),
    );
}

impl _atomic_write_text(path: Path, content: str) {
    (fd, temporary_name) = tempfile.mkstemp(dir=path.parent, prefix=".tmp-", suffix=path.suffix);
    try {
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle {
            handle.write(content);
        }
        os.replace(temporary_name, path);
    } except BaseException {
        with contextlib.suppress(OSError) {
            os.unlink(temporary_name);
        }
        raise;
    }
}

impl materialize_memorize_input(
    memorize_input: MemorizeInput, out_dir: Path, *, session_index: int = 1, clear: bool = True
) -> MaterializedConversation {
    out_dir.mkdir(parents=True, exist_ok=True);
    if clear {
        for stale in out_dir.glob("*.jsonl") {
            stale.unlink();
        }
    }
    memory_path = out_dir / f"{session_index}.jsonl";
    skill_path = out_dir / f"{session_index}_full.jsonl";
    _atomic_write_text(memory_path, _serialize_items(project_memory(memorize_input)));
    _atomic_write_text(skill_path, _serialize_items(project_skill(memorize_input)));
    return MaterializedConversation(memory_path=memory_path, skill_path=skill_path);
}

impl materialize_memorize_inputs(
    memorize_inputs: Sequence[MemorizeInput], out_dir: Path
) -> list[MaterializedConversation] {
    return [
        materialize_memorize_input(item, out_dir, session_index=index, clear=index == 1)
        for (index, item) in enumerate(memorize_inputs, 1)
    ];
}
