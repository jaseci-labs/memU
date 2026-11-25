import importlib;
import argparse;
import os;
import sys;
import uuid;
import from typing { Any }
glob _RETRIEVAL_CONFIG_COMMENTS = """# Host retrieval score cutoffs (docs/retrieval.md)
# MEMU_MEMORY_MODE selects independent Cloud or Local settings.
# Cloud uses calibrated defaults; review them when the Cloud embedding model changes.
# Uncomment to override; leave commented to follow defaults across upgrades.
# MEMU_CLOUD_RETRIEVE_MIN_SCORE_SHORT=0.55
# MEMU_CLOUD_RETRIEVE_MIN_SCORE_LONG=0.60
# MEMU_CLOUD_RETRIEVE_MIN_SCORE_EXTRACTED=0.58
# Local defaults to no filtering. Calibrate for your embedding model and corpus.
# Replace the placeholders before uncommenting; recalibrate when changing models.
# MEMU_LOCAL_RETRIEVE_MIN_SCORE_SHORT=<your-calibrated-score>
# MEMU_LOCAL_RETRIEVE_MIN_SCORE_LONG=<your-calibrated-score>
# MEMU_LOCAL_RETRIEVE_MIN_SCORE_EXTRACTED=<your-calibrated-score>
# Values: finite [-1, 1]; score >= cutoff survives; -1 retains all valid cosine scores.
""",
     IDENTITY_KEYS = ("MEMU_DB", "MEMU_EMBED_PROVIDER", "MEMU_EMBED_MODEL");

with entry {}

glob REFUSED = 2;

with entry {}

def _row(label: str, value: str);
def _declared_mode(values: dict[str, str]) -> str;
def _effective_mode(values: dict[str, str]) -> str;
def _protection(values: dict[str, str]) -> str | None;
def _client_id(values: dict[str, str]) -> tuple[dict[str, str], str, bool];
def _short(client_id: str) -> str;
def _write(updates: dict[str, str]);
def _report_install_started(args: argparse.Namespace);
async def _cmd_init(args: argparse.Namespace) -> int;
def _refuse_flip(values: dict[str, str], target: str, binary: str) -> int | None;
def _refuse_identity(values: dict[str, str], updates: dict[str, str]) -> int | None;
async def _cmd_config(args: argparse.Namespace) -> int;
def _updates_for(target: str, args: argparse.Namespace) -> dict[str, str];
def _report_backend(target: str, values: dict[str, str], updates: dict[str, str]);
def _collect(updates: dict[str, str], args: argparse.Namespace, pairs: tuple[tuple[str, str], ...]);
def _show -> int;
def register(sub: Any, *, binary: str, host: str = "", session_id_env: str = "");
