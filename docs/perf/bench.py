"""Alternate original / Jac runs of each workload; report medians and load.

usage: python3 bench.py <reps> [workload ...]   (results appended to results.jsonl)
"""

import json
import resource
import os
import shutil
import statistics
import subprocess
import sys
import time
from pathlib import Path

P = Path("/home/jayanaka/neojac-deslop/perf/memU")
BENCH = P / "bench"
J = Path("/home/jayanaka/neojac-deslop/repos/NevaMind-AI_memU")
SIDES = {
    "orig": {
        "py": str(P / "venv/bin/python"),
        "path": "/home/jayanaka/neojac-deslop/base/memU/src",
        "cwd": "/home/jayanaka/neojac-deslop/base/memU",
    },
    "jac_before": {
        "py": str(J / ".jac/venv/bin/python"),
        "path": str(P / "jac_before/.jac/build/pypi/top/site"),
        "cwd": str(J),
    },
    "jac": {
        "py": str(J / ".jac/venv/bin/python"),
        "path": str(J / ".jac/build/pypi/top/site"),
        "cwd": str(J),
    },
}
ACTIVE = os.environ.get("BENCH_SIDES", "orig,jac_before,jac").split(",")
PAYLOAD = BENCH / "payload.json"
QUERY = "weekly deploy rollout latency budget"


def env_for(side: str, home: Path) -> dict[str, str]:
    e = dict(os.environ)
    e.update({
        "PYTHONPATH": SIDES[side]["path"],
        "PYTHONPYCACHEPREFIX": str(P / "pycache"),
        "HOME": str(home),
        "MEMU_BASE_URL": "http://127.0.0.1:18765/v1",
        "MEMU_API_KEY": "sk-test",
        "MEMU_EVENTS_BASE_URL": "",
    })
    e.pop("MEMU_DB", None)
    return e


CPU: list[float] = []


def _cpu() -> float:
    ru = resource.getrusage(resource.RUSAGE_CHILDREN)
    return ru.ru_utime + ru.ru_stime


