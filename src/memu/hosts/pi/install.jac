import argparse;
import shutil;
import from typing { Any }
glob STAGES = ("检查安装条件", "准备 memU 与记忆后端", "配置并检查 pi 扩展");
async def _command(argv: list[str]) -> int;
def _check_files;
async def _stage(stage: int, args: argparse.Namespace);
async def run(args: argparse.Namespace) -> int;
def register(sub: Any);
