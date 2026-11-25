import from typing { Annotated, Literal, Self, TypeAlias, Union }
import from pydantic { BaseModel, ConfigDict, Field, JsonValue, model_validator }

class InputModel(BaseModel) {
    static has model_config: any = ConfigDict(extra="forbid");
}

class MessageInput(InputModel) {
    has `type: Literal["message"] = "message",
        role: Literal["user", "assistant"],
        content: str = Field(min_length=1);
}

class ToolCallInput(InputModel) {
    has `type: Literal["tool_call"] = "tool_call",
        name: str = Field(min_length=1),
        arguments: JsonValue = Field(default_factory=dict[any, any]);
}

class ToolResultInput(InputModel) {
    has `type: Literal["tool_result"] = "tool_result",
        content: JsonValue,
        name: str | None = Field(default=None, min_length=1),
        is_error: bool | None = None;
}

glob ConversationItem: any;

with entry {
    ConversationItem = Annotated[Union[MessageInput, ToolCallInput, ToolResultInput], Field(
        discriminator="type"
    )];
}

class MemorizeInput(InputModel) {
    has schema_version: Literal["1.0"] = "1.0",
        items: list[ConversationItem] = Field(min_length=1);
    @model_validator(mode="after")
    def require_message -> Self;
}

glob MemoryInputItem: any;

with entry {
    MemoryInputItem = MessageInput;
}

glob SkillInputItem: any;

with entry {
    SkillInputItem = Union[MessageInput, ToolCallInput, ToolResultInput];
}

def project_memory(memorize_input: MemorizeInput) -> list[MemoryInputItem];
def project_skill(memorize_input: MemorizeInput) -> list[SkillInputItem];
glob __all__ = [
    "ConversationItem",
    "MemorizeInput",
    "MessageInput",
    "ToolCallInput",
    "ToolResultInput",
    "project_memory",
    "project_skill",
];
