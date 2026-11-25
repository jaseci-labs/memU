impl text(message: builtins.str, **values: builtins.str) -> builtins.str {
    translated: any = _EN.get(message, message) if LANGUAGE.get() == "en" else message;
    return translated.format(**values) if values else translated;
}
