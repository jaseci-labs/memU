"""Generate a deterministic commit payload: N memory files x L lines, S skills, R resources."""

import json
import random
import sys

WORDS = (
    "launch preference deploy rollout coffee morning review python rust jac memory "
    "agent context window latency budget team meeting design database index vector "
    "query embedding cache retry timeout schedule weekly report customer feedback"
).split()


def main(n_files: int, lines: int, skills: int, resources: int, out: str) -> None:
    rnd = random.Random(42)
    files = []
    for i in range(n_files):
        body = [f"# topic {i}"]
        for j in range(lines):
            body.append(f"- {' '.join(rnd.choice(WORDS) for _ in range(12))} #{i}.{j}")
        files.append({
            "track": "memory",
            "name": f"topic-{i:04d}",
            "description": " ".join(rnd.choice(WORDS) for _ in range(8)),
            "content": "\n".join(body),
        })
    for i in range(skills):
        files.append({
            "track": "skill",
            "name": f"skill-{i:03d}",
            "description": " ".join(rnd.choice(WORDS) for _ in range(10)),
            "content": "how to " + " ".join(rnd.choice(WORDS) for _ in range(30)),
        })
    res = [
        {"path": f"/data/docs/doc-{i:04d}.md", "description": " ".join(rnd.choice(WORDS) for _ in range(10))}
        for i in range(resources)
    ]
    with open(out, "w", encoding="utf-8") as fh:
        json.dump({"recall_files": files, "resource": res}, fh)


if __name__ == "__main__":
    main(*(int(a) for a in sys.argv[1:5]), sys.argv[5])
