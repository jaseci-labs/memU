"""The bridging run's own session, remembered so ``prepare`` never mines it.

The record seam runs *as a session of the host agent*, and the host logs that
session in exactly the place memU discovers sessions from. Left alone that is a
loop: every run hands the next run fresh "new" content, so ``prepare`` can never
report zero, and the mining jobs chew through memU's own bookkeeping — the
newest transcripts on disk, so they sort to the top and take the ``max_jobs``
slots real conversations were waiting for (#606).

Claiming a session takes two facts, and they are known in different places:

    the launch  — "this is the scheduled run", but the session does not exist
                  yet, so its id cannot be known there
    inside it   — the host has put the session id in the environment
                  (:attr:`~memu.hosts.host_cli.HostSpec.session_id_env`), but a
                  process there cannot tell why it was started

``prepare`` is simply where the two meet: it runs *inside* the session, and it
inherits the launcher's environment. So running ``prepare`` is not part of the
condition — it is where the condition can be evaluated. Treating the command
itself as the signal is the bug this module was corrected for: people run
``prepare`` by hand, often meaning "remember this conversation now", and
claiming that session delivers the opposite, permanently.

Both signals live in the invocation rather than in the transcript, so the
identity is exact, and nothing can be forged later by a memory that happens to
quote the wrong text.

Hosts that expose no such variable are not served here. What to do for them is
open — see ADR 0015, which rejects matching a marker against transcript content
and records the alternatives — so this module deliberately offers no fallback.
"""

import operator;

import from __future__ { annotations }

import json;

import os;

import from collections.abc { Mapping }

import from pathlib { Path }

glob MAX_REMEMBERED: any = 1000;

glob BRIDGING_RUN_ENV: any;

with entry {
    BRIDGING_RUN_ENV = "MEMU_BRIDGING_RUN";
}

"""Whether this invocation is the scheduled bridging task, not a person.

    Running ``prepare`` is emphatically *not* the test. It is an ordinary command
    people run by hand — during development, or simply to say "remember this
    conversation now" — and treating that as a bridging run would exclude the very
    session the user asked to have mined, permanently and for every later run.

    What actually marks the scheduled task is how it was *launched*: the wrapper
    exports :data:`BRIDGING_RUN_ENV`, and the task runs in memU's own working
    directory (``schedule`` passes ``-WorkingDirectory``; without it Task Scheduler
    would start in ``System32``). Either signal is enough — the directory keeps
    tasks registered before this existed working, and the variable survives an
    agent that changes directory before running the command.

    Fails open in the safe direction: unrecognised means "a person ran this", so
    nothing is recorded and nothing is skipped.
    """
def is_bridging_run(cwd: Path, base: Path, env: Mapping[str, str] | None = None) -> bool;

"""Session ids of previous bridging runs, oldest first.

    Fails open: an unreadable or malformed file yields no ids, so the worst case
    is the pre-#606 behaviour (self-sessions get mined) rather than a run that
    cannot start.
    """
def load(path: Path) -> list[str];

"""Record this run's own session id, and return every id to skip.

    Idempotent: a re-run inside the same host session (a retried bridging task,
    or a bare ``prepare`` the user typed themselves) does not duplicate the id.
    """
def remember(path: Path, session_id: str) -> list[str];
