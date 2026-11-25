impl configure_windows_path(executable: Path) {
    if sys.platform != "win32" {
        return;
    }
    directory = str(executable.parent);
    shell = shutil.which("powershell.exe");
    if shell is None {
        raise FileNotFoundError("PowerShell is required to configure Windows user PATH");
    }
    script = "$ErrorActionPreference = 'Stop'\n$directory = $env:MEMU_CLI_BIN\n$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')\n$entries = @($userPath -split ';' | ForEach-Object { $_.Trim().TrimEnd('\\\\') })\nif ($entries -notcontains $directory.TrimEnd('\\\\')) {\n    $updated = if ([string]::IsNullOrEmpty($userPath)) { $directory } else { \"$directory;$userPath\" }\n    [Environment]::SetEnvironmentVariable('Path', $updated, 'User')\n}\n";
    subprocess.run(
        [shell, "-NoProfile", "-NonInteractive", "-Command", script],
        env={**dict(os.environ), "MEMU_CLI_BIN": directory},
        stdin=subprocess.DEVNULL,
        capture_output=True,
        timeout=20,
        check=True,
    );
    current = os.environ.get("PATH", "");
    if os.path.normcase(directory) not in {
        os.path.normcase(os.path.expandvars(`entry.strip().strip("\"")).rstrip("\\/"))
        for `entry in current.split(os.pathsep)
        if `entry.strip()
    }
    {
        os.environ["PATH"] = directory + (os.pathsep + current if current else "");
    }
}

impl install(host: str, url: str, *, unix_shell: str, env: dict[str, str] | None = None) {
    windows = sys.platform == "win32";
    shell = shutil.which("powershell.exe" if windows else unix_shell);
    if shell is None {
        raise FileNotFoundError(
            f"The official {host} installer requires PowerShell on Windows or {unix_shell} on Unix"
        );
    }
    suffix = "ps1" if windows else "sh";
    print(text("📥  正在下载官方 {host} 安装器：{url}", host=host, url=url), file=sys.stderr, flush=True);
    with tempfile.TemporaryDirectory(prefix=f"memu-{host.lower()}-install-") as directory {
        script = Path(directory) / f"install.{suffix}";
        request = urllib.request.Request(url, headers={"User-Agent": "memu-cli"});
        with urllib.request.urlopen(request, timeout=30, **trust.urlopen_kwargs()) as response {
            data = response.read(1024 * 1024 + 1);
        }
        if not data or len(data) > 1024 * 1024 {
            raise ValueError("Official installer download is empty or exceeds 1 MiB");
        }
        script.write_bytes(data);
        argv = [
            shell,
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script),
        ]
            if windows
            else [shell, str(script)];
        print(text("📦 正在运行官方安装器，下载和安装可能需要几分钟……"), file=sys.stderr, flush=True);
        subprocess.run(
            argv,
            stdin=subprocess.DEVNULL,
            stdout=sys.stderr,
            stderr=sys.stderr,
            env={**dict(os.environ), **(env or {})},
            timeout=300,
            check=True,
        );
    }
}
