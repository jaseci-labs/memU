impl _atomic_write_text(path: Path, text: str) -> None {
    fd: any;
    tmp: any;
    (fd, tmp) = tempfile.mkstemp(dir=`str(path.parent), prefix=".tmp-", suffix=path.suffix) as any;
    try {
        handle: any;
        with os.fdopen(fd, "w", encoding="utf-8") as handle {
            handle.write(text);
        }
        os.replace(tmp, path);
    } except BaseException {
        with contextlib.suppress(OSError) {
            os.unlink(tmp);
        }
        raise;
    }
}

impl recall_file_path(base_dir: Path, subdir: str, name: str) -> Path {
    return base_dir / subdir / (format(name.replace(" ", "-"), "") + ".md");
}

impl write_recall_file(base_dir: Path, subdir: str, recall_file: dict[str, Any]) -> Path | None {
    name: any = recall_file["name"];
    description: any = recall_file.get("description", "");
    content: any = recall_file.get("content") or "";

    out_path: any = recall_file_path(base_dir, subdir, name);
    if subdir == "memory" and not content.strip() {
        out_path.unlink(missing_ok=True);
        return None;
    }

    out_dir: any = base_dir / subdir;
    out_dir.mkdir(parents=True, exist_ok=True);

    _atomic_write_text(out_path, f"---\nname: {name}\ndescription: {description}\n---\n{content}");
    return out_path;
}

impl read_recall_file(path: Path, track: str) -> dict[str, Any] {
    text: any = path.read_text(encoding="utf-8");
    empty_markers: list[str] = [];
    name: any = "";
    description: any = "";
    content: any = text;
    if text.startswith("---\n") {
        _: any;
        frontmatter: any;
        (_, frontmatter, content) = re.split(
            "^---\\n", text, maxsplit=2, flags=re.MULTILINE
        ) as any;
        for line in frontmatter.splitlines() {
            key: any;
            sep: any;
            value: any;
            (key, sep, value) = line.partition(":") as any;
            if not sep {
                continue;
            }
            if key.strip() == "name" {
                name = value.strip();
            } elif key.strip() == "description" {
                description = value.strip();
            } elif key.strip() == "empty" {
                empty_markers.append(value.strip());
            }
        }
    }
    if not name {
        msg: any = f"recall file {path.name!r} requires a non-empty name in frontmatter";
        raise ValueError(msg);
    }
    if track == "memory" and not content.strip() and empty_markers != ["true"] {
        msg = f"recall file {path.name!r} requires empty: true in frontmatter to submit an empty memory body";
        raise ValueError(msg);
    }
    return {"name": name, "track": track, "description": description, "content": content};
}

impl finalize_recall_file(path: Path, recall_file: dict[str, Any]) -> None {
    if recall_file["track"] != "memory" {
        return;
    }
    if not recall_file["content"].strip() {
        path.unlink(missing_ok=True);
        return;
    }
    text: any = path.read_text(encoding="utf-8");
    _: any;
    frontmatter: any;
    content: any;
    (_, frontmatter, content) = re.split("^---\\n", text, maxsplit=2, flags=re.MULTILINE) as any;
    cleaned: any = re.sub("^[ \\t]*empty[ \\t]*:[^\\n]*\\n?", "", frontmatter, flags=re.MULTILINE);
    if cleaned != frontmatter {
        _atomic_write_text(path, f"---\n{cleaned}---\n{content}");
    }
}
