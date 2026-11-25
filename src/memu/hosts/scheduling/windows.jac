import json;
import platform;
import shutil;
import subprocess;
import sys;
import from pathlib { Path }
import from typing { TYPE_CHECKING }
glob TASK_PATH = "\\memU\\";

with entry {}

glob DEFAULT_INTERVAL_MINUTES = 60,
     WRAPPER_NAME = "memu-bridge.ps1",
     PROMPT_NAME = "bridge-prompt.txt",
     LOG_NAME = "bridge.log";
def _invocation_args(schedule_command: str) -> list[str];
def _ps_quote(value: str) -> str;
def powershell_invocation(agent_path: str, schedule_command: str) -> str;
def agent_check_argv(agent_path: str, schedule_command: str, prompt: str) -> list[str];
def wrapper_script(
    agent_path: str, schedule_command: str, prompt_file: Path, log_file: Path, path_dirs: list[str]
) -> str;
def register_script(
    task_name: str, wrapper_path: Path, interval_minutes: int, workdir: Path
) -> str;
def unregister_script(task_name: str) -> str;
def unregister_if_present_script(task_name: str) -> str;
def status_script(task_name: str) -> str;
def _require_windows;
def _run_powershell(script: str) -> subprocess.CompletedProcess[str];
def _agent_binary(spec: HostSpec) -> str;
def _resolve_agent(spec: HostSpec) -> str | None;
def _authenticates(spec: HostSpec, agent_path: str, workdir: Path) -> tuple[bool, str];
def _paths(layout: Layout) -> tuple[Path, Path, Path, Path];
def _auth_gate(spec: HostSpec, agent_path: str, workdir: Path) -> int;
def install(
    spec: HostSpec, layout: Layout, *, interval_minutes: int = DEFAULT_INTERVAL_MINUTES
) -> int;
def uninstall(spec: HostSpec, layout: Layout) -> int;
def cleanup_script(spec: HostSpec, layout: Layout, *, remove: bool) -> str;
def cleanup(spec: HostSpec, layout: Layout, *, remove: bool) -> int;
def _former_registrations(spec: HostSpec) -> tuple[str, ...];
def _display_names(names: tuple[str, ...]) -> str;
def status(spec: HostSpec, layout: Layout) -> int;
def verify(spec: HostSpec, layout: Layout) -> int;
