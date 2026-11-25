import importlib;
import argparse;
import asyncio;
import contextlib;
import functools;
import json;
import os;
import platform;
import re;
import shlex;
import sys;
import time;
import urllib.request;
import from collections.abc { Callable, Coroutine }
import from dataclasses { dataclass, field }
import from importlib.resources { files }
import from pathlib { Path }
import from typing { Any, Literal, Optional }
glob commit: any,
     prepare: any;

with entry {
    commit = importlib.import_module("memu.hosts.bridging").commit;
    prepare = importlib.import_module("memu.hosts.bridging").prepare;
}

glob ScheduleBackend = Literal["os", "native", "external", "hook"];

with entry {}

glob DOCS = {"install": "INSTALL.md", "task": "BRIDGING_TASK.md", "uninstall": "UNINSTALL.md"},
     _TASK_NAME_RE = re.compile("memu-bridging-[a-z0-9]+(?:-[a-z0-9]+)*\\Z"),
     _DOC_TOKEN_RE = re.compile("\\{\\{([a-z_]+)\\}\\}"),
     _DOC_TOKENS = frozenset({
         "task_name",
         "former_task_names",
         "all_task_names",
         "task_name_pattern",
         "task_doc_name",
     });
def _task_names_text(names: tuple[str, ...]) -> str;
def _task_name_pattern(names: tuple[str, ...]) -> str;
glob GUIDE_EVENTS = {
    "install": events.INSTALL_GUIDE_OPENED,
    "uninstall": events.UNINSTALL_GUIDE_OPENED,
};

with entry {}

def _check_host_spec(spec: any);

@dataclass(frozen=True)
class HostSpec {
    has host: str,
        display: str,
        package: str,
        task_name: str,
        source_factory: Callable[[str], TranscriptSource],
        session_dir: str,
        session_help: str,
        instruction_path: str,
        legacy_instruction_paths: tuple[str, ...] = (),
        former_task_names: tuple[str, ...] = (),
        skills_dir: str = "",
        base_dir: str = "",
        schedule_backend: ScheduleBackend = "external",
        schedule_command: str = "",
        schedule_prepare_session_dir: bool = False,
        session_id_env: str = "",
        needs_headless_auth: bool = False,
        install_hint: str = "",
        auth_hint: str = "",
        extra_flags: dict[str, str] = field(default_factory=dict[any, any]),
        register_extra: Callable[[Any], None] | None = None,
        resolve_self_sessions: Callable[[TranscriptSource, Layout], list[str]] | None = None,
        hook: Any = None;
    static has __post_init__: any = _check_host_spec;

    has binary: str {
        getter {
            return f"memu-{self.host}";
        }
    }

    has verify_command: str {
        getter {
            binary = f"{self.binary}.exe" if sys.platform == "win32" else self.binary;
            return f"{binary} verify-resources";
        }
    }

    has default_base_dir: str {
        getter {
            return self.base_dir or f"~/.memu/hosts/{self.host}";
        }
    }

    has all_task_names: tuple[str, ...] {
        getter {
            return (self.task_name, *self.former_task_names);
        }
    }

    has task_doc_name: str {
        getter {
            return f"create-{self.task_name}-task";
        }
    }

    def render_doc(text: str) -> str;
}


def _layout(spec: HostSpec, args: argparse.Namespace) -> Layout;
def _refresh_retrieval(spec: HostSpec);
async def _cmd_prepare(spec: HostSpec, args: argparse.Namespace) -> int;
async def _cmd_commit(spec: HostSpec, args: argparse.Namespace) -> int;
def _pending_session_count(layout: Layout) -> int;
glob MAX_CYCLE_SECONDS = 24 * 60 * 60;

with entry {}

def _elapsed_ms(started: float) -> int;
def _mark_cycle_start(spec: HostSpec, layout: Layout);
def _cycle_duration_ms(layout: Layout) -> int | None;
def _cycle_is_open(layout: Layout) -> bool;
def _record_commit(
    spec: HostSpec,
    layout: Layout,
    *,
    success: bool,
    recall_files: int,
    resources: int,
    sessions: int,
    latency_ms: int,
);
async def _cmd_verify_resources(spec: HostSpec, args: argparse.Namespace) -> int;
glob _TRANSPORT_SMELLS = (
    "502",
    "503",
    "504",
    "timeout",
    "timed out",
    "connect",
    "unreachable",
    "proxy",
);
def _smells_like_transport(exc: BaseException) -> bool;
def _proxy_hint(base_url: str) -> str | None;
async def _cmd_doctor(spec: HostSpec, args: argparse.Namespace) -> int;
async def _cmd_backend_doctor(spec: HostSpec, args: argparse.Namespace) -> int;
async def _cmd_docs(spec: HostSpec, args: argparse.Namespace) -> int;
def _report_guide_opened(spec: HostSpec, event: str);
async def _cmd_hook_run(spec: HostSpec, args: argparse.Namespace) -> int;
async def _run_hook_pipeline(spec: HostSpec, args: argparse.Namespace) -> int;
async def _cmd_schedule(spec: HostSpec, args: argparse.Namespace) -> int;
async def _cmd_report(spec: HostSpec, args: argparse.Namespace) -> int;
def _register_report(sub: Any, handler: Any);
def build_parser(spec: HostSpec) -> argparse.ArgumentParser;
def run(spec: HostSpec, argv: Optional[list[str]] = None) -> int;
