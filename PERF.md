# Performance: the Jac rewrite against the original Python

The original is commit `dbd0a1b53` (Python). The Jac is this branch (`neojac-perf`), built with
neojac 0.5.1. The whole `memu` package is one `cpython` space (`archwire.jac`). Its Jac is lowered
to CPython code objects and runs on the CPython 3.15.2 that neojac ships. **No part of memU runs
in a native space** (see blocker 3).

## How it was measured

- **Same interpreter, same packages.** The original runs in its own venv on neojac's CPython
  3.15.2, with the exact package pins of the Jac venv (`pip freeze` of `.jac/venv`). The original
  imports from `src/` with `PYTHONPYCACHEPREFIX` set outside its checkout. The Jac imports from
  `.jac/build/pypi/top/site`.
- **Same inputs, offline.** An OpenAI-compatible `/embeddings` stub returns a deterministic
  256-dimensional unit vector per text, seeded by its SHA-256 (`docs/perf/embed_stub.py`). The
  commit payload has 200 memory files × 20 lines, 30 skills and 100 resources: 4,360 texts
  embedded, about 4,000 segments (`gen_payload.py`). The `memorize` session has 3,000 items
  (`gen_session.py`). Every run gets an empty `HOME`, with event reporting off.
- **Same output.** After every batch the harness normalises each side's output and compares it
  with the original's (`normalize.py`), dropping UUIDs and timestamps and rounding scores to 6
  places. The `memorize prepare` comparison also hashes all 237 files of the prepared workspace.
  **Every workload produced the same output on every side.**
- **Alternation and medians.** `docs/perf/bench.py` rotates the order of the sides on every
  repetition and reports medians. CLI: 7 reps. In-process: 5. Test suite: 3. It records wall
  time, and also the child's user+sys CPU time, because the machine is shared.
- **Load.** The machine has 20 cores and is shared with other users. The 1-minute load average
  during each batch (min/median/max):
  - CLI: 10.8/13.4/25.9
  - in-process: 14.9/24.0/33.9
  - test suite: 19.9/27.2/46.3
  - while profiling: 26–60

  CPU time is the steadier number. The wall time of the test suite swings by ±25% between reps.
- **Three sides:**
  - **orig:** the original Python.
  - **Jac before:** commit `7ac272b`, the rewrite as found plus the one correctness fix it needed
    before its `commit` and `retrieve` could run at all (below).
  - **Jac after:** this branch, `6625588`.

  The rewrite exactly as found (`dd817e1`) fails `memu commit` and `memu retrieve` with
  `error: "Unknown embedding profile 'embedding'"`.

`docs/perf/` holds the harness (`run_all.sh` runs the three batches). Its paths are this
machine's.

## Results

Median seconds, wall (CPU in parentheses where the two differ). Lower is better. **Jac/orig**
compares *Jac after* with *orig*.

### Commands (`memu …`, a fresh process each, SQLite store)

| Workload | orig | Jac before | Jac after | Jac/orig |
|---|---:|---:|---:|---:|
| `memu --help` (start-up) | 0.853 | 0.999 | **0.620** | 0.73 |
| `import memu.app` (library start-up) | 0.828 | 0.998 | **0.573** | 0.69 |
| `memu commit` (4,360 texts into an empty store) | 6.373 (5.68) | 7.978 (7.32) | 7.325 (6.67) | 1.15 |
| `memu commit` again (planning, no new vectors) | 2.708 | 2.998 | 2.890 | 1.07 |
| `memu retrieve` (one query, ~4k segments) | 1.859 | 2.197 | **1.764** | 0.95 |
| `memu list-files` (330 files) | 1.164 | 1.035 | **0.619** | 0.53 |
| `memu memorize prepare` (3,000-item session) | 1.187 | 1.206 | **0.740** | 0.62 |

`memu commit` and `memu retrieve` under *Jac before* ran with the validator fix. Without it they
fail.

### Library in-process (`MemoryService`, fake embedding client, no HTTP)

Inside one process, median seconds per phase:

| Phase | orig | Jac before | Jac after | Jac/orig |
|---|---:|---:|---:|---:|
| inmemory commit | 0.461 | 1.085 | 0.589 | 1.28 |
| inmemory re-commit | 0.474 | 0.477 | 0.572 | 1.21 |
| inmemory 30 retrieves | 1.768 | **14.628** | 1.992 | 1.13 |
| sqlite commit | 7.531 | 7.244 | 7.708 | 1.02 |
| sqlite re-commit | 2.749 | 2.562 | 2.768 | 1.01 |
| sqlite 10 retrieves | 8.218 | 13.018 | 9.736 | 1.18 |
| whole process | 22.92 (22.17) | 38.85 (38.33) | 24.02 (23.65) | 1.05 |

