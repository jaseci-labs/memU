import builtins;
import from collections.abc { Iterable }
import from typing { cast }
import numpy as np;
def _cosine(a: np.ndarray, b: np.ndarray) -> float;
def cosine_topk(
    query_vec: list[float], corpus: Iterable[tuple[str, list[float] | None]], k: int = 5
) -> list[tuple[str, float]];
glob __all__ = ["cosine_topk"];
