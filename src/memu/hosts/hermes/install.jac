import argparse;
import platform;
import shutil;
import from dataclasses { replace }
import from pathlib { Path }
import from typing { Any }
glob STAGES = ("检查安装条件", "准备 memU 与记忆后端", "Configuring and checking SOUL.md");
async def _command(argv: list[str]) -> int;
async def _stage(stage: int, args: argparse.Namespace);
async def run(args: argparse.Namespace) -> int;
def register(sub: Any);