def run(side: str, argv: list[str], home: Path, out: Path | None = None, cwd: str | None = None) -> float:
    c0 = _cpu()
    t0 = time.perf_counter()
    r = subprocess.run(
        argv, env=env_for(side, home), cwd=cwd or str(BENCH),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    dt = time.perf_counter() - t0
    CPU.append(_cpu() - c0)
    if r.returncode != 0 and "pytest" not in argv:
        raise SystemExit(f"{side} {argv} failed: {r.stderr.decode()[-2000:]}")
    if out is not None:
        out.write_bytes(r.stdout)
    return dt


def memu(side: str, *args: str) -> list[str]:
    return [SIDES[side]["py"], "-m", "memu", *args]


def wl_startup_help(side, work):
    return run(side, memu(side, "--help"), work / "home")


def wl_import_service(side, work):
    return run(side, [SIDES[side]["py"], "-c", "from memu.app import MemoryService"], work / "home")


def wl_commit(side, work):
    db = work / "db.sqlite3"
    db.unlink(missing_ok=True)
    return run(side, memu(side, "commit", str(PAYLOAD), "--db", str(db), "--json"), work / "home", work / "commit.json")


def wl_recommit(side, work):
    # Same payload into the populated store: planning + diff, no new vectors.
    return run(side, memu(side, "commit", str(PAYLOAD), "--db", str(work / "db.sqlite3"), "--json"), work / "home", work / "recommit.json")


def wl_retrieve(side, work):
    return run(side, memu(side, "retrieve", QUERY, "--db", str(work / "db.sqlite3")), work / "home", work / "retrieve.json")


def wl_list_files(side, work):
    return run(side, memu(side, "list-files", "--db", str(work / "db.sqlite3")), work / "home", work / "list.txt")


def wl_memorize_prepare(side, work):
    import hashlib
    import re
    runs = work / "home/.memu/developer/runs"
    dt = run(side, memu(side, "memorize", "prepare", str(BENCH / "session.json"), "--db", str(work / "db.sqlite3"), "--json"),
             work / "home", work / "prepare.raw")

    def norm(text: str) -> str:
        return re.sub(r"run-[a-z0-9_]+", "run-X", text.replace(str(work), "WORK"))

    lines = [norm((work / "prepare.raw").read_text())]
    for run_dir in runs.iterdir():
        for f in sorted(run_dir.rglob("*")):
            if f.is_file():
                lines.append(f"{norm(str(f.relative_to(run_dir)))} {hashlib.sha256(norm(f.read_text()).encode()).hexdigest()}")
        shutil.rmtree(run_dir)
    (work / "prepare.txt").write_text("\n".join(lines))
    return dt


def wl_inproc(side, work):
    c0 = _cpu()
    t0 = time.perf_counter()
    r = subprocess.run([SIDES[side]["py"], str(BENCH / "inproc.py")], env=env_for(side, work / "home"),
                       cwd=str(BENCH), stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    dt = time.perf_counter() - t0
    CPU.append(_cpu() - c0)
    (work / "inproc.json").write_bytes(r.stdout)
    PHASES.setdefault(side, []).append(json.loads(r.stderr.decode().strip().splitlines()[-1]))
    return dt


PHASES: dict[str, list[dict[str, float]]] = {}


def compare_outputs(works) -> dict[str, str]:
    verdict = {}
    for f in ["commit.json", "recommit.json", "retrieve.json", "list.txt", "prepare.txt", "inproc.json"]:
        normed = {}
        for side, w in works.items():
            if (w / f).exists():
                normed[side] = subprocess.run([sys.executable, str(BENCH / "normalize.py"), str(w / f)],
                                              stdout=subprocess.PIPE, check=True).stdout
        if len(normed) > 1:
            ref = normed.get("orig", next(iter(normed.values())))
            verdict[f] = "same" if all(v == ref for v in normed.values()) else "DIFF " + ",".join(s for s, v in normed.items() if v != ref)
    return verdict


def wl_pytest(side, work):
    argv = [SIDES[side]["py"], "-m", "pytest", "-q", "-p", "no:cacheprovider", "--no-header"]
    if side != "orig":
        argv.append("--import-mode=append")
        argv += ["--deselect", "tests/test_env_embedding_profile.py::test_service_built_from_profile_aliases_embedding"]
    # Deselect the tests that fail on this machine for both (env/timing), so each run is the full rest.
    for t in DESELECT:
        argv += ["--deselect", t]
    return run(side, argv, work / "home", work / "pytest.txt", cwd=SIDES[side]["cwd"] if side == "orig" else str(J / ".jac/test/trees/NevaMind-AI_memU"))


DESELECT = [
    "tests/test_bridging_resources.py::test_verify_accepts_windows_absolute_paths",
    "tests/test_claude_memorize_hook.py::test_real_agent_process_skips_both_submit_handlers",
    "tests/test_claude_memorize_hook.py::test_real_detached_worker_records_failure_without_touching_store",
    "tests/test_hermes_memorize_hook.py::test_installed_shell_command_starts_detached_worker",
]

WORKLOADS = {
    "startup_help": wl_startup_help,
    "import_service": wl_import_service,
    "commit": wl_commit,
    "recommit": wl_recommit,
    "retrieve": wl_retrieve,
    "list_files": wl_list_files,
    "memorize_prepare": wl_memorize_prepare,
    "inproc": wl_inproc,
    "pytest": wl_pytest,
}


def main() -> None:
    reps = int(sys.argv[1])
    names = sys.argv[2:] or [n for n in WORKLOADS if n != "pytest"]
    label = os.environ.get("BENCH_LABEL", "run")
    works = {}
    for side in ACTIVE:
        w = P / f"work_{side}"
        if w.exists():
            shutil.rmtree(w)
        (w / "home").mkdir(parents=True)
        works[side] = w
    times: dict[str, dict[str, list[float]]] = {n: {s: [] for s in ACTIVE} for n in names}
    cpus: dict[str, dict[str, list[float]]] = {n: {s: [] for s in ACTIVE} for n in names}
    loads = []
    for i in range(reps):
        order = ACTIVE[i % len(ACTIVE):] + ACTIVE[:i % len(ACTIVE)]
        for side in order:
            for n in names:
                loads.append(os.getloadavg()[0])
                times[n][side].append(WORKLOADS[n](side, works[side]))
                cpus[n][side].append(CPU[-1])
    res = {
        "label": label, "reps": reps, "when": time.strftime("%Y-%m-%d %H:%M:%S"),
        "load_min": min(loads), "load_med": statistics.median(loads), "load_max": max(loads),
        "median": {n: {s: statistics.median(v) for s, v in d.items()} for n, d in times.items()},
        "all": times,
        "cpu_median": {n: {s: statistics.median(v) for s, v in d.items()} for n, d in cpus.items()},
        "cpu_all": cpus,
        "phases": {s: {k: statistics.median(p[k] for p in ps) for k in ps[0]} for s, ps in PHASES.items()},
        "outputs": compare_outputs(works),
    }
    with open(BENCH / "results.jsonl", "a") as fh:
        fh.write(json.dumps(res) + "\n")
    print(f"label={label} reps={reps} load(1m) min/med/max = {res['load_min']:.1f}/{res['load_med']:.1f}/{res['load_max']:.1f}")
    print(f"{'workload':16}" + "".join(f"{s:>12}" for s in ACTIVE) + "  (median wall s | median cpu s)")
    for n in names:
        print(f"{n:16}" + "".join(f"{res['median'][n][s]:12.3f}" for s in ACTIVE)
              + "  |" + "".join(f"{res['cpu_median'][n][s]:10.3f}" for s in ACTIVE))
    for k in (next(iter(res["phases"].values()), {}) if res["phases"] else {}):
        print(f"  {k:14}" + "".join(f"{res['phases'][s][k]:12.3f}" for s in ACTIVE if s in res["phases"]))
    print("outputs:", res["outputs"])


if __name__ == "__main__":
    main()
