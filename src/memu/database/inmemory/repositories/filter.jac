import from collections.abc { Mapping }

import from typing { Any }

def matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool {
    if not where {
        return True;
    }
    for (raw_key, expected) in where.items() {
        if expected is None {
            continue;
        }
        field: any;
        op: any;
        (field, op) = [*raw_key.split("__", 1), None][:2] as any;
        actual: any = getattr(`obj, `str(field), None);
        if op == "in" {
            if isinstance(expected, `str) {
                if actual != expected {
                    return False;
                }
            } else {
                try {
                    if actual not in expected {
                        return False;
                    }
                } except TypeError {
                    return False;
                }
            }
        } elif actual != expected {
            return False;
        }
    }
    return True;
}
