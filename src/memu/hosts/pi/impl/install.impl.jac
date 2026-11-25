impl _command(argv: list[str]) -> int {
    import from memu.hosts.host_cli { build_parser }
    import from memu.hosts.pi.cli { SPEC }
    args = build_parser(SPEC).parse_args(argv);
    return int(await args.handler(args));
}

impl _check_files {
    try {
        hook_install.target();
    } except ValueError {
        raise lifecycle.Blocked("pi 扩展安装位置已有非 memU 文件或链接，请检查归属后重试。") from None;
    }
}

impl _stage(stage: int, args: argparse.Namespace) {
    if stage == 1 {
        executable = shutil.which("pi");
        if not executable {
            raise lifecycle.Blocked("未在 PATH 中找到 pi；请在可运行 pi 的终端中重新安装 memU。");
        }
        _check_files();
        print(text("   pi：{path}", path=executable));
    } elif stage == 2 {
        await lifecycle.backend(args, _command);
    } else {
        lock = hook_install.agent_dir() / ".memu-hooks-lock";
        lock.mkdir(parents=True, exist_ok=True);
        with workspace_lock(lock) as acquired {
            if not acquired {
                raise lifecycle.Blocked("另一个 pi 扩展安装正在运行，请稍后重试。");
            }
            _check_files();
            path = hook_install.install(args.base_dir);
            if path.read_text(encoding="utf-8") != hook_install.extension_content(args.base_dir) {
                raise lifecycle.Failed("pi 扩展回读验证失败，请重新运行安装。");
            }
        }
    }
}

impl run(args: argparse.Namespace) -> int {
    return await lifecycle.run(
        args,
        host="pi",
        stages=STAGES,
        execute=_stage,
        welcome="\n👋  欢迎安装 memU · pi",
        completion={
            "notice": "在 pi 中运行 /reload 或重新打开会话，启用自动检索和后台记忆。",
            "hook_verification": "local_extension_readback",
        },
    );
}

impl register(sub: Any) {
    parser = sub.add_parser("install", help="Configure pi memory hooks in one invocation");
    lifecycle.add_arguments(parser, "pi", install_missing=False);
    parser.set_defaults(handler=run);
}
