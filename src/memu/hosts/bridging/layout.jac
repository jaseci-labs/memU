"""Where the bridging pipeline keeps its working state.

Prepare and commit must agree on every one of these paths. They used to agree by
duplicating the constants in two scripts under a ``# Must match prepare_jobs.py``
comment — a comment is not a mechanism. One object, one source of truth.
"""

import from __future__ { annotations }

import os;

import from dataclasses { dataclass }

import from pathlib { Path }

glob BASE_DIR: any = "~/.memu";

glob TRACK_DIRS: dict[str, str];

with entry {
    TRACK_DIRS = {"memory": "memory", "skill": "skill"};
    base_default_ = BASE_DIR;
}

glob base_default_: any;

"""The ``~/.memu`` working tree for one host's bridging runs."""
@dataclass(frozen=True)
class Layout {
    has base: Path;

    has host: str;

    class def `default(host: str, base: str | Path = base_default_) -> Layout;

    """Transcripts sliced out of the host's session log this run."""
    has sessions: Path {
        getter {
            return self.base / "sessions";
        }
    }

    """The numbered job-instruction files the agent works through."""
    has jobs: Path {
        getter {
            return self.base / "jobs";
        }
    }

    has memory: Path {
        getter {
            return self.base / TRACK_DIRS["memory"];
        }
    }

    has skill: Path {
        getter {
            return self.base / TRACK_DIRS["skill"];
        }
    }

    """Per-session line cursor — the *promoted* one, advanced only by a
        successful ``commit``. Scoped by host: two hosts' session keys are
        unrelated, and sharing one cursor file would let each hide the other's
        new turns."""
    has session_manifest: Path {
        getter {
            return self.base / f".session_manifest.{self.host}.json";
        }
    }

    """The cursor as ``prepare`` staged it, promoted by ``commit``.

        Two files because the two moments differ: prepare knows what it *saw*,
        only commit knows what survived into the store. Promoting on commit is
        what makes a bare ``prepare`` harmless and a run that dies mid-pipeline
        recoverable instead of silently lossy (#518)."""
    has session_manifest_pending: Path {
        getter {
            return self.session_manifest.with_name(self.session_manifest.name + ".pending");
        }
    }

    """When this cycle's ``prepare`` began, for ``commit`` to close (ADR 0016 §10).

        The two halves of the record seam are separate processes, usually minutes
        or hours apart, so the start cannot be held in memory — and
        :func:`time.monotonic` does not cross a process boundary at all. A file is
        the only carrier, and an explicit one rather than an existing artifact's
        mtime: ``session_manifest_pending`` is written partway through ``prepare``,
        before the store mirror and the template fetches, so reading its timestamp
        would silently exclude exactly the network time worth measuring — and would
        bind the number to a statement order nobody has agreed to preserve.

        Host-scoped like the cursor beside it, and ephemeral: written by every
        ``prepare``, cleared by the ``commit`` that reports it.
        """
    has run_marker: Path {
        getter {
            return self.base / f".bridging_run.{self.host}.json";
        }
    }

    """Session ids of the bridging runs themselves, skipped by ``prepare``.

        Host-scoped like the cursor, and for the same reason: two hosts' session
        ids are unrelated, and a shared file would let one host's run id mask an
        unrelated real session on the other."""
    has self_sessions: Path {
        getter {
            return self.base / f".self_sessions.{self.host}.json";
        }
    }

    """Content hashes of the tracked files as of the last successful
        ``commit`` (bootstrapped by the first ``prepare`` from the
        store-derived mirror)."""
    has memory_manifest: Path {
        getter {
            return self.base / ".memory_manifest.json";
        }
    }

    """Raw append-only log of files the sessions touched, written by the skill jobs."""
    has resource_log: Path {
        getter {
            return self.base / ".resource.tmp";
        }
    }

    """The verified, describe-me resource file the agent annotates."""
    has resources: Path {
        getter {
            return self.base / "resources.md";
        }
    }

    has track_dirs: list[str] {
        getter {
            return `list(TRACK_DIRS.values());
        }
    }
}
