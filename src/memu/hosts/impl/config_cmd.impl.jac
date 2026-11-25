impl _row(label: str, value: str) {
    print(f"{label:<10}{value}");
}

impl _declared_mode(values: dict[str, str]) -> str {
    raw = values.get("MEMU_MEMORY_MODE", "").strip().lower();
    return raw if raw in ("local", "cloud") else "";
}

impl _effective_mode(values: dict[str, str]) -> str {
    return _declared_mode(values) or "local";
}

impl _protection(values: dict[str, str]) -> str | None {
    if _effective_mode(values) == "cloud" {
        if values.get("MEMU_CLOUD_API_KEY") {
            return "a memU Cloud key is already stored";
        }
        return None;
    }
    if values.get("MEMU_DB") {
        return "a local store is already configured (MEMU_DB)";
    }
    return None;
}

impl _client_id(values: dict[str, str]) -> tuple[dict[str, str], str, bool] {
    existing = values.get("MEMU_CLIENT_ID", "");
    if existing {
        return ({}, existing, False);
    }
    generated = str(uuid.uuid4());
    return ({"MEMU_CLIENT_ID": generated}, generated, True);
}

impl _short(client_id: str) -> str {
    return f"{client_id[:4]}…" if len(client_id) > 4 else client_id;
}

impl _write(updates: dict[str, str]) {
    (path, _) = config_file.write_values(updates, comments=_RETRIEVAL_CONFIG_COMMENTS);
    env_module.reload();
    _row("config", f"{path} ({config_file.permission_note()})");
}

impl _report_install_started(args: argparse.Namespace) {
    events.record(
        events.CLI_INSTALL_STARTED,
        host=getattr(args, "host", ""),
        session_id_env=getattr(args, "session_id_env", ""),
    );
    events.flush();
}

impl _cmd_init(args: argparse.Namespace) -> int {
    values = config_file.read();
    declared = _declared_mode(values);
    (updates, client_id, generated) = _client_id(values);
    if not args.cloud_api_key {
        if not declared {
            updates["MEMU_MEMORY_MODE"] = "local";
        }
        if declared {
            _row("mode", f"{declared} (kept)");
        } elif values.get("MEMU_DB") {
            _row("mode", "local (recorded; the existing store is unchanged)");
        } else {
            _row("mode", "local (default; no store configured yet)");
        }
        _row("client", f"{_short(client_id)}{' (generated)' if generated else ''}");
        _write(updates);
        _report_install_started(args);
        print(f"ready — continue with `{args.binary} docs install`");
        return 0;
    }
    orphaned = _protection(values) if _effective_mode(values) != "cloud" else None;
    stored = values.get("MEMU_CLOUD_API_KEY", "");
    replacing = bool(stored) and stored != args.cloud_api_key;
    updates["MEMU_MEMORY_MODE"] = "cloud";
    updates["MEMU_CLOUD_API_KEY"] = args.cloud_api_key;
    _row("mode", "cloud (from --cloud-api-key)");
    if orphaned {
        _row("switched", f"{orphaned} and is no longer read");
    }
    _row("key", "replaced — the previously stored memU Cloud key is gone" if replacing else "set");
    _row("client", f"{_short(client_id)}{' (generated)' if generated else ''}");
    _write(updates);
    if orphaned {
        sys.stdout.flush();
        print(
            "warning: this machine was in local mode with a store configured. Nothing was deleted, but memories written there are not visible to cloud memory, and new ones now go to the cloud account this key belongs to.",
            file=sys.stderr,
        );
        print(f"To go back: `{args.binary} config --local --force`", file=sys.stderr);
    }
    _report_install_started(args);
    print(f"ready — continue with `{args.binary} docs install`");
    return 0;
}

impl _refuse_flip(values: dict[str, str], target: str, binary: str) -> int | None {
    if _effective_mode(values) == target {
        return None;
    }
    why = _protection(values);
    if why is None {
        return None;
    }
    print(
        f"error: {why}, so switching this machine to {target} memory is refused. Record and retrieval must agree on one backend, or retrieval silently finds nothing.",
        file=sys.stderr,
    );
    print(
        f"If you mean to switch anyway, re-run with --force (`{binary} config --{target} … --force`).",
        file=sys.stderr,
    );
    return REFUSED;
}

impl _refuse_identity(values: dict[str, str], updates: dict[str, str]) -> int | None {
    for key in IDENTITY_KEYS {
        new = updates.get(key);
        old = values.get(key, "");
        if new is None or not old or new == old {
            continue;
        }
        print(
            f"error: {key} is already set on this machine, and changing it strands every vector already written against it — retrieval keeps succeeding and finds nothing.",
            file=sys.stderr,
        );
        print(
            "Repair the connection, never the identity. Re-run with --force only if the store is genuinely being replaced.",
            file=sys.stderr,
        );
        return REFUSED;
    }
    return None;
}

impl _cmd_config(args: argparse.Namespace) -> int {
    if args.show {
        return _show();
    }
    if not args.cloud and (not args.local) {
        print("error: `config` needs --cloud or --local.", file=sys.stderr);
        print(
            f"To read the configuration without writing anything: `{args.binary} config show`",
            file=sys.stderr,
        );
        return REFUSED;
    }
    values = config_file.read();
    target = "cloud" if args.cloud else "local";
    if not args.force {
        refused = _refuse_flip(values, target, args.binary);
        if refused is not None {
            return refused;
        }
    }
    updates = _updates_for(target, args);
    if not args.force {
        refused = _refuse_identity(values, updates);
        if refused is not None {
            return refused;
        }
    }
    updates.update(_client_id(values)[0]);
    _row("mode", target + (" (forced)" if args.force else ""));
    _report_backend(target, values, updates);
    _write(updates);
    print(f"ready — verify with `{args.binary} doctor`");
    return 0;
}

