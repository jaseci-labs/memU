impl _cosine(a: np.ndarray, b: np.ndarray) -> float {
    denom = np.linalg.norm(a) * np.linalg.norm(b) + 1e-09;
    return float(np.dot(a, b) / denom);
}

impl cosine_topk(
    query_vec: list[float], corpus: Iterable[tuple[str, list[float] | None]], k: int = 5
) -> list[tuple[str, float]] {
    if k <= 0 {
        return [];
    }
    q = np.asarray(query_vec, dtype=np.float32);
    if q.ndim != 1 or q.size == 0 or (not np.isfinite(q).all()) {
        return [];
    }
    dim = q.size;
    ids: list[str] = [];
    vecs: list[list[float]] = [];
    for (_id, vec) in corpus {
        if vec is None {
            continue;
        }
        if len(vec) != dim {
            continue;
        }
        ids.append(_id);
        vecs.append(cast(list[float], vec));
    }
    if not vecs {
        return [];
    }
    with np.errstate(over="ignore") {
        matrix = np.array(vecs, dtype=np.float32);
    }
    finite_rows = cast(np.ndarray, np.isfinite(matrix).all(axis=1));
    if not finite_rows.all() {
        matrix = matrix[finite_rows];
        ids = [row_id for (row_id, keep) in builtins.zip(ids, finite_rows, strict=True) if keep];
        if not ids {
            return [];
        }
    }
    q_norm = np.linalg.norm(q);
    vec_norms = np.linalg.norm(matrix, axis=1);
    scores = matrix @ q / (vec_norms * q_norm + 1e-09);
    n = len(scores);
    actual_k = min(k, n);
    if actual_k == n {
        topk_indices = np.argsort(scores)[::-1];
    } else {
        topk_indices = np.argpartition(scores, -actual_k)[-actual_k:];
        topk_indices = topk_indices[np.argsort(scores[topk_indices])[::-1]];
    }
    return [(ids[i], float(scores[i])) for i in topk_indices];
}
