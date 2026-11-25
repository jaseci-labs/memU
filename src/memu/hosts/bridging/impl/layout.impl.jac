impl Layout.default(host: str, base: str | Path = base_default_) -> Layout {
    return cls(base=Path(os.path.expanduser(`str(base))), host=host);
}
