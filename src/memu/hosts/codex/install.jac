import builtins;
import argparse;
import json;
import os;
import from pathlib { Path }
import from typing { Any }
glob STAGES = ("检查安装条件", "准备 memU 与记忆后端", "准备 Codex CLI", "配置自动记忆与检索", "完成安装检查"),
     NOTICE = "如果你使用 Codex Desktop，且以前自行安装过 memU 定时任务，现在可以自行暂停或移除它们，避免重复处理记忆。";
def _home -> Path;
async def _command(argv: list[str]) -> int;
def _inspect;
def _check_cleanup;
async def _stage(stage: int, args: argparse.Namespace);
def _prepare_host(args: argparse.Namespace);
async def run(args: argparse.Namespace) -> int;
def register(sub: Any);
