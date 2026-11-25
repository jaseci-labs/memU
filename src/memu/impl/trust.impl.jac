impl _default_context_has_cas -> bool {
    return `bool(ssl.create_default_context().get_ca_certs());
}

impl ssl_context -> ssl.SSLContext | None {
    try {
        paths: any = ssl.get_default_verify_paths();
        if paths.cafile or paths.capath {
            return None;
        }
        if _default_context_has_cas() {
            return None;
        }
        import certifi;

        return ssl.create_default_context(cafile=certifi.where());
    } except Exception {
        return None;
    }
}

impl urlopen_kwargs -> dict[str, any] {
    context: any = ssl_context();
    return {"context": context} if context is not None else dict[str, any]();
}
