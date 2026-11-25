import from typing { Type }
import asyncio;
import from collections.abc { Mapping }
import from typing { Any }
import httpx;
glob DEFAULT_CLOUD_BASE_URL = "https://api.memu.so/api/v4/memory/",
     DEFAULT_SCOPE = "default",
     _USER_FIELDS = {"user_id", "agent_id", "user_name", "agent_name"},
     _WHERE_FIELDS = {"user_id", "agent_id"};

class CloudMemoryError(RuntimeError) {
    has code: str | None,
        status_code: int | None;
    def init(message: str, *, status_code: int | None = None, code: str | None = None);
}

class CloudClientConfigurationError(ValueError) {
    class def empty_api_key -> CloudClientConfigurationError;
    class def invalid_attempts -> CloudClientConfigurationError;
    class def unsupported_where(fields: list[str]) -> CloudClientConfigurationError;
    class def unsupported_user(fields: list[str]) -> CloudClientConfigurationError;
}

class CloudAuthenticationError(CloudMemoryError) {}

class CloudAuthorizationError(CloudMemoryError) {}

class CloudValidationError(CloudMemoryError) {}

class CloudRateLimitError(CloudMemoryError) {}

class CloudTransportError(CloudMemoryError) {
    class def from_transport(exc: Exception) -> CloudTransportError;
}

class CloudServiceError(CloudMemoryError) {
    class def invalid_json(status_code: int) -> CloudServiceError;
    class def unexpected_shape(status_code: int) -> CloudServiceError;
    class def unreachable_retry_state -> CloudServiceError;
}

class CloudMemoryClient {
    has transport: httpx.AsyncBaseTransport | None,
        max_attempts: int,
        timeout: any,
        api_key: str,
        base_url: any;
    def init(
        *,
        base_url: str = DEFAULT_CLOUD_BASE_URL,
        api_key: str,
        timeout: httpx.Timeout | None = None,
        max_attempts: int = 3,
        transport: httpx.AsyncBaseTransport | None = None,
    );
    async def list_all_recall_files(
        where: dict[str, Any] | None = None, *, cursor: str | None = None, limit: int | None = None
    ) -> dict[str, Any];
    async def progressive_retrieve(
        query: str, where: dict[str, Any] | None = None
    ) -> dict[str, Any];
    async def commit_results(
        *,
        recall_files: list[dict[str, Any]] | None = None,
        resource: list[dict[str, Any]] | None = None,
        user: dict[str, Any] | None = None,
    ) -> dict[str, Any];
    static def _scope(where: Mapping[str, Any] | None) -> dict[str, str];
    static def _scope_value(value: Any) -> str;
    static def _user(user: Mapping[str, Any] | None) -> dict[str, Any];
    async def _request(
        method: str,
        endpoint: str,
        *,
        params: dict[str, str] | None = None,
        json: dict[str, Any] | None = None,
    ) -> dict[str, Any];
    static def _response_error(response: httpx.Response) -> CloudMemoryError;
    static def _error_details(response: httpx.Response) -> tuple[str, str | None];
    static def _error_category(status: int) -> tuple[Type[CloudMemoryError], str];
}
