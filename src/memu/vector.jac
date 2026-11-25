import builtins;
import from collections.abc { Iterable }
import from typing { cast, Optional }
import numpy as np;
def _cosine(a: np.ndarray, b: np.ndarray) -> float;
def cosine_topk(
    query_vec: list[float], corpus: Iterable[tuple[str, Optional[list[float]]]], k: int = 5
) -> list[tuple[str, float]];
glob __all__ = ["cosine_topk"];
