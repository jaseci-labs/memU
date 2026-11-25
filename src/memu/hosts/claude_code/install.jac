import builtins;
import argparse;
import shutil;
import subprocess;
import sys;
import from typing { Any }
glob STAGES = ("检查安装条件", "准备 memU 与记忆后端", "准备 Claude CLI", "配置自动记忆与检索", "完成安装检查");
async def _command(argv: list[str]) -> int;
def _check_cleanup;
def _prepare_host(args: argparse.Namespace);
async def _stage(stage: int, args: argparse.Namespace);
async def run(args: argparse.Namespace) -> int;
def register(sub: Any);
