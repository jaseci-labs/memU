impl PostgresRepoBase.init(
    *,
    state: DatabaseState,
    sqla_models: Any,
    sessions: SessionManager,
    scope_fields: list[str],
    use_vector: bool = True,
) {
    self._state = state;
    self._sqla_models = sqla_models;
    self._sessions = sessions;
    self._scope_fields = scope_fields;
    self._use_vector = use_vector;
}

impl PostgresRepoBase._scope_kwargs_from(`obj: Any) -> dict[str, Any] {
    return {field: getattr(`obj, field, None) for field in self._scope_fields};
}

impl PostgresRepoBase._normalize_embedding(embedding: Any) -> list[float] | None {
    if embedding is None {
        return None;
    }
    if hasattr(embedding, "to_list") {
        try {
            return [float(x) for x in embedding.to_list()];
        } except Exception {
            logger.debug("Could not convert pgvector value %s", embedding);
            return None;
        }
    }
    if isinstance(embedding, str) {
        stripped = embedding.strip("[]");
        if not stripped {
            return [];
        }
        return [float(x) for x in stripped.split(",")];
    }
    try {
        return [float(x) for x in embedding];
    } except Exception {
        logger.debug("Could not normalize embedding %s", embedding);
        return None;
    }
}

impl PostgresRepoBase._prepare_embedding(embedding: list[float] | None) -> Any {
    if embedding is None {
        return None;
    }
    return embedding;
}

impl PostgresRepoBase._merge_and_commit(`obj: Any) {
    with self._sessions.session() as session {
        session.merge(`obj);
        session.commit();
    }
}

impl PostgresRepoBase._now -> pendulum.DateTime {
    return pendulum.now("UTC");
}

impl PostgresRepoBase._build_filters(model: Any, where: Mapping[str, Any] | None) -> list[Any] {
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

impl PostgresRepoBase._matches_where(`obj: Any, where: Mapping[str, Any] | None) -> bool {
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
