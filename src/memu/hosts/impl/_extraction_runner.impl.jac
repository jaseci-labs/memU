impl _owner_exited(lifetime_fd: int, timeout: float = 0) -> bool {
    readable: any;
    _: any;
    (readable, _, _) = select.select([lifetime_fd], [], [], timeout) as any;
    return `bool(readable) and not os.read(lifetime_fd, 1);
}

impl _read_command(lifetime_fd: int) -> list[str] | None {
    input_fd: any = sys.stdin.fileno();
    header: any = bytearray();
    while True {
        if lifetime_fd >= 0 {
            readable: any;
            _: any;
            (readable, _, _) = select.select([input_fd, lifetime_fd], [], []) as any;
            if lifetime_fd in readable and not os.read(lifetime_fd, 1) {
                return None;
            }
            if input_fd not in readable {
                continue;
            }
        }
        character: any = os.read(input_fd, 1);
        if not character {
            msg: any = "Incomplete extraction command header";
            raise ValueError(msg);
        }
        if character == b"\n" {
            break;
        }
        header.extend(character);
    }
    command: any = json.loads(header.decode("ascii"));
    if not isinstance(command, `list)
        or not command
        or `any(not isinstance(part, `str) for part in command)
    {
        msg = "Extraction command must be a nonempty JSON array of strings";
        raise ValueError(msg);
    }
    return command;
}

impl _group_has_only_zombies(group_id: int) -> bool {
    columns: any;
    result: any = subprocess.run(
        ["/bin/ps", "-axo", "pgid=,stat="],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        timeout=1,
        check=False,
    );
    if result.returncode {
        return False;
    }
    states: any = [
        columns[1]
        for line in result.stdout.splitlines()
        if len(columns := line.split()) == 2 and columns[0] == `str(group_id).encode("ascii")
    ];
    return all(state.startswith(b"Z") for state in states);
}

import from jaclang.comptime { target }

comptime if target().os == "darwin" {
    impl _wait_darwin(process_id: int, lifetime_fd: int) -> None {
        queue: any = select.kqueue();
        try {
            queue.control(
                [select.kevent(lifetime_fd, filter=select.KQ_FILTER_READ, flags=select.KQ_EV_ADD)],
                0,
                0,
            );
            try {
                queue.control(
                    [
                        select.kevent(
                            process_id,
                            filter=select.KQ_FILTER_PROC,
                            flags=select.KQ_EV_ADD | select.KQ_EV_ONESHOT,
                            fflags=select.KQ_NOTE_EXIT,
                        ),
                    ],
                    0,
                    0,
                );
            } except ProcessLookupError {
                return;
            }
            while True {
                for event in queue.control(None, 2, None) {
                    if event.filter == select.KQ_FILTER_PROC or not os.read(lifetime_fd, 1) {
                        return;
                    }
                }
            }
        } finally {
            queue.close();
        }
    }
}

impl _wait_posix(process: subprocess.Popen[bytes], lifetime_fd: int) -> int {
    try {
        comptime if target().os == "darwin" {
            _wait_darwin(process.pid, lifetime_fd);
        } else {
            while os.waitid(os.P_PID, process.pid, os.WEXITED | os.WNOHANG | os.WNOWAIT) is None {
                if _owner_exited(lifetime_fd, 0.025) {
                    break;
                }
            }
        }
    } finally {
        with suppress(ProcessLookupError) {
            try {
                os.killpg(process.pid, signal.SIGKILL);
            } except PermissionError {
                comptime if target().os != "darwin" {
                    raise;
                } else {
                    if not _group_has_only_zombies(process.pid) {
                        raise;
                    }
                }
            }
        }
    }
    return process.wait();
}

impl _run(lifetime_fd: int, flags: int) -> dict[str, int | str | None] {
    platform_module: any;
    comptime if target().os == "windows" {
        import msvcrt;

        msvcrt.setmode(sys.stdin.fileno(), os.O_BINARY);
    } else {
        if lifetime_fd < 0 {
            msg: any = "POSIX extraction requires an owner lifetime descriptor";
            raise ValueError(msg);
        }
        primitives: any = ("kqueue", "kevent", "KQ_NOTE_EXIT")
            if sys.platform == "darwin"
            else ("waitid", "WEXITED", "WNOHANG", "WNOWAIT", "P_PID");
        platform_module = select if sys.platform == "darwin" else os;
        if `any(not hasattr(platform_module, name) for name in primitives) {
            msg = "Extraction lifetime requires a non-reaping POSIX exit observer";
            raise OSError(errno.ENOSYS, msg);
        }
        os.set_inheritable(lifetime_fd, False);
        signal.signal(signal.SIGCHLD, signal.SIG_DFL);
    }
    command: any = _read_command(lifetime_fd);
    if command is None or lifetime_fd >= 0 and _owner_exited(lifetime_fd) {
        return {"errno": None, "error": "Extraction owner exited before launch"};
    }
    source: any = None;
    comptime if target().os == "windows" {
        source = sys.stdin.buffer.read();
    }
    process: any = subprocess.Popen(
        command,
        stdin=subprocess.PIPE if os.name == "nt" else None,
        stderr=subprocess.DEVNULL,
        start_new_session=operator.ne(os.name, "nt"),
        creationflags=flags,
    );
    comptime if target().os == "windows" {
        process.communicate(source);
        returncode: any = process.returncode;
    } else {
        returncode = _wait_posix(process, lifetime_fd);
    }
    return {"returncode": returncode};
}

impl main {
    try {
        lifetime_fd: any;
        flags: any;
        (lifetime_fd, flags) = map(int, sys.argv[1:]) as any;
        status: any = _run(lifetime_fd, flags);
    } except (OSError, ValueError) as exc {
        status = {
            "errno": getattr(exc, "errno", None),
            "error": getattr(exc, "strerror", None) or `str(exc),
        };
    }
    with suppress(BrokenPipeError) {
        os.write(sys.stderr.fileno(), (json.dumps(status) + "\n").encode("ascii"));
    }
}
