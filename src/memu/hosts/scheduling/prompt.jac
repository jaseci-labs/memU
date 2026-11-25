import shlex;
import from pathlib { Path }
import from typing { TYPE_CHECKING }
def bridging_pipeline_prompt(
    spec: HostSpec, *, prepare_session_dir: str | Path | None = None
) -> str;
