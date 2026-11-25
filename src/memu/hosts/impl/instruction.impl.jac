impl begin(binary: str) -> str {
    return BEGIN_TEMPLATE.format(binary=binary);
}

impl _skill_body(skill_text: str) -> str {
    without_frontmatter = re.sub(
        "\\A---\\n.*?\\n---\\n+", "", skill_text, count=1, flags=re.DOTALL
    );
    return re.sub("\\A#[^\\n]*\\n+", "", without_frontmatter, count=1);
}

impl _body(binary: str, skill_text: str | None) -> str {
    body = RETRIEVAL_BODY if skill_text is None else _skill_body(skill_text);
    return body.format(binary=binary);
}

impl skill_document(binary: str, *, skill_text: str | None = None) -> str {
    if skill_text is not None {
        return skill_text.format(binary=binary);
    }
    return SKILL_TEMPLATE.format(name=SKILL_NAME, body=_body(binary, None));
}

impl instruction(binary: str, *, skill: bool = False, skill_text: str | None = None) -> str {
    if binary == "memu-hermes" {
        return HERMES_INSTRUCTION_TEMPLATE.format(body=RETRIEVAL_BODY.format(binary=binary));
    }
    if skill {
        return SKILL_INSTRUCTION_TEMPLATE.format(skill=SKILL_NAME, binary=binary);
    }
    return INSTRUCTION_TEMPLATE.format(body=_body(binary, skill_text));
}

impl block(binary: str, *, skill: bool = False, skill_text: str | None = None) -> str {
    return f"{begin(binary)}\n{instruction(binary, skill=skill, skill_text=skill_text)}{END}\n";
}

impl _block_re(binary: str) -> re.Pattern[str] {
    return re.compile(
        f"^{re.escape(begin(binary))}\\r?\\n.*?^{re.escape(END)}(?:\\r?\\n)?",
        re.DOTALL | re.MULTILINE,
    );
}

impl patch(
    current: str, binary: str, *, skill: bool = False, skill_text: str | None = None
) -> str {
    pattern = _block_re(binary);
    if pattern.search(current) {
        return pattern.sub(
            lambda (_: any) -> any { block(binary, skill=skill, skill_text=skill_text) },
            current,
            count=1,
        );
    }
    if current and (not current.endswith("\n")) {
        current += "\n";
    }
    separator = "\n" if current else "";
    return f"{current}{separator}{block(binary, skill=skill, skill_text=skill_text)}";
}

