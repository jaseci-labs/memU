import from __future__ { annotations }

import from collections.abc { Mapping }

import from typing { Any }

"""Basic field/`__in` matcher for in-memory repos."""
def matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool;

glob __all__: any = ["matches_where"];
