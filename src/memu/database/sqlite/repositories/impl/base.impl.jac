impl SQLiteRepoBase.init(
    *,
    state: DatabaseState,
    sqla_models: Any,
    sessions: SQLiteSessionManager,
    scope_fields: list[str],
) {
    self._state = state;
    self._sqla_models = sqla_models;
    self._sessions = sessions;
    self._scope_fields = scope_fields;
}

impl SQLiteRepoBase._scope_kwargs_from(`obj: Any) -> dict[str, Any] {
    return {field: getattr(`obj, field, None) for field in self._scope_fields};
}

impl SQLiteRepoBase._normalize_embedding(embedding: Any) -> list[float] | None {
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

impl SQLiteRepoBase._prepare_embedding(embedding: list[float] | None) -> list[float] | None {
    if embedding is None {
        return None;
    }
    return list(embedding);
}

impl SQLiteRepoBase._merge_and_commit(`obj: Any) {
    with self._sessions.session() as session {
        session.merge(`obj);
        session.commit();
    }
}

impl SQLiteRepoBase._now -> pendulum.DateTime {
    return pendulum.now("UTC");
}

impl SQLiteRepoBase._build_filters(model: Any, where: Mapping[str, Any] | None) -> list[Any] {
    if not where {
        return [];
    }
    filters: list[Any] = [];
    for (raw_key, expected) in where.items() {
        if expected is None {
            continue;
        }
        (field, op) = [*raw_key.split("__", 1), None][:2];
        column = getattr(model, str(field), None);
        if column is None {
            msg = f"Unknown filter field '{field}' for model '{model.__name__}'";
            raise ValueError(msg);
        }
        if op == "in" {
            if isinstance(expected, str) {
                filters.append(column == expected);
            } else {
                filters.append(column.in_(expected));
            }
        } else {
            filters.append(column == expected);
        }
    }
    return filters;
}

impl SQLiteRepoBase._matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool {
    if not where {
        return True;
    }
    for (raw_key, expected) in where.items() {
        if expected is None {
            continue;
        }
        (field, op) = [*raw_key.split("__", 1), None][:2];
        actual = getattr(`obj, str(field), None);
        if op == "in" {
            if isinstance(expected, str) {
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