The phases that take under 0.6 s (inmemory commit and re-commit) differ by about 0.1 s, which is
within this machine's noise.

### Test suite (`pytest`, 1,613 collected)

| | orig | Jac before | Jac after | Jac/orig |
|---|---:|---:|---:|---:|
| wall | 156.6 | 132.3 | 122.3 | 0.78 |
| CPU (all processes it waits on) | 55.3 | 60.8 | **49.1** | 0.89 |

Every side passed the same 1,572 tests, and every side failed the same one,
`test_events.py::test_a_failed_commit_reports_the_call_and_leaves_the_cycle_to_the_agent`. It
fails because the harness clears `MEMU_EVENTS_BASE_URL`, and it fails for the original too. The
harness deselects six tests that fail on this machine for the original as well: the Windows-path
cases, and the detached-worker tests that time out under load. Through `neojac test`, the full
suite gives 1,576 passed and the same 4 environmental failures as the original.

## What made the difference

1. **The runtime's per-element conversion of vectors (the big one).** In a cpython space, an
   `any` that reaches a typed `list[T]` or `dict[K, V]` place is checked by
   `_jac.convert`/`_fits`, written in Python, one element at a time. These places received one:
   - `cosine_topk(..., corpus: Iterable[...])`: the corpus is CPython's iterable, so every row is
     an `any`, and `vecs.append(cast(list[float], vec))` into `vecs: list[list[float]]` converted
     every float of every stored vector on every query. That was **5.3M `convert` calls for 5
     queries, 97% of retrieve time**.
   - `_EmbeddingBatch.resolve`: every vector a commit embeds.
   - The embedding clients' `cast(list[float], d["embedding"])` in the SDK client and in every
     HTTP backend, then again in `HTTPEmbeddingClient.embed`, which reads its backend through an
     `any` field.

   The fixes:
   - `cosine_topk` keeps the rows as `list[any]` and hands them to numpy as they are, as the
     original does.
   - The batch reads each vector once with `[float(x) for x in v]`: the same typed result, made
     by plain Python, about 40× cheaper.
   - The backends parse the same way, and `embed` calls its backend through a typed local.
   - The SDK client returns the SDK's lists untouched, as the original does.

   Commits `d8ffb2e`, `a412b1a`, `f615aeb`. Effect: inmemory retrieve 14.6 s → 2.0 s, sqlite
   retrieve 13.0 s → 9.7 s, inmemory commit 1.09 s → 0.59 s, whole-process CPU 38.3 s → 23.7 s.
2. **Start-up: the OpenAI SDK is imported when a client is built (`fcc8dfb`).** `import openai`
   was about half the start-up of every `memu` entry point, `--help` and `list-files` included.
   `openai_sdk.jac` now imports it inside `init`. Its annotations stay text
   (`import from __future__ { annotations }`), so `CreateEmbeddingResponse` is named without
   being imported. This is why start-up, `list-files` and `memorize prepare` beat the original by
   0.25–0.55 s.

   One surface change: `memu.embedding.openai_sdk` no longer has `AsyncOpenAI` or
   `DefaultAsyncHttpxClient` as module attributes. Nothing in the repository reads them.
3. **SQLite vector normalisation with `list(map(float, v))` (`6625588`).** Every retrieve
   normalises every stored row's vector. The `map` form builds the same list in about 60% of the
   time. This is a small gain, about 0.1 s per 20k rows, and the original pays the comprehension
   too.
4. **A correctness fix that the measurement needed (`7ac272b`).** The rewrite wrote
   `@model_validator(mode="before") class def ensure_default`. neojac makes a `class def` a
   classmethod by putting `@classmethod` outermost, above `@model_validator`, so pydantic never
   registered the validator. As a result:
   - `EmbeddingProfilesConfig` lost its `embedding → default` alias;
   - the real `memu commit` and `memu retrieve` failed;
   - the suite missed it, because its tests inject the embedding client by that name.

   `@builtins.classmethod` under the validator puts the wrapper where Python had it (E2241
   documents the marker). A regression test was added
   (`tests/test_env_embedding_profile.py::test_service_built_from_profile_aliases_embedding`).
   It passes on the original and on the fix, and fails on the rewrite as found.

### Where the Jac is still slower, and why

- **`memu commit`: 1.15× wall, 1.17× CPU in the table above; 1.02× CPU after `5e83c58`.**
  Profiles of the two sides make the same 2.3M SQLAlchemy calls, with the same SQL, the same
  143–147 GC collections and the same heap. The two venvs are not the cause either: the
  original's code ran at the same speed on the Jac venv's interpreter and packages (5
  alternating runs). Nearly all of commit is SQLAlchemy (a `session.refresh` per inserted row;
  removing it would change the timestamps in the output), JSON and SQLite. The Jac's own extra
  work is one typed float pass over the 1.1M embedded floats (`resolve`, to honour
  `list[list[float]]`), plus the `held`/`convert` checks below. `5e83c58` builds that pass with
  `list(map(float, v))`. In a re-measure of 7 alternating runs (load 55–75), commit's median
  CPU was 11.59 s for the original and 11.87 s for the Jac, a ratio of **1.02**.
