import from email.utils { parsedate_to_datetime }

import httpx;

glob RETRYABLE_STATUS_CODES: any = {408, 429, 500, 502, 503, 504},
     DEFAULT_MAX_ATTEMPTS: any = 3,
     _MAX_RETRY_AFTER: any = 30.0,
     _BASE_BACKOFF: any = 0.25,
     _MAX_BACKOFF: any = 2.0;
def retry_delay(attempt: int, response: httpx.Response | None = None) -> float;
