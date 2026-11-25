"""The resource pass: verify the touched-file log, then have the agent describe it.

The skill jobs append every file path a session touched to a raw log. That log is
untrusted — paths may be relative, duplicated, or already deleted — so
:func:`verify_resource_log` filters it down to files that still exist before the
agent is asked to spend a read on each one.
"""

import from __future__ { annotations }

import os;

import from pathlib { Path, PureWindowsPath }

import from typing { Any }

glob MAX_RESOURCES: any = 50;

glob RESOURCE_JOB_TEMPLATE: any = "You are the **resource-describe** pass for an agent's workspace. Your job is to\nannotate a list of files the agent recently touched with short, human-readable\ndescriptions of what each file is.\n\n## Step 1 — build the resource list\n\nRun this command with `bash`:\n\n    {verify_command}\n\nIt reads the raw log of touched files, keeps only the ones that still exist as\nreal files, dedups them, and writes the result to:\n\n    {resource_file}\n\nRead that file. It is a series of `---`-delimited records, each shaped like:\n\n    ---\n    path: <absolute path to a file>\n    description:\n    ---\n\nThe `description:` lines start empty — filling them in is your task.\n\n## Step 2 — describe each file\n\nFor every record, read the file at its `path` (with `bash`, e.g. `cat`) and\nwrite a **one to several sentence** description of what the file is and what it\ncontains onto its `description:` line.\n\nThis is **best-effort**. Put the literal value `null` on the `description:` line\ninstead when the file:\n\n  - cannot be read (permission denied, broken, or gone),\n  - is very large (don't try to read huge files), or\n  - is an unknown, binary, or uncommon format you can't meaningfully summarize.\n\nA `null` description is a perfectly good outcome — do not guess at content you\ncould not actually read.\n\n## Step 3 — write the result back\n\nRewrite `{resource_file}` in place, keeping the exact same `---`-delimited\nstructure and every `path:` line unchanged, with each `description:` line now\nholding either your summary or `null`. Keep each description on a single line.\n";

glob max_resources_default_: any;

with entry {
    max_resources_default_ = MAX_RESOURCES;
}

"""Filter the raw touched-file log into the describe-me resource file.

    Keeps absolute paths that still resolve to a real file, deduped in first-seen
    order, capped at ``max_resources``. Returns how many survived.
    """
def verify_resource_log(
    log: Path, resource_file: Path, max_resources: int = max_resources_default_
) -> int;

"""Parse the finalized resource file into ``{path, description}`` records.

    Records the agent left empty or marked with the literal ``null`` are dropped —
    that is the "couldn't describe it" outcome, not a failure.
    """
def read_resources(resource_file: Path) -> list[dict[str, Any]];

glob template_default_: any;

with entry {
    template_default_ = RESOURCE_JOB_TEMPLATE;
}

"""Write the resource-describe job as ``<job_index>.txt`` under ``job_dir``.

    ``template`` defaults to the embedded constant and is overridden by
    :func:`~memu.hosts.bridging.pipeline.prepare` with the server's current copy
    when it is reachable (:mod:`memu.hosts.templates`).
    """
def prepare_resource_job(
    job_dir: Path,
    verify_command: str,
    resource_file: Path,
    job_index: int,
    *,
    template: str = template_default_,
) -> None;