- **In-process retrieve: 1.13–1.18×.** Every value read through an `any` is wrapped in
  `_jac.held` (0.34 µs a call), and every value returned as a typed class goes through
  `_jac.convert` (0.79 µs). Python's attribute read costs 0.05 µs. The SQLite row mapper
  (`_row_to_record` and `_scope_kwargs_from`) does about ten of these per row, which is about
  80 ms per query over 21k rows. In the CLI, start-up more than pays this back (`memu retrieve`
  is 0.95× of the original).

## Blockers: where neojac stops a further speed-up

### 1. No O(1) way to give Python data a typed container type; `as` converts, although the docs say it never does

Every typed boundary an `any` crosses walks the value in Python. `e as T` is documented as "asserts
that the value of `e` is a `T` … It never converts." In a cpython space it lowers to the same
deep `_jac.convert`, and returns a converted copy:

```jac
def take(v: any) -> list[list[float]] {
    return v as list[list[float]];
}

with entry:__main__ {
    src: any = [[1, 2.0]];
    got = take(src);
    print(got, got is src);
}
```

`neojac emit-py svc` gives `return _jac.convert(v, (list, (list, float)))`. Running it prints
`[[1.0, 2.0]] False`: the ints became floats, and the list is a copy. The docs say it should
print the original `[[1, 2.0]] True`.

The consequence: data that comes from Python (provider JSON, SQLAlchemy rows, numpy) can keep a
Jac type only by being walked element by element (about 0.5–2.5 µs an element). Otherwise it
stays `any`. The fixes above keep hot data `any`, or walk it once with a plain comprehension.

### 2. Imports of the project's own modules are eager wires; nothing can be loaded lazily

memU's start-up is dominated by `memu/__init__` importing `MemoryService`, and with it SQLAlchemy
(0.37 s), numpy (0.14 s) and pydantic. Every `memu-*` hook pays this, even one that only launches
a worker. A lazy import of a project module is refused:

```jac
def lazy -> int {
    import from heavy { work }
    return work();
}
```

```text
main.jac:2:5: error[E2094]: the import of 'heavy' inside 'lazy' is written in 'main', which takes its imports of the modules under its archwire.jac from wires: add `heavy ++> main { work }` to the `graph import` block
```

The wire it asks for (`heavy ++> main { work }`) is emitted as a top-level
`import heavy as _jac_m23`, which runs when the module loads. A third-party package can be
imported in a function, which is what fix 2 does for `openai`. A project module cannot.

### 3. A shipped cpython package cannot call a native space

memU ships as a PyPI wheel (`memu-cli`). It is imported by plain CPython (`pip install`, the
`memu` scripts, pytest), so its code must be a cpython space. With a native space wired into the
shipped cpython space, it checks and builds:

```jac
// archwire.jac
graph spaces {
    space fast: native { kern; }
    space lib: cpython { "."; }

    package nativetest { ship lib; }
}

graph import {
    kern ++> api { dot }
}
```

```jac
// kern.jac
def:pub dot(a: list[float], b: list[float]) -> float { ... }
// api.jac
def score(a: list[float], b: list[float]) -> float {
    return dot(a, b);
}
```

But the call lowers to a remote request
(`rt.stdjac.remote.call_def(space='fast', module='kern', name='dot', …)`). The wheel contains
neither the native code nor `rt`, and importing it fails with
`ModuleNotFoundError: No module named 'rt'`. A native space reaches CPython only when it is the
host app embedding the cpython space ("A native app may run one cpython space"), and even then
calls cross serialized, as requests. So no part of a Python library can move into a native space
while the library ships as a wheel. In memU's case the compute would not gain from it anyway: the
hot work is numpy's matrix product, C `json` decoding of stored vectors, and SQLAlchemy.

### 4. Per-read `held` and per-return `convert` cannot be turned off

`_jac.held(v)` (boxing for Jac structs and arrays, which memU never uses) wraps every value read
through an `any`. A typed return of an `any` goes through `_jac.convert`. Together they are the
remaining 13–18% of in-process retrieve (above). No annotation or setting removes them for code
that handles Python objects. The only way out would be to move such code back into a `.py` file
of the space, which this port does not do.

### Also seen

- `neojac run <app>` of a cpython space that imports pydantic failed at start-up:
  `ModuleNotFoundError: No module named '_sysconfigdata__linux_x86_64-linux-gnu'`. This was a
  scratch project (`space svc: cpython { entry main; }`, `app demo { run svc; }`). memU does not
  ship such an app, so it did not block anything here.