impl _updates_for(target: str, args: argparse.Namespace) -> dict[str, str] {
    updates: dict[str, str] = {"MEMU_MEMORY_MODE": target};
    if target == "cloud" {
        _collect(updates, args, (("cloud_api_key", "MEMU_CLOUD_API_KEY"),));
        import from memu.cloud { DEFAULT_CLOUD_BASE_URL }
        if args.cloud_base_url and args.cloud_base_url != DEFAULT_CLOUD_BASE_URL {
            updates["MEMU_CLOUD_BASE_URL"] = args.cloud_base_url;
        }
        return updates;
    }
    _collect(
        updates,
        args,
        (
            ("db", "MEMU_DB"),
            ("embed_provider", "MEMU_EMBED_PROVIDER"),
            ("embed_model", "MEMU_EMBED_MODEL"),
            ("embed_api_key", "MEMU_API_KEY"),
            ("embed_base_url", "MEMU_BASE_URL"),
        ),
    );
    return updates;
}

impl _report_backend(target: str, values: dict[str, str], updates: dict[str, str]) {
    if target == "local" {
        _row(
            "store",
            updates.get("MEMU_DB")
                or values.get("MEMU_DB")
                or "unset — set one with --db before `doctor`",
        );
        return;
    }
    (stored, new) = (values.get("MEMU_CLOUD_API_KEY", ""), updates.get("MEMU_CLOUD_API_KEY", ""));
    if new and stored and (new != stored) {
        _row("key", "replaced — the previously stored memU Cloud key is gone");
    } elif new or stored {
        _row("key", "set");
    } else {
        _row("key", "unset — cloud memory needs one; `doctor` will fail until it is set");
    }
}

impl _collect(
    updates: dict[str, str], args: argparse.Namespace, pairs: tuple[tuple[str, str], ...]
) {
    for (attr, key) in pairs {
        value = getattr(args, attr, None);
        if value {
            updates[key] = value;
        }
    }
}

impl _show -> int {
    path = config_file.config_path();
    values = config_file.read();
    if not path.is_file() {
        _row("config", f"{path} (not created yet)");
        _row("mode", "local (default; nothing configured)");
        return 0;
    }
    _row("config", str(path));
    declared = _declared_mode(values);
    _row("mode", declared or "local (undeclared; local for backward compatibility)");
    if _effective_mode(values) == "cloud" {
        _row("key", "set" if values.get("MEMU_CLOUD_API_KEY") else "unset");
        _row("endpoint", values.get("MEMU_CLOUD_BASE_URL") or "default");
    } else {
        _row("store", values.get("MEMU_DB") or "unset");
        _row(
            "provider",
            values.get("MEMU_EMBED_PROVIDER")
                or values.get("MEMU_LLM_PROVIDER")
                or "openai (default)",
        );
        _row("model", values.get("MEMU_EMBED_MODEL") or "provider default");
        _row("embed key", "set" if values.get("MEMU_API_KEY") else "unset");
    }
    _row("client", _short(values.get("MEMU_CLIENT_ID", "")) or "unset");
    shadowed = sorted(
        (key
        for key in (
            "MEMU_MEMORY_MODE",
            "MEMU_DB",
            "MEMU_CLOUD_API_KEY",
            "MEMU_EMBED_PROVIDER",
            "MEMU_EMBED_MODEL",
        )
        if os.environ.get(key) and os.environ[key] != values.get(key)),
    );
    if shadowed {
        print(f"note: the environment overrides what this file says for {', '.join(shadowed)}");
    }
    return 0;
}

impl register(sub: Any, *, binary: str, host: str = "", session_id_env: str = "") {
    initialiser = sub.add_parser(
        "init",
        help="Create or update ~/.memu/config.env — the one command SKILL.md names before `docs install`",
    );
    initialiser.add_argument(
        "--cloud-api-key",
        default="",
        help="The user's memU Cloud key. Providing one selects cloud memory; omit it to keep or default the mode",
    );
    initialiser.set_defaults(
        handler=_cmd_init, binary=binary, host=host, session_id_env=session_id_env
    );
    configure = sub.add_parser(
        "config",
        help="Set the memory backend explicitly in ~/.memu/config.env, or `config show` to read it",
    );
    configure.add_argument(
        "show",
        nargs="?",
        choices=("show",),
        help="Print the declared configuration and exit, writing nothing",
    );
    mode = configure.add_mutually_exclusive_group();
    mode.add_argument("--cloud", action="store_true", help="Select memU Cloud memory");
    mode.add_argument("--local", action="store_true", help="Select local memory on this device");
    configure.add_argument("--cloud-api-key", default="", help="memU Cloud key (cloud mode)");
    configure.add_argument(
        "--cloud-base-url", default="", help="Override the memU Cloud endpoint (cloud mode)"
    );
    configure.add_argument(
        "--db", default="", help="Local store: an absolute path, a sqlite:// or a postgres:// DSN"
    );
    configure.add_argument(
        "--embed-provider", default="", help="Embedding provider id (openai, jina, voyage, …)"
    );
    configure.add_argument("--embed-model", default="", help="Embedding model id");
    configure.add_argument(
        "--embed-api-key", default="", help="Embedding provider credential (MEMU_API_KEY)"
    );
    configure.add_argument(
        "--embed-base-url",
        default="",
        help="Embedding endpoint, e.g. a local OpenAI-compatible server",
    );
    configure.add_argument(
        "--force",
        action="store_true",
        help="Override the one-backend guard. Only when the store is genuinely being replaced",
    );
    configure.set_defaults(handler=_cmd_config, binary=binary);
}
