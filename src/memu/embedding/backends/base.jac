import builtins;

import from __future__ { annotations }

import from typing { Any }

"""Defines how to talk to a specific embedding provider.

    Each provider lives in its own module under :mod:`memu.embedding.backends`
    and customizes the request endpoint, payload shape, response parsing and
    (when needed) the auth headers.
    """
obj EmbeddingBackend {
    static has name: any = "base";

    static has embedding_endpoint: any = "/embeddings";

    """Auth/request headers for this provider.

        Defaults to OpenAI-style bearer auth; providers with a different scheme
        override this.
        """
    def default_headers(api_key: str) -> dict[str, str];

    def build_embedding_payload(*, inputs: list[str], embed_model: str) -> dict[str, Any];

    def parse_embedding_response(data: dict[str, Any]) -> list[list[float]];

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
