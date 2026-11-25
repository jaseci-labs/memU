import contextlib;
import json;
import os;
import tempfile;
import from collections.abc { Sequence }
import from dataclasses { dataclass }
import from pathlib { Path }
import from pydantic { JsonValue }

@dataclass(frozen=True)
class MaterializedConversation {
    has memory_path: Path,
        skill_path: Path;
}

def _dump_item(item: SkillInputItem) -> dict[str, JsonValue];
def _serialize_items(items: Sequence[SkillInputItem]) -> str;
def _atomic_write_text(path: Path, content: str);
def materialize_memorize_input(
    memorize_input: MemorizeInput, out_dir: Path, *, session_index: int = 1, clear: bool = True
) -> MaterializedConversation;
def materialize_memorize_inputs(
    memorize_inputs: Sequence[MemorizeInput], out_dir: Path
) -> list[MaterializedConversation];
