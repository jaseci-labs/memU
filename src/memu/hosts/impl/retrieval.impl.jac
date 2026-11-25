impl render_context(memories: dict[str, Any], *, original: dict[str, Any] | None = None) -> str {
    original = memories if original is None else original;
    payload = {
        **memories,
        "context_counts": {
            "returned": {layer: len(memories.get(layer, [])) for layer in ("hits", "resources")},
            "omitted": {
                layer: len(original.get(layer, [])) - len(memories.get(layer, []))
                for layer in ("hits", "resources")
            },
        },
    };
    return CONTEXT_PREFIX + json.dumps(payload, ensure_ascii=False, separators=(",", ":"));
}

impl retrieve(
    query: str, where: dict[str, Any] | None = None, *, query_kind: QueryKind | None = None
) -> dict[str, Any] {
    kind = query_kind
        or ("long" if sum((not c.isspace() for c in query)) >= LONG_QUERY_CHARS else "short");
    min_score = retrieval_min_score(kind);
    backend = build_agentic_memory_backend_from_env();
    result: dict[str, Any] = await backend.progressive_retrieve(query, where=where);
    segment_count = len(result.get("segments", []));
    if min_score is not None {
        result["segments"] = [s for s in result.get("segments", []) if s["score"] >= min_score];
        file_ids = {s["recall_file_id"] for s in result["segments"]};
        result["files"] = [f for f in result.get("files", []) if f["id"] in file_ids];
    }
    shaped = _shape_for_agent(result);
    shaped["retrieval_status"] = {
        "status": "succeeded",
        "query_kind": kind,
        "min_score": min_score,
        "candidate_segments": segment_count,
        "filtered_segments": segment_count - len(result.get("segments", [])),
        "retained_segments": len(result.get("segments", [])),
        "returned_hits": len(shaped["hits"]),
    };
    return shaped;
}

impl _shape_for_agent(result: dict[str, Any]) -> dict[str, Any] {
    base = Path(os.path.expanduser(BASE_DIR));
    sources: dict[str, dict[str, Any]] = {};
    files = result.get("files", []);
    for file in files {
        source: dict[str, Any] = {
            key: file[key]
            for key in ("description", "track", "created_at", "updated_at")
            if key in file
        };
        subdir = TRACK_DIRS.get(file.get("track") or "");
        if subdir is not None
            and file.get("name")
            and ((path := write_recall_file(base, subdir, file)) is not None)
        {
            source["path"] = str(path);
        } elif "content" in file {
            source["content"] = file["content"];
        }
        sources[file["id"]] = source;
    }
    hits: list[any] = [];
    matched_files: set[any] = set();
    for segment in result.get("segments", []) {
        file_id = segment.get("recall_file_id");
        hit = {key: segment[key] for key in ("text", "track", "score") if key in segment};
        hit.update(sources.get(file_id, {}));
        hits.append(hit);
        matched_files.add(file_id);
    }
    for file in files {
        if file["id"] not in matched_files {
            hit = dict(sources[file["id"]]);
            if "score" in file {
                hit["score"] = file["score"];
            }
            hits.append(hit);
        }
    }
    resources: list[any] = [];
    for resource in result.get("resources", []) {
        item = {
            key: resource[key]
            for key in ("caption", "score", "created_at", "updated_at")
            if key in resource
        };
        path = resource.get("url", resource.get("local_path"));
        if path is not None {
            item["path"] = path;
        }
        resources.append(item);
    }
    return {"hits": hits[:5], "resources": resources};
}

impl _cmd_retrieve(args: argparse.Namespace) -> int {
    query = args.query;
    if args.query_stdin {
        reconfigure = getattr(sys.stdin, "reconfigure", None);
        if reconfigure is not None {
            reconfigure(encoding="utf-8", newline="");
        }
        query = sys.stdin.read();
    }
    started = time.monotonic();
    try {
        result = await retrieve(query, query_kind=args.query_kind)
            if args.query_kind
            else await retrieve(query);
    } except Exception {
        events.record_outcome(
            events.MEMORY_SEARCH_SUCCEEDED,
            events.MEMORY_SEARCH_FAILED,
            host=args.host,
            session_id_env=args.session_id_env,
            success=False,
            deliver=True,
            result_count=0,
            latency_ms=round((time.monotonic() - started) * 1000),
        );
        raise;
    }
    latency_ms = round((time.monotonic() - started) * 1000);
    print(json.dumps(result, separators=(",", ":"), ensure_ascii=False, default=str));
    events.record_outcome(
        events.MEMORY_SEARCH_SUCCEEDED,
        events.MEMORY_SEARCH_FAILED,
        host=args.host,
        session_id_env=args.session_id_env,
        success=True,
        deliver=True,
        result_count=events.counts(result, layers=("hits", "resources")),
        latency_ms=latency_ms,
    );
    return 0;
}

impl register(sub: Any, *, host: str = "", session_id_env: str = "") {
    parser = sub.add_parser(
        "retrieve",
        help="LLM-free single-shot retrieval over memory, skills, and resources (what the inject hook runs)",
    );
    query = parser.add_mutually_exclusive_group(required=True);
    query.add_argument("query", nargs="?", help="Natural-language query");
    query.add_argument(
        "--query-stdin", action="store_true", help="Read the complete UTF-8 query from stdin"
    );
    parser.add_argument(
        "--query-kind",
        choices=("short", "long", "extracted"),
        help="Score cutoff category; defaults to short/long by 200 non-whitespace characters",
    );
    parser.set_defaults(handler=_cmd_retrieve, host=host, session_id_env=session_id_env);
}