impl strip(current: str, binary: str) -> str {
    for `match in reversed(list(_block_re(binary).finditer(current))) {
        start = `match.start();
        separator = re.search("(?:\\r?\\n)(\\r?\\n)\\Z", current[:start]);
        if separator {
            start -= len(separator.group(1));
        }
        current = current[:start] + current[`match.end():];
    }
    return current;
}

impl _read_text(path: Path) -> str {
    with path.open(encoding="utf-8", newline="") as handle {
        return handle.read();
    }
}

impl _write(path: Path, updated: str, *, backup: bool, dry_run: bool) -> tuple[bool, str] {
    current = _read_text(path) if path.is_file() else "";
    diff = "".join(
        difflib.unified_diff(
            current.splitlines(keepends=True),
            updated.splitlines(keepends=True),
            fromfile=str(path),
            tofile=str(path),
        ),
    );
    if updated == current or dry_run {
        return (False, diff);
    }
    target = path.resolve() if path.is_symlink() else path;
    target.parent.mkdir(parents=True, exist_ok=True);
    if backup and current {
        shutil.copyfile(path, path.with_suffix(path.suffix + ".bak"));
    }
    (fd, temporary_name) = tempfile.mkstemp(
        dir=target.parent, prefix=".tmp-", suffix=target.suffix
    );
    temporary = Path(temporary_name);
    try {
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle {
            handle.write(updated);
        }
        if target.exists() {
            shutil.copymode(target, temporary);
        }
        temporary.replace(target);
    } finally {
        temporary.unlink(missing_ok=True);
    }
    return (True, diff);
}

impl install(
    path: Path,
    binary: str,
    *,
    skill: bool = False,
    skill_text: str | None = None,
    dry_run: bool = False,
) -> tuple[bool, str] {
    path = path.expanduser();
    current = _read_text(path) if path.is_file() else "";
    return _write(
        path,
        patch(current, binary, skill=skill, skill_text=skill_text),
        backup=True,
        dry_run=dry_run,
    );
}

impl remove(path: Path, binary: str, *, dry_run: bool = False) -> tuple[bool, str] {
    path = path.expanduser();
    if not path.is_file() {
        return (False, "");
    }
    current = _read_text(path);
    return _write(path, strip(current, binary), backup=True, dry_run=dry_run);
}

impl skill_path(skills_dir: Path) -> Path {
    return skills_dir.expanduser() / SKILL_NAME / "SKILL.md";
}

impl install_skill(
    skills_dir: Path, binary: str, *, skill_text: str | None = None, dry_run: bool = False
) -> tuple[bool, str] {
    target = skill_path(skills_dir);
    receipt = target.with_name(".memu-owned.json");
    if receipt.is_symlink() or (receipt.exists() and (not receipt.is_file())) {
        raise ValueError(f"Retrieval skill ownership record is not a regular file: {receipt}");
    }
    document = skill_document(binary, skill_text=skill_text).replace("\r\n", "\n").replace(
        "\r", "\n"
    );
    result = _write(target, document, backup=False, dry_run=dry_run);
    record = json.dumps({
        "binary": binary,
        "sha256": hashlib.sha256(document.encode("utf-8")).hexdigest(),
    })
        + "\n";
    _write(receipt, record, backup=False, dry_run=dry_run);
    return result;
}

impl _check_skill_content(target: Path, binary: str, *, recorded: bool) {
    document = target.read_text(encoding="utf-8");
    if not recorded {
        if document != skill_document(binary) {
            message = f"Unrecorded retrieval skill differs from the packaged version; preserved for ownership review: {target}";
            raise ValueError(message);
        }
        return;
    }
    receipt = target.with_name(".memu-owned.json");
    try {
        record = json.loads(receipt.read_text(encoding="utf-8"));
    } except ValueError as exc {
        raise ValueError(
            f"Invalid retrieval skill ownership record; files preserved: {receipt}"
        ) from exc;
    }
    digest = hashlib.sha256(document.encode("utf-8")).hexdigest();
    if not isinstance(record, dict)
        or record.get("binary") != binary
        or record.get("sha256") != digest
    {
        raise ValueError(
            f"Retrieval skill differs from its ownership record; files preserved: {target}"
        );
    }
}

impl check_skill_cleanup(skills_dir: Path, binary: str) -> bool {
    target = skill_path(skills_dir);
    directory = target.parent;
    try {
        for path in (skills_dir.expanduser(), directory) {
            try {
                `entry = path.lstat();
            } except FileNotFoundError {
                return False;
            }
            if not stat.S_ISDIR(`entry.st_mode) or getattr(`entry, "st_reparse_tag", False) {
                raise ValueError(
                    "Retrieval skill contains links or non-directory paths; preserved for ownership review.",
                );
            }
        }
        receipt = directory / ".memu-owned.json";
        entries = set(directory.iterdir());
        if entries not in ({target}, {target, receipt}) {
            raise ValueError(
                "Retrieval skill has extra or unrecognized entries; preserved for ownership review."
            );
        }
        for file in entries {
            `entry = file.lstat();
            if not stat.S_ISREG(`entry.st_mode) or getattr(`entry, "st_reparse_tag", False) {
                raise ValueError(
                    "Retrieval skill contains links or non-file entries; preserved for ownership review.",
                );
            }
        }
        _check_skill_content(target, binary, recorded=receipt in entries);
    } except (OSError, UnicodeError) as exc {
        raise ValueError(
            "Cannot verify retrieval skill ownership; files preserved. Check access and file encoding.",
        ) from exc;
    }
    return True;
}

impl remove_skill(skills_dir: Path, binary: str, *, dry_run: bool = False) -> tuple[bool, str] {
    if not check_skill_cleanup(skills_dir, binary) {
        return (False, "");
    }
    directory = skill_path(skills_dir).parent;
    diff = f"removed {directory}/\n";
    if dry_run {
        return (False, diff);
    }
    shutil.rmtree(directory);
    return (True, diff);
}

impl refresh(
    path: Path, binary: str, *, skills_dir: Path | None = None
) -> list[tuple[Path, bool]] {
    skill_text = None if binary == "memu-hermes" else templates.fetch(templates.RETRIEVAL_SKILL);
    if skill_text is None and binary != "memu-hermes" {
        return [];
    }
    if skills_dir is not None {
        target = skill_path(skills_dir);
        if not target.is_file() {
            return [];
        }
        (changed, _) = install_skill(skills_dir, binary, skill_text=skill_text);
        return [(target, changed)];
    }
    target = path.expanduser();
    if not target.is_file() or not _block_re(binary).search(target.read_text(encoding="utf-8")) {
        return [];
    }
    (changed, _) = install(path, binary, skill=False, skill_text=skill_text);
    return [(target, changed)];
}

impl _report(path: Path, changed: bool, diff: str, *, dry_run: bool) {
    if not diff {
        print(f"{path}: already up to date");
    } elif dry_run {
        print(f"{path}: would change\n\n{diff}", end="");
    } else {
        print(f"{path}: {'updated' if changed else 'unchanged'}\n\n{diff}", end="");
    }
}

impl _cmd_install_instruction(args: argparse.Namespace) -> int {
    skills_dir = Path(args.skills_dir) if args.skills_dir else None;
    skill = skills_dir is not None;
    if args.binary == "memu-hermes" and skills_dir is not None {
        raise ValueError(
            "Hermes retrieval instructions belong inline in SOUL.md; omit --skills-dir"
        );
    }
    skill_text = None
        if args.binary == "memu-hermes"
        else templates.fetch(templates.RETRIEVAL_SKILL);
    if args.print_only {
        if skills_dir is not None {
            print(
                f"# {skill_path(skills_dir)}\n\n{skill_document(args.binary, skill_text=skill_text)}",
            );
        }
        print(block(args.binary, skill=skill, skill_text=skill_text), end="");
        return 0;
    }
    if skills_dir is not None {
        (changed, diff) = install_skill(
            skills_dir, args.binary, skill_text=skill_text, dry_run=args.dry_run
        );
        _report(skill_path(skills_dir), changed, diff, dry_run=args.dry_run);
    }
    path = Path(args.path);
    (changed, diff) = install(
        path, args.binary, skill=skill, skill_text=skill_text, dry_run=args.dry_run
    );
    _report(path.expanduser(), changed, diff, dry_run=args.dry_run);
    if args.path == args.default_instruction_path {
        if args.binary == "memu-hermes" {
            legacy_skills = path.expanduser().parent / "skills";
            (changed, diff) = remove_skill(legacy_skills, args.binary, dry_run=args.dry_run);
            _report(skill_path(legacy_skills), changed, diff, dry_run=args.dry_run);
        }
        for legacy_text in args.legacy_paths {
            legacy = Path(legacy_text);
            if legacy.expanduser() == path.expanduser() {
                continue;
            }
            (legacy_changed, legacy_diff) = remove(legacy, args.binary, dry_run=args.dry_run);
            if legacy_diff {
                _report(legacy.expanduser(), legacy_changed, legacy_diff, dry_run=args.dry_run);
            }
        }
    }
    return 0;
}

impl cleanup(
    paths: Iterable[Path], binary: str, *, skills_dir: Path | None = None, dry_run: bool = False
) -> list[tuple[Path, bool, str]] {
    if skills_dir is not None {
        check_skill_cleanup(skills_dir, binary);
    }
    results: list[any] = [];
    seen: set[Path] = set();
    for path in paths {
        expanded = path.expanduser();
        if expanded in seen {
            continue;
        }
        seen.add(expanded);
        (changed, diff) = remove(expanded, binary, dry_run=dry_run);
        if diff {
            results.append((expanded, changed, diff));
        }
    }
    if skills_dir is not None {
        (changed, diff) = remove_skill(skills_dir, binary, dry_run=dry_run);
        if diff {
            results.append((skill_path(skills_dir), changed, diff));
        }
    }
    return results;
}

impl _cmd_remove_instruction(args: argparse.Namespace) -> int {
    paths = [Path(args.path)];
    if args.path == args.default_instruction_path {
        paths.extend([Path(path) for path in args.legacy_paths]);
    }
    skills_dir = Path(args.skills_dir)
        if args.skills_dir
            and (args.binary != "memu-hermes" or args.path == args.default_instruction_path)
        else None;
    results = cleanup(paths, args.binary, skills_dir=skills_dir, dry_run=args.dry_run);
    for (path, changed, diff) in results {
        _report(path, changed, diff, dry_run=args.dry_run);
    }
    if not results {
        print(f"{Path(args.path)}: no managed artifacts to remove");
    }
    return 0;
}

impl _cmd_install_instruction_async(args: argparse.Namespace) -> int {
    return _cmd_install_instruction(args);
}

impl _cmd_remove_instruction_async(args: argparse.Namespace) -> int {
    return _cmd_remove_instruction(args);
}

impl register(
    sub: Any, *, path: str, binary: str, skills_dir: str = "", legacy_paths: tuple[str, ...] = ()
) {
    parser = sub.add_parser(
        "install-instruction",
        help="Patch SOUL.md with on-demand memory retrieval"
            if binary == "memu-hermes"
            else "Patch the host's global instruction file so the agent retrieves before answering",
    );
    parser.add_argument(
        "--path", default=path, help=f"Instruction file to patch (default: {path})"
    );
    parser.add_argument(
        "--skills-dir",
        default=skills_dir,
        help=f"Skills directory to install the {SKILL_NAME} skill into (default: {skills_dir})"
            if skills_dir
            else argparse.SUPPRESS,
    );
    parser.add_argument("--dry-run", action="store_true", help="Show the diff without writing");
    parser.add_argument(
        "--print",
        dest="print_only",
        action="store_true",
        help="Print what would be installed and exit",
    );
    parser.set_defaults(
        handler=_cmd_install_instruction_async,
        binary=binary,
        default_instruction_path=path,
        legacy_paths=legacy_paths,
    );
    remover = sub.add_parser(
        "remove-instruction",
        help="Remove memU's managed block from the host's global instruction file — and, on a skill host, its verified retrieval skill; user edits, extra files and links block cleanup",
    );
    remover.add_argument(
        "--path", default=path, help=f"Instruction file to unpatch (default: {path})"
    );
    remover.add_argument(
        "--skills-dir",
        default=skills_dir,
        help=f"Skills directory the {SKILL_NAME} skill was installed into (default: {skills_dir})"
            if skills_dir
            else argparse.SUPPRESS,
    );
    remover.add_argument("--dry-run", action="store_true", help="Show the diff without writing");
    remover.set_defaults(
        handler=_cmd_remove_instruction_async,
        binary=binary,
        default_instruction_path=path,
        legacy_paths=legacy_paths,
    );
}
