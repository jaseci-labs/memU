import functools;

import ssl;

import from typing { TypedDict }

class UrlopenKwargs(TypedDict, total=False) {
    has context: ssl.SSLContext;
}

def _default_context_has_cas -> bool;
@functools.cache
def ssl_context -> ssl.SSLContext | None;
def urlopen_kwargs -> dict[str, any];
