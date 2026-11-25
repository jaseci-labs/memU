impl MemorizeInput.require_message -> Self {
    if not any((isinstance(item, MessageInput) for item in self.items)) {
        msg = "memorize input must contain at least one message";
        raise ValueError(msg);
    }
    return self;
}

impl project_memory(memorize_input: MemorizeInput) -> list[MemoryInputItem] {
    return [item for item in memorize_input.items if isinstance(item, MessageInput)];
}

impl project_skill(memorize_input: MemorizeInput) -> list[SkillInputItem] {
    return list(memorize_input.items);
}
