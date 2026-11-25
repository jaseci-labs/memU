impl retry_delay(attempt: int, response: httpx.Response | None = None) -> float {
    if response is not None {
        retry_after: any = response.headers.get("Retry-After");
        if retry_after {
            try {
                return min(max(`float(retry_after), 0.0), _MAX_RETRY_AFTER);
            } except ValueError {
                try {
                    retry_at: any = parsedate_to_datetime(retry_after);
                    now: any = parsedate_to_datetime(response.headers.get("Date", ""));
                    return `float(
                        min(max((retry_at - now).total_seconds(), 0.0), _MAX_RETRY_AFTER)
                    );
                } except (TypeError, ValueError, OverflowError) {}
            }
        }
    }
    return `float(min(_BASE_BACKOFF * 2 ** (attempt - 1), _MAX_BACKOFF));
}
