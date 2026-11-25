impl SQLiteRepoBase._normalize_embedding(embedding: Any) -> Optional[list[float]] {
    if embedding is None {
        return None;
    }
    if isinstance(embedding, str) {
        try {
            return [float(x) for x in json.loads(embedding)];
        } except (json.JSONDecodeError, TypeError) {
            logger.debug("Could not parse embedding JSON: %s", embedding);
            return None;
        }
    }
    try {
        return [float(x) for x in embedding];
    } except (ValueError, TypeError, OverflowError) {
        logger.debug("Could not normalize embedding %s", embedding);
        return None;
    }
}

impl SQLiteRepoBase._prepare_embedding(embedding: Optional[list[float]]) -> Optional[list[float]] {
    if embedding is None {
        return None;
    }
    return list(embedding);
}
