impl is_automatic(event: builtins.dict[builtins.str, Any]) -> builtins.bool {
    origin: any = event.get("origin");
    prompt: any = event.get("prompt");
    return isinstance(origin, `dict) and operator.eq(origin.get("kind"), "task-notification")
        or isinstance(prompt, `str) and prompt.lstrip().startswith("<task-notification>");
}
