"""Deterministic memorize session: N messages / tool calls / tool results."""
import json, random, sys
rnd = random.Random(3)
W = "deploy rollout coffee review python rust jac memory agent latency budget team design index vector".split()
items = []
for i in range(int(sys.argv[1])):
    k = i % 4
    text = " ".join(rnd.choice(W) for _ in range(40))
    if k in (0, 1):
        items.append({"type": "message", "role": "user" if k == 0 else "assistant", "content": f"{i}: {text}"})
    elif k == 2:
        items.append({"type": "tool_call", "name": "grep", "arguments": {"q": text[:30], "n": i}})
    else:
        items.append({"type": "tool_result", "name": "grep", "content": {"lines": [text] * 3}})
json.dump({"schema_version": "1.0", "items": items}, open(sys.argv[2], "w"))
