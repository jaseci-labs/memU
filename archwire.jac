graph layers {
    layer all { *; }
}

graph spaces {
    space memu_cli: node { "npm"; }
    space memu: cpython { "."; }

    package memu { ship memu; }
    space memu_dev: cpython { scripts.* | tests | tests.*; }
}

graph import {
    src.memu.app.service --> src.memu { MemoryService }
    src.memu.app.agentic --> src.memu.app.service { AgenticMixin }
    src.memu.app.client_pool --> src.memu.app.service { ClientPool }
    src.memu.app.settings --> src.memu.app.service {
        DatabaseConfig,
        EmbeddingConfig,
        EmbeddingProfilesConfig,
        ProgressiveRetrieveConfig,
        UserConfig,
    }
    src.memu.database.factory --> src.memu.app.service { build_database }
    src.memu.database.interfaces --> src.memu.app.service { Database }
    src.memu.embedding.gateway --> src.memu.app.service { build_embedding_client }
    src.memu.database.interfaces --> src.memu.app.agentic { AtomicDatabase, Database }
    src.memu.app.settings --> src.memu.app.agentic { ProgressiveRetrieveConfig }
    src.memu.database.models --> src.memu.app.agentic { RecallFile, Resource }
    src.memu.database.models --> src.memu.database.interfaces {
        RecallFile,
        RecallFileSegment,
        Resource,
    }
    src.memu.database.repositories --> src.memu.database.interfaces {
        RecallFileRepo,
        RecallFileSegmentRepo,
        ResourceRepo,
    }
    src.memu.database.repositories.recall_file --> src.memu.database.repositories { RecallFileRepo }
    src.memu.database.repositories.recall_file_segment --> src.memu.database.repositories {
        RecallFileSegmentRepo,
    }
    src.memu.database.repositories.resource --> src.memu.database.repositories { ResourceRepo }
    src.memu.database.models --> src.memu.database.repositories.recall_file { RecallFile }
    src.memu.database.models --> src.memu.database.repositories.recall_file_segment {
        RecallFileSegment,
    }
    src.memu.vector --> src.memu.database.repositories.recall_file_segment { cosine_topk }
    src.memu.database.models --> src.memu.database.repositories.resource { Resource }
    src.memu.embedding.defaults --> src.memu.app.settings {
        EMBEDDING_PROVIDER_ENDPOINTS,
        EMBEDDING_SDK_BASE_URLS,
        default_embedding_model,
    }
    src.memu.app.settings --> src.memu.database.factory { DatabaseConfig }
    src.memu.database.inmemory --> src.memu.database.factory { build_inmemory_database }
    src.memu.database.interfaces --> src.memu.database.factory { Database }
    src.memu.database.postgres --> src.memu.database.factory { build_postgres_database }
    src.memu.database.sqlite --> src.memu.database.factory { build_sqlite_database }
    src.memu.app.settings --> src.memu.database.inmemory { DatabaseConfig }
    src.memu.database.inmemory.models --> src.memu.database.inmemory { build_inmemory_models }
    src.memu.database.inmemory.repo --> src.memu.database.inmemory { InMemoryStore }
    src.memu.database.models --> src.memu.database.inmemory.models {
        RecallFile,
        RecallFileSegment,
        Resource,
        merge_scope_model,
    }
    src.memu.database.inmemory.models --> src.memu.database.inmemory.repo { build_inmemory_models }
    src.memu.database.inmemory.repositories --> src.memu.database.inmemory.repo {
        InMemoryFileSegmentRepository,
        InMemoryRecallFileRepository,
        InMemoryResourceRepository,
    }
    src.memu.database.inmemory.state --> src.memu.database.inmemory.repo { InMemoryState }
    src.memu.database.interfaces --> src.memu.database.inmemory.repo { Database }
    src.memu.database.models --> src.memu.database.inmemory.repo {
        RecallFile,
        RecallFileSegment,
        Resource,
    }
    src.memu.database.repositories --> src.memu.database.inmemory.repo {
        RecallFileRepo,
        ResourceRepo,
    }
    src.memu.database.transaction --> src.memu.database.inmemory.repo { preserve_state }
    src.memu.database.inmemory.repositories.recall_file_repo --> src.memu.database.inmemory.repositories {
        InMemoryRecallFileRepository,
        RecallFileRepo,
    }
    src.memu.database.inmemory.repositories.recall_file_segment_repo --> src.memu.database.inmemory.repositories {
        InMemoryFileSegmentRepository,
        RecallFileSegmentRepo,
    }
    src.memu.database.inmemory.repositories.resource_repo --> src.memu.database.inmemory.repositories {
        InMemoryResourceRepository,
        ResourceRepo,
    }
    src.memu.database.inmemory.repositories.filter --> src.memu.database.inmemory.repositories.recall_file_repo {
        matches_where,
    }
    src.memu.database.inmemory.state --> src.memu.database.inmemory.repositories.recall_file_repo {
        InMemoryState,
    }
    src.memu.database.models --> src.memu.database.inmemory.repositories.recall_file_repo {
        RecallFile,
    }
    src.memu.database.repositories.recall_file --> src.memu.database.inmemory.repositories.recall_file_repo {
        RecallFileRepo,
    }
    src.memu.database.state --> src.memu.database.inmemory.state { DatabaseState }
    src.memu.database.models --> src.memu.database.state { RecallFile, RecallFileSegment, Resource }
    src.memu.database.inmemory.repositories.filter --> src.memu.database.inmemory.repositories.recall_file_segment_repo {
        matches_where,
    }
    src.memu.database.inmemory.state --> src.memu.database.inmemory.repositories.recall_file_segment_repo {
        InMemoryState,
    }
    src.memu.database.models --> src.memu.database.inmemory.repositories.recall_file_segment_repo {
        RecallFileSegment,
    }
    src.memu.database.repositories.recall_file_segment --> src.memu.database.inmemory.repositories.recall_file_segment_repo {
        RecallFileSegmentRepo,
    }
    src.memu.database.inmemory.repositories.filter --> src.memu.database.inmemory.repositories.resource_repo {
        matches_where,
    }
    src.memu.database.inmemory.state --> src.memu.database.inmemory.repositories.resource_repo {
        InMemoryState,
    }
    src.memu.database.models --> src.memu.database.inmemory.repositories.resource_repo { Resource }
    src.memu.database.repositories.resource --> src.memu.database.inmemory.repositories.resource_repo {
        ResourceRepo,
    }
    src.memu.vector --> src.memu.database.inmemory.repositories.resource_repo { cosine_topk }
    src.memu.database.state --> src.memu.database.transaction { DatabaseState }
    src.memu.app.settings --> src.memu.database.postgres { DatabaseConfig }
    src.memu.database.postgres.postgres --> src.memu.database.postgres { PostgresStore }
    src.memu.database.postgres.schema --> src.memu.database.postgres {
        SQLAModels,
        get_sqlalchemy_models,
    }
    src.memu.database.interfaces --> src.memu.database.postgres.postgres { Database }
    src.memu.database.models --> src.memu.database.postgres.postgres {
        RecallFile,
        RecallFileSegment,
        Resource,
    }
    src.memu.database.postgres.migration --> src.memu.database.postgres.postgres {
        DDLMode,
        run_migrations,
    }
    src.memu.database.postgres.repositories.recall_file_repo --> src.memu.database.postgres.postgres {
        PostgresRecallFileRepo,
    }
    src.memu.database.postgres.repositories.recall_file_segment_repo --> src.memu.database.postgres.postgres {
        PostgresRecallFileSegmentRepo,
    }
    src.memu.database.postgres.repositories.resource_repo --> src.memu.database.postgres.postgres {
        PostgresResourceRepo,
    }
    src.memu.database.postgres.schema --> src.memu.database.postgres.postgres {
        SQLAModels,
        get_sqlalchemy_models,
        require_sqlalchemy,
    }
    src.memu.database.postgres.session --> src.memu.database.postgres.postgres { SessionManager }
    src.memu.database.repositories --> src.memu.database.postgres.postgres {
        RecallFileRepo,
        RecallFileSegmentRepo,
        ResourceRepo,
    }
    src.memu.database.state --> src.memu.database.postgres.postgres { DatabaseState }
    src.memu.database.postgres.schema --> src.memu.database.postgres.migration { get_metadata }
    src.memu.app.settings --> src.memu.database.postgres.schema { DefaultUserModel }
    src.memu.database.postgres.models --> src.memu.database.postgres.schema {
        RecallFileModel,
        RecallFileSegmentModel,
        ResourceModel,
        build_table_model,
    }
    src.memu.database.models --> src.memu.database.postgres.models {
        RecallFile,
        RecallFileSegment,
        Resource,
    }
    src.memu.database.models --> src.memu.database.postgres.repositories.recall_file_repo {
        RecallFile,
    }
    src.memu.database.postgres.repositories.base --> src.memu.database.postgres.repositories.recall_file_repo {
        PostgresRepoBase,
    }
    src.memu.database.postgres.session --> src.memu.database.postgres.repositories.recall_file_repo {
        SessionManager,
    }
    src.memu.database.repositories.recall_file --> src.memu.database.postgres.repositories.recall_file_repo {
        RecallFileRepo,
    }
    src.memu.database.state --> src.memu.database.postgres.repositories.recall_file_repo {
        DatabaseState,
    }
    src.memu.database.postgres.session --> src.memu.database.postgres.repositories.base {
        SessionManager,
    }
    src.memu.database.state --> src.memu.database.postgres.repositories.base { DatabaseState }
    src.memu.database.models --> src.memu.database.postgres.repositories.recall_file_segment_repo {
        RecallFileSegment,
    }
    src.memu.database.postgres.repositories.base --> src.memu.database.postgres.repositories.recall_file_segment_repo {
        PostgresRepoBase,
    }
    src.memu.database.postgres.session --> src.memu.database.postgres.repositories.recall_file_segment_repo {
        SessionManager,
    }
    src.memu.database.repositories.recall_file_segment --> src.memu.database.postgres.repositories.recall_file_segment_repo {
        RecallFileSegmentRepo,
    }
    src.memu.database.state --> src.memu.database.postgres.repositories.recall_file_segment_repo {
        DatabaseState,
    }
    src.memu.database.models --> src.memu.database.postgres.repositories.resource_repo { Resource }
    src.memu.database.postgres.repositories.base --> src.memu.database.postgres.repositories.resource_repo {
        PostgresRepoBase,
    }
    src.memu.database.postgres.session --> src.memu.database.postgres.repositories.resource_repo {
        SessionManager,
    }
    src.memu.database.repositories.resource --> src.memu.database.postgres.repositories.resource_repo {
        ResourceRepo,
    }
    src.memu.database.state --> src.memu.database.postgres.repositories.resource_repo {
        DatabaseState,
    }
    src.memu.vector --> src.memu.database.postgres.repositories.resource_repo { cosine_topk }
    src.memu.app.settings --> src.memu.database.sqlite { DatabaseConfig }
    src.memu.database.sqlite.sqlite --> src.memu.database.sqlite { SQLiteStore }
    src.memu.database.interfaces --> src.memu.database.sqlite.sqlite { Database }
    src.memu.database.models --> src.memu.database.sqlite.sqlite {
        RecallFile,
        RecallFileSegment,
        Resource,
        build_scoped_models,
    }
    src.memu.database.repositories --> src.memu.database.sqlite.sqlite {
        RecallFileRepo,
        RecallFileSegmentRepo,
        ResourceRepo,
    }
    src.memu.database.sqlite.repositories.recall_file_repo --> src.memu.database.sqlite.sqlite {
        SQLiteRecallFileRepo,
    }
    src.memu.database.sqlite.repositories.recall_file_segment_repo --> src.memu.database.sqlite.sqlite {
        SQLiteRecallFileSegmentRepo,
    }
    src.memu.database.sqlite.repositories.resource_repo --> src.memu.database.sqlite.sqlite {
        SQLiteResourceRepo,
    }
    src.memu.database.sqlite.schema --> src.memu.database.sqlite.sqlite {
        SQLiteSQLAModels,
        get_sqlite_sqlalchemy_models,
    }
    src.memu.database.sqlite.session --> src.memu.database.sqlite.sqlite { SQLiteSessionManager }
    src.memu.database.state --> src.memu.database.sqlite.sqlite { DatabaseState }
    src.memu.database.transaction --> src.memu.database.sqlite.sqlite { preserve_state }
    src.memu.database.models --> src.memu.database.sqlite.repositories.recall_file_repo {
        RecallFile,
    }
    src.memu.database.repositories.recall_file --> src.memu.database.sqlite.repositories.recall_file_repo {
        RecallFileRepo,
    }
    src.memu.database.sqlite.repositories.base --> src.memu.database.sqlite.repositories.recall_file_repo {
        SQLiteRepoBase,
    }
    src.memu.database.sqlite.schema --> src.memu.database.sqlite.repositories.recall_file_repo {
        SQLiteSQLAModels,
    }
    src.memu.database.sqlite.session --> src.memu.database.sqlite.repositories.recall_file_repo {
        SQLiteSessionManager,
    }
    src.memu.database.state --> src.memu.database.sqlite.repositories.recall_file_repo {
        DatabaseState,
    }
    src.memu.database.sqlite.session --> src.memu.database.sqlite.repositories.base {
        SQLiteSessionManager,
    }
    src.memu.database.state --> src.memu.database.sqlite.repositories.base { DatabaseState }
    src.memu.database.transaction --> src.memu.database.sqlite.session { AtomicSessionManager }
    src.memu.database.sqlite.models --> src.memu.database.sqlite.schema {
        SQLiteRecallFileModel,
        SQLiteRecallFileSegmentModel,
        SQLiteResourceModel,
        build_sqlite_table_model,
    }
    src.memu.database.models --> src.memu.database.sqlite.models {
        RecallFile,
        RecallFileSegment,
        Resource,
    }
    src.memu.database.models --> src.memu.database.sqlite.repositories.recall_file_segment_repo {
        RecallFileSegment,
    }
    src.memu.database.repositories.recall_file_segment --> src.memu.database.sqlite.repositories.recall_file_segment_repo {
        RecallFileSegmentRepo,
    }
    src.memu.database.sqlite.repositories.base --> src.memu.database.sqlite.repositories.recall_file_segment_repo {
        SQLiteRepoBase,
    }
    src.memu.database.sqlite.schema --> src.memu.database.sqlite.repositories.recall_file_segment_repo {
        SQLiteSQLAModels,
    }
    src.memu.database.sqlite.session --> src.memu.database.sqlite.repositories.recall_file_segment_repo {
        SQLiteSessionManager,
    }
    src.memu.database.state --> src.memu.database.sqlite.repositories.recall_file_segment_repo {
        DatabaseState,
    }
    src.memu.database.models --> src.memu.database.sqlite.repositories.resource_repo { Resource }
    src.memu.database.repositories.resource --> src.memu.database.sqlite.repositories.resource_repo {
        ResourceRepo,
    }
    src.memu.database.sqlite.repositories.base --> src.memu.database.sqlite.repositories.resource_repo {
        SQLiteRepoBase,
    }
    src.memu.database.sqlite.schema --> src.memu.database.sqlite.repositories.resource_repo {
        SQLiteSQLAModels,
    }
    src.memu.database.sqlite.session --> src.memu.database.sqlite.repositories.resource_repo {
        SQLiteSessionManager,
    }
    src.memu.database.state --> src.memu.database.sqlite.repositories.resource_repo {
        DatabaseState,
    }
    src.memu.vector --> src.memu.database.sqlite.repositories.resource_repo { cosine_topk }
    src.memu.app.settings --> src.memu.embedding.gateway { EmbeddingConfig }
    src.memu.embedding.openai_sdk --> src.memu.embedding.gateway { OpenAIEmbeddingSDKClient }
    src.memu.embedding.http_client --> src.memu.embedding.gateway { HTTPEmbeddingClient }
    src.memu.embedding.http_client --> src.memu.embedding.openai_sdk {
        _load_proxy,
        proxy_bypass_mounts,
    }
    src.memu.embedding.backends.base --> src.memu.embedding.http_client { EmbeddingBackend }
    src.memu.embedding.backends.doubao --> src.memu.embedding.http_client {
        DoubaoEmbeddingBackend,
        DoubaoMultimodalEmbeddingInput,
    }
    src.memu.embedding.backends.jina --> src.memu.embedding.http_client { JinaEmbeddingBackend }
    src.memu.embedding.backends.openai --> src.memu.embedding.http_client { OpenAIEmbeddingBackend }
    src.memu.embedding.backends.openrouter --> src.memu.embedding.http_client {
        OpenRouterEmbeddingBackend,
    }
    src.memu.embedding.backends.voyage --> src.memu.embedding.http_client { VoyageEmbeddingBackend }
    src.memu.retry --> src.memu.embedding.http_client {
        DEFAULT_MAX_ATTEMPTS,
        RETRYABLE_STATUS_CODES,
        retry_delay,
    }
    src.memu.env --> src.memu.embedding.http_client { env }
    src.memu.embedding.backends.base --> src.memu.embedding.backends.doubao { EmbeddingBackend }
    src.memu.embedding.backends.base --> src.memu.embedding.backends.jina { EmbeddingBackend }
    src.memu.embedding.backends.base --> src.memu.embedding.backends.openai { EmbeddingBackend }
    src.memu.embedding.backends.base --> src.memu.embedding.backends.openrouter { EmbeddingBackend }
    src.memu.embedding.backends.base --> src.memu.embedding.backends.voyage { EmbeddingBackend }
    src.memu.agentic_backend --> src.memu.env { AgenticMemoryBackend }
    src.memu.cloud --> src.memu.env { CloudMemoryClient, DEFAULT_CLOUD_BASE_URL }
    src.memu.app --> src.memu.env { MemoryService }
    src.memu.embedding.http_client --> src.memu.cloud { proxy_bypass_mounts }
    src.memu.env --> src.memu.cloud { env }
    src.memu.retry --> src.memu.cloud { RETRYABLE_STATUS_CODES, retry_delay }
    src.memu.app.memorize --> src.memu.app {
        ConversationItem,
        MaterializedConversation,
        MemorizeInput,
        MemorizeWorkspace,
        MessageInput,
        PreparedMemorizeRun,
        ToolCallInput,
        ToolResultInput,
        commit_memorize,
        materialize_memorize_input,
        prepare_memorize,
        project_memory,
        project_skill,
    }
    src.memu.app.service --> src.memu.app { MemoryService }
    src.memu.app.settings --> src.memu.app {
        DatabaseConfig,
        DefaultUserModel,
        EmbeddingConfig,
        EmbeddingProfilesConfig,
        ProgressiveRetrieveConfig,
        UserConfig,
    }
    src.memu.app.memorize.input --> src.memu.app.memorize {
        ConversationItem,
        MemorizeInput,
        MessageInput,
        ToolCallInput,
        ToolResultInput,
        project_memory,
        project_skill,
    }
    src.memu.app.memorize.lifecycle --> src.memu.app.memorize {
        MemorizeWorkspace,
        PreparedMemorizeRun,
        commit_memorize,
        prepare_memorize,
    }
    src.memu.app.memorize.materialize --> src.memu.app.memorize {
        MaterializedConversation,
        materialize_memorize_input,
    }
    src.memu.agentic_backend --> src.memu.app.memorize.lifecycle { AgenticMemoryBackend }
    src.memu.app.memorize.input --> src.memu.app.memorize.lifecycle { MemorizeInput }
    src.memu.app.memorize.materialize --> src.memu.app.memorize.lifecycle {
        MaterializedConversation,
        _atomic_write_text,
        materialize_memorize_inputs,
    }
    src.memu.hosts.templates --> src.memu.app.memorize.lifecycle;
    src.memu.hosts.bridging.instructions --> src.memu.app.memorize.lifecycle {
        MEMORY_JOB_TEMPLATE,
        SKILL_JOB_TEMPLATE,
        prepare_instruction_jobs,
    }
    src.memu.hosts.bridging.layout --> src.memu.app.memorize.lifecycle { TRACK_DIRS }
    src.memu.hosts.bridging.manifest --> src.memu.app.memorize.lifecycle {
        diff_tracked,
        snapshot_tracked,
    }
    src.memu.hosts.bridging.recall_files --> src.memu.app.memorize.lifecycle {
        finalize_recall_file,
        read_recall_file,
        write_recall_file,
    }
    src.memu.hosts.bridging.resources --> src.memu.app.memorize.lifecycle {
        RESOURCE_JOB_TEMPLATE,
        prepare_resource_job,
        read_resources,
    }
    src.memu.app.memorize.input --> src.memu.app.memorize.materialize {
        MemorizeInput,
        SkillInputItem,
        project_memory,
        project_skill,
    }
    src.memu.trust --> src.memu.hosts.templates;
    src.memu.hosts.bridging.layout --> src.memu.hosts.templates { BASE_DIR }
    src.memu.cli --> src.memu.__main__ { main }
    src.memu.events --> src.memu.cli;
    src.memu.agentic_backend --> src.memu.cli { AgenticMemoryBackend }
    src.memu.app.memorize.input --> src.memu.cli { MemorizeInput }
    src.memu.app.memorize.lifecycle --> src.memu.cli {
        MemorizeWorkspace,
        PreparedMemorizeRun,
        commit_memorize,
        prepare_memorize,
    }
    src.memu.env --> src.memu.cli { build_agentic_memory_backend_from_env, embedding_provider, env }
    src.memu.hosts.bridging.resources --> src.memu.cli { verify_resource_log }
    src.memu.config_file --> src.memu.events;
    src.memu.trust --> src.memu.events;
    src.memu.env --> src.memu.events { env, env_declared, memory_mode, reload }
    src.memu --> src.memu.events { __version__ }
    src.memu.env --> src.memu.config_file { CONFIG_ENV, read_config }
    src.memu.database.factory --> src.memu.database { build_database }
    src.memu.database.interfaces --> src.memu.database {
        Database,
        RecallFileRecord,
        RecallFileSegmentRecord,
        ResourceRecord,
    }
    src.memu.database.repositories --> src.memu.database {
        RecallFileRepo,
        RecallFileSegmentRepo,
        ResourceRepo,
    }
    src.memu.vector --> src.memu.database.inmemory.vector { _cosine, cosine_topk }
    src.memu.database.postgres.schema --> src.memu.database.postgres.migrations.env { get_metadata }
    src.memu.database.postgres.repositories.recall_file_repo --> src.memu.database.postgres.repositories {
        PostgresRecallFileRepo,
    }
    src.memu.database.postgres.repositories.recall_file_segment_repo --> src.memu.database.postgres.repositories {
        PostgresRecallFileSegmentRepo,
    }
    src.memu.database.postgres.repositories.resource_repo --> src.memu.database.postgres.repositories {
        PostgresResourceRepo,
    }
    src.memu.database.sqlite.repositories.base --> src.memu.database.sqlite.repositories {
        SQLiteRepoBase,
    }
    src.memu.database.sqlite.repositories.recall_file_repo --> src.memu.database.sqlite.repositories {
        SQLiteRecallFileRepo,
    }
    src.memu.database.sqlite.repositories.recall_file_segment_repo --> src.memu.database.sqlite.repositories {
        SQLiteRecallFileSegmentRepo,
    }
    src.memu.database.sqlite.repositories.resource_repo --> src.memu.database.sqlite.repositories {
        SQLiteResourceRepo,
    }
    src.memu.embedding.base --> src.memu.embedding { EmbeddingClient }
    src.memu.embedding.defaults --> src.memu.embedding {
        EMBEDDING_PROVIDER_DEFAULTS,
        EMBEDDING_PROVIDER_ENDPOINTS,
        default_embedding_model,
    }
    src.memu.embedding.gateway --> src.memu.embedding { build_embedding_client }
    src.memu.embedding.http_client --> src.memu.embedding { HTTPEmbeddingClient }
    src.memu.embedding.openai_sdk --> src.memu.embedding { OpenAIEmbeddingSDKClient }
    src.memu.embedding.backends.base --> src.memu.embedding.backends { EmbeddingBackend }
    src.memu.embedding.backends.doubao --> src.memu.embedding.backends {
        DoubaoEmbeddingBackend,
        DoubaoMultimodalEmbeddingInput,
    }
    src.memu.embedding.backends.jina --> src.memu.embedding.backends { JinaEmbeddingBackend }
    src.memu.embedding.backends.openai --> src.memu.embedding.backends { OpenAIEmbeddingBackend }
    src.memu.embedding.backends.openrouter --> src.memu.embedding.backends {
        OpenRouterEmbeddingBackend,
    }
    src.memu.embedding.backends.voyage --> src.memu.embedding.backends { VoyageEmbeddingBackend }
    src.memu.hosts.bridging.layout --> src.memu.hosts.bridging { Layout }
    src.memu.hosts.bridging.pipeline --> src.memu.hosts.bridging { commit, prepare }
    src.memu.events --> src.memu.hosts.bridging.pipeline;
    src.memu.env --> src.memu.hosts.bridging.pipeline { build_agentic_memory_backend_from_env }
    src.memu.hosts.templates --> src.memu.hosts.bridging.pipeline;
    src.memu.hosts.base --> src.memu.hosts.bridging.pipeline { TranscriptSource }
    src.memu.hosts.bridging.instructions --> src.memu.hosts.bridging.pipeline {
        MEMORY_JOB_TEMPLATE,
        SKILL_JOB_TEMPLATE,
        prepare_instruction_jobs,
    }
    src.memu.hosts.bridging.layout --> src.memu.hosts.bridging.pipeline { Layout, TRACK_DIRS }
    src.memu.hosts.bridging.manifest --> src.memu.hosts.bridging.pipeline {
        diff_tracked,
        snapshot_tracked,
    }
    src.memu.hosts.bridging.recall_files --> src.memu.hosts.bridging.pipeline {
        finalize_recall_file,
        read_recall_file,
        write_recall_file,
    }
    src.memu.hosts.bridging.resources --> src.memu.hosts.bridging.pipeline {
        RESOURCE_JOB_TEMPLATE,
        prepare_resource_job,
        read_resources,
    }
    src.memu.hosts.bridging.transcripts --> src.memu.hosts.bridging.pipeline { prepare_transcripts }
    src.memu.hosts.base --> src.memu.hosts.bridging.transcripts {
        RecordKind,
        TranscriptRead,
        TranscriptReadError,
        TranscriptSource,
    }
    src.memu.hosts.claude_code.desktop_sessions --> src.memu.hosts.claude_code {
        ClaudeDesktopTranscriptSource,
    }
    src.memu.hosts.claude_code.sessions --> src.memu.hosts.claude_code {
        ClaudeCodeTranscriptSource,
    }
    src.memu.hosts.base --> src.memu.hosts.claude_code.desktop_sessions {
        RecordKind,
        TranscriptRead,
        TranscriptSource,
    }
    src.memu.hosts.claude_code.sessions --> src.memu.hosts.claude_code.desktop_sessions {
        ClaudeCodeTranscriptSource,
    }
    src.memu.hosts.cowork.sessions --> src.memu.hosts.claude_code.desktop_sessions {
        CoworkTranscriptSource,
    }
    src.memu.hosts.base --> src.memu.hosts.claude_code.sessions { RecordKind, TranscriptSource }
    src.memu.hosts.claude_records --> src.memu.hosts.claude_code.sessions { classify_claude_record }
    src.memu.hosts.base --> src.memu.hosts.claude_records { RecordKind }
    src.memu.hosts.base --> src.memu.hosts.cowork.sessions {
        RecordKind,
        TranscriptReadError,
        TranscriptSource,
    }
    src.memu.hosts.claude_records --> src.memu.hosts.cowork.sessions { classify_claude_record }
    src.memu.hosts.installation --> src.memu.hosts.claude_code.auth;
    src.memu.hosts.claude_code.cli_prepare --> src.memu.hosts.claude_code.auth;
    src.memu.hosts.claude_code.hook_install --> src.memu.hosts.claude_code.auth;
    src.memu.hosts.hooks.admission --> src.memu.hosts.claude_code.auth { workspace_lock }
    src.memu.hosts.install_language --> src.memu.hosts.claude_code.auth { LANGUAGE, text }
    src.memu.config_file --> src.memu.hosts.installation;
    src.memu.events --> src.memu.hosts.installation;
    src.memu.hosts.instruction --> src.memu.hosts.installation;
    src.memu.hosts.hooks.admission --> src.memu.hosts.installation { workspace_lock }
    src.memu.hosts.install_language --> src.memu.hosts.installation { LANGUAGE, text }
    src.memu.hosts.templates --> src.memu.hosts.instruction;
    src.memu.hosts.bridging --> src.memu.hosts.hooks.admission { Layout }
    src.memu.hosts.bridging.recall_files --> src.memu.hosts.hooks.admission { _atomic_write_text }
    src.memu.hosts.cli_install --> src.memu.hosts.claude_code.cli_prepare;
    src.memu.hosts.install_language --> src.memu.hosts.claude_code.cli_prepare { text }
    src.memu.trust --> src.memu.hosts.cli_install;
    src.memu.hosts.install_language --> src.memu.hosts.cli_install { text }
    src.memu.hosts.codex.prompt_hook_install --> src.memu.hosts.claude_code.hook_install {
        _atomic_write,
    }
    src.memu.hosts.bridging --> src.memu.hosts.codex.prompt_hook_install { Layout }
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.prompt_hook_install;
    src.memu.hosts.cli_install --> src.memu.hosts.codex.cli_prepare;
    src.memu.hosts.hooks --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.bridging --> src.memu.hosts.claude_code.cli { Layout }
    src.memu.hosts.claude_code.auth --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.claude_code.cowork_cmd --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.claude_code.install --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.claude_code.memorize_hook --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.claude_code.prompt_hook --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.claude_code.uninstall --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.claude_code.desktop_sessions --> src.memu.hosts.claude_code.cli {
        ClaudeDesktopTranscriptSource,
    }
    src.memu.hosts.claude_code.sessions --> src.memu.hosts.claude_code.cli { SESSION_DIR }
    src.memu.hosts.host_cli --> src.memu.hosts.claude_code.cli { HostSpec, run }
    src.memu.hosts.scheduling.macos --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.scheduling --> src.memu.hosts.claude_code.cli;
    src.memu.hosts.bridging --> src.memu.hosts.hooks { Layout }
    src.memu.hosts.base --> src.memu.hosts.claude_code.cowork_cmd { RecordKind, TranscriptSource }
    src.memu.hosts.claude_code.desktop_sessions --> src.memu.hosts.claude_code.cowork_cmd {
        ClaudeDesktopTranscriptSource,
    }
    src.memu.hosts.claude_code.sessions --> src.memu.hosts.claude_code.cowork_cmd {
        ClaudeCodeTranscriptSource,
        SESSION_DIR,
    }
    src.memu.hosts.cowork.sessions --> src.memu.hosts.claude_code.cowork_cmd {
        CoworkTranscriptSource,
    }
    src.memu.hosts.cli_install --> src.memu.hosts.claude_code.install;
    src.memu.hosts.installation --> src.memu.hosts.claude_code.install;
    src.memu.hosts.claude_code.auth --> src.memu.hosts.claude_code.install;
    src.memu.hosts.claude_code.cli_prepare --> src.memu.hosts.claude_code.install;
    src.memu.hosts.claude_code.hook_install --> src.memu.hosts.claude_code.install;
    src.memu.hosts.hooks.admission --> src.memu.hosts.claude_code.install { workspace_lock }
    src.memu.hosts.install_language --> src.memu.hosts.claude_code.install { text }
    src.memu.hosts.claude_code.cli --> src.memu.hosts.claude_code.install { SPEC }
    src.memu.hosts.host_cli --> src.memu.hosts.claude_code.install { build_parser }
    src.memu.events --> src.memu.hosts.host_cli;
    src.memu.hosts.config_cmd --> src.memu.hosts.host_cli;
    src.memu.hosts.hooks --> src.memu.hosts.host_cli;
    src.memu.hosts.instruction --> src.memu.hosts.host_cli;
    src.memu.hosts.retrieval --> src.memu.hosts.host_cli;
    src.memu.hosts.templates --> src.memu.hosts.host_cli;
    src.memu.hosts.base --> src.memu.hosts.host_cli { TranscriptSource }
    src.memu.hosts.bridging --> src.memu.hosts.host_cli { Layout, commit, prepare }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.host_cli;
    src.memu.hosts.bridging.pipeline --> src.memu.hosts.host_cli { MAX_JOBS }
    src.memu.hosts.bridging.resources --> src.memu.hosts.host_cli { verify_resource_log }
    src.memu.env --> src.memu.hosts.host_cli {
        CONFIG_ENV,
        ConfigError,
        cloud_base_url,
        embedding_provider,
        env,
        memory_mode,
    }
    src.memu.embedding.http_client --> src.memu.hosts.host_cli { is_loopback_url }
    src.memu.hosts.codex.doctor --> src.memu.hosts.host_cli { check }
    src.memu.hosts.claude_code.doctor --> src.memu.hosts.host_cli { check }
    src.memu.hosts.codex.notify_console --> src.memu.hosts.host_cli { memorize_run }
    src.memu.hosts.pi.memorize_hook --> src.memu.hosts.host_cli { memorize_run }
    src.memu.hosts.hermes.memorize_hook --> src.memu.hosts.host_cli { memorize_run }
    src.memu.hosts.claude_code.memorize_hook --> src.memu.hosts.host_cli { memorize_run }
    src.memu.hosts.scheduling --> src.memu.hosts.host_cli;
    src.memu.config_file --> src.memu.hosts.config_cmd;
    src.memu.events --> src.memu.hosts.config_cmd;
    src.memu.env --> src.memu.hosts.config_cmd;
    src.memu.cloud --> src.memu.hosts.config_cmd { DEFAULT_CLOUD_BASE_URL }
    src.memu.events --> src.memu.hosts.retrieval;
    src.memu.env --> src.memu.hosts.retrieval {
        LONG_QUERY_CHARS,
        QueryKind,
        build_agentic_memory_backend_from_env,
        retrieval_min_score,
    }
    src.memu.hosts.bridging.layout --> src.memu.hosts.retrieval { BASE_DIR, TRACK_DIRS }
    src.memu.hosts.bridging.recall_files --> src.memu.hosts.retrieval { write_recall_file }
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.doctor;
    src.memu.hosts.codex.prompt_hook_install --> src.memu.hosts.codex.doctor;
    src.memu.hosts.claude_code.cli_prepare --> src.memu.hosts.claude_code.doctor;
    src.memu.hosts.claude_code.hook_install --> src.memu.hosts.claude_code.doctor;
    src.memu.hosts.bridging --> src.memu.hosts.codex.notify_console { Layout }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.codex.notify_console;
    src.memu.hosts.hooks.admission --> src.memu.hosts.codex.notify_console;
    src.memu.hosts.hooks.worker --> src.memu.hosts.codex.notify_console;
    src.memu.hosts.codex.cli --> src.memu.hosts.codex.notify_console { main }
    src.memu.hosts.bridging --> src.memu.hosts.hooks.worker { Layout }
    src.memu.hosts.hooks --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.install --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.memorize_hook --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.notify_console --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.prompt_hook --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.prompt_hook_install --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.uninstall --> src.memu.hosts.codex.cli;
    src.memu.hosts.codex.sessions --> src.memu.hosts.codex.cli {
        CodexTranscriptSource,
        SESSION_DIR,
    }
    src.memu.hosts.host_cli --> src.memu.hosts.codex.cli { HostSpec, build_parser, run }
    src.memu.hosts.installation --> src.memu.hosts.codex.install;
    src.memu.hosts.installation --> src.memu.hosts.codex.install { Blocked, Failed }
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.install;
    src.memu.hosts.codex.prompt_hook_install --> src.memu.hosts.codex.install;
    src.memu.hosts.install_language --> src.memu.hosts.codex.install { text }
    src.memu.hosts.codex.cli --> src.memu.hosts.codex.install { build_parser }
    src.memu.hosts.bridging --> src.memu.hosts.codex.memorize_hook { Layout }
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.memorize_hook;
    src.memu.hosts.codex.hook_status --> src.memu.hosts.codex.memorize_hook;
    src.memu.hosts.codex.notify_console --> src.memu.hosts.codex.memorize_hook;
    src.memu.env --> src.memu.hosts.codex.prompt_hook { LONG_QUERY_CHARS }
    src.memu.hosts.codex.query_extraction --> src.memu.hosts.codex.prompt_hook { select_query }
    src.memu.hosts.retrieval --> src.memu.hosts.codex.prompt_hook { render_context }
    src.memu.hosts.query_extraction --> src.memu.hosts.codex.query_extraction;
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.query_extraction;
    src.memu.env --> src.memu.hosts.query_extraction { LONG_QUERY_CHARS }
    src.memu.hosts._extraction_windows_job --> src.memu.hosts.query_extraction {
        WindowsExtractionJob,
    }
    src.memu.hosts.instruction --> src.memu.hosts.codex.uninstall;
    src.memu.hosts.codex.cli_prepare --> src.memu.hosts.codex.uninstall;
    src.memu.hosts.codex.prompt_hook_install --> src.memu.hosts.codex.uninstall;
    src.memu.hosts.base --> src.memu.hosts.codex.sessions { RecordKind, TranscriptSource }
    src.memu.hosts.hooks --> src.memu.hosts.pi.memorize_hook;
    src.memu.hosts.bridging --> src.memu.hosts.pi.memorize_hook { Layout }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.pi.memorize_hook;
    src.memu.hosts.hooks.admission --> src.memu.hosts.pi.memorize_hook;
    src.memu.hosts.hooks.worker --> src.memu.hosts.pi.memorize_hook;
    src.memu.hosts.host_cli --> src.memu.hosts.pi.memorize_hook { run }
    src.memu.hosts.pi.cli --> src.memu.hosts.pi.memorize_hook { SPEC }
    src.memu.hosts.hooks --> src.memu.hosts.pi.cli;
    src.memu.hosts.host_cli --> src.memu.hosts.pi.cli { HostSpec, run }
    src.memu.hosts.pi.hook_install --> src.memu.hosts.pi.cli;
    src.memu.hosts.pi.install --> src.memu.hosts.pi.cli;
    src.memu.hosts.pi.memorize_hook --> src.memu.hosts.pi.cli;
    src.memu.hosts.pi.sessions --> src.memu.hosts.pi.cli {
        AGENT_DIR,
        PiTranscriptSource,
        SESSION_DIR,
    }
    src.memu.hosts.instruction --> src.memu.hosts.pi.hook_install;
    src.memu.hosts.hooks.admission --> src.memu.hosts.pi.hook_install { workspace_lock }
    src.memu.hosts.pi.memorize_hook --> src.memu.hosts.pi.hook_install;
    src.memu.hosts.pi.prompt_hook --> src.memu.hosts.pi.hook_install { prompt_hook }
    src.memu.env --> src.memu.hosts.pi.prompt_hook { LONG_QUERY_CHARS }
    src.memu.hosts.pi.query_extraction --> src.memu.hosts.pi.prompt_hook { select_query }
    src.memu.hosts.query_extraction --> src.memu.hosts.pi.prompt_hook { ExtractionCancellation }
    src.memu.hosts.retrieval --> src.memu.hosts.pi.prompt_hook {
        QueryKind,
        render_context,
        retrieve,
    }
    src.memu.hosts.query_extraction --> src.memu.hosts.pi.query_extraction;
    src.memu.hosts.installation --> src.memu.hosts.pi.install;
    src.memu.hosts.hooks.admission --> src.memu.hosts.pi.install { workspace_lock }
    src.memu.hosts.install_language --> src.memu.hosts.pi.install { text }
    src.memu.hosts.pi.hook_install --> src.memu.hosts.pi.install;
    src.memu.hosts.host_cli --> src.memu.hosts.pi.install { build_parser }
    src.memu.hosts.pi.cli --> src.memu.hosts.pi.install { SPEC }
    src.memu.hosts.base --> src.memu.hosts.pi.sessions { RecordKind, TranscriptSource }
    src.memu.hosts.bridging --> src.memu.hosts.hermes.memorize_hook { Layout }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.hermes.memorize_hook;
    src.memu.hosts.hermes.sessions --> src.memu.hosts.hermes.memorize_hook {
        hermes_home,
        state_db_path,
    }
    src.memu.hosts.hooks.admission --> src.memu.hosts.hermes.memorize_hook;
    src.memu.hosts.hooks.worker --> src.memu.hosts.hermes.memorize_hook;
    src.memu.hosts.hermes.cli --> src.memu.hosts.hermes.memorize_hook { main }
    src.memu.hosts.base --> src.memu.hosts.hermes.sessions { RecordKind, TranscriptSource }
    src.memu.hosts.hooks --> src.memu.hosts.hermes.cli;
    src.memu.hosts.hermes.hook --> src.memu.hosts.hermes.cli;
    src.memu.hosts.hermes.hook_install --> src.memu.hosts.hermes.cli;
    src.memu.hosts.hermes.install --> src.memu.hosts.hermes.cli;
    src.memu.hosts.hermes.sessions --> src.memu.hosts.hermes.cli {
        HermesTranscriptSource,
        hermes_home,
        state_db_path,
    }
    src.memu.hosts.host_cli --> src.memu.hosts.hermes.cli { HostSpec, run }
    src.memu.hosts.hermes.memorize_hook --> src.memu.hosts.hermes.cli;
    src.memu.hosts.bridging --> src.memu.hosts.hermes.hook { Layout }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.hermes.hook;
    src.memu.hosts.hermes.sessions --> src.memu.hosts.hermes.hook { hermes_home }
    src.memu.hosts.hooks.worker --> src.memu.hosts.hermes.hook;
    src.memu.hosts.instruction --> src.memu.hosts.hermes.hook_install;
    src.memu.hosts.bridging.recall_files --> src.memu.hosts.hermes.hook_install {
        _atomic_write_text,
    }
    src.memu.hosts.hermes.sessions --> src.memu.hosts.hermes.hook_install { hermes_home }
    src.memu.hosts.hooks.admission --> src.memu.hosts.hermes.hook_install { workspace_lock }
    src.memu.hosts.hermes.install --> src.memu.hosts.hermes.hook_install { _command }
    src.memu.hosts.hermes.cli --> src.memu.hosts.hermes.hook_install { SPEC }
    src.memu.hosts.installation --> src.memu.hosts.hermes.install;
    src.memu.hosts.instruction --> src.memu.hosts.hermes.install;
    src.memu.hosts.hermes.hook_install --> src.memu.hosts.hermes.install;
    src.memu.hosts.hermes.sessions --> src.memu.hosts.hermes.install { hermes_home, state_db_path }
    src.memu.hosts.hooks.admission --> src.memu.hosts.hermes.install { workspace_lock }
    src.memu.hosts.hermes.cli --> src.memu.hosts.hermes.install { SPEC }
    src.memu.hosts.host_cli --> src.memu.hosts.hermes.install { build_parser }
    src.memu.hosts.bridging --> src.memu.hosts.claude_code.memorize_hook { Layout }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.claude_code.memorize_hook;
    src.memu.hosts.claude_code.cli_prepare --> src.memu.hosts.claude_code.memorize_hook;
    src.memu.hosts.claude_code.submit --> src.memu.hosts.claude_code.memorize_hook { is_automatic }
    src.memu.hosts.hooks.admission --> src.memu.hosts.claude_code.memorize_hook;
    src.memu.hosts.hooks.worker --> src.memu.hosts.claude_code.memorize_hook;
    src.memu.hosts.claude_code.sessions --> src.memu.hosts.claude_code.memorize_hook { SESSION_DIR }
    src.memu.hosts.claude_code.cli --> src.memu.hosts.claude_code.memorize_hook { main }
    src.memu.hosts.scheduling.windows --> src.memu.hosts.scheduling {
        cleanup,
        install,
        status,
        uninstall,
        verify,
    }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.scheduling.windows { BRIDGING_RUN_ENV }
    src.memu.hosts.scheduling.prompt --> src.memu.hosts.scheduling.windows {
        bridging_pipeline_prompt,
    }
    src.memu.hosts.bridging --> src.memu.hosts.scheduling.windows { Layout }
    src.memu.hosts.host_cli --> src.memu.hosts.scheduling.windows { HostSpec }
    src.memu.hosts.host_cli --> src.memu.hosts.scheduling.prompt { HostSpec }
    src.memu.env --> src.memu.hosts.claude_code.prompt_hook { LONG_QUERY_CHARS }
    src.memu.hosts.claude_code.query_extraction --> src.memu.hosts.claude_code.prompt_hook {
        select_query,
    }
    src.memu.hosts.claude_code.submit --> src.memu.hosts.claude_code.prompt_hook { is_automatic }
    src.memu.hosts.retrieval --> src.memu.hosts.claude_code.prompt_hook {
        CONTEXT_PREFIX,
        render_context,
    }
    src.memu.hosts.query_extraction --> src.memu.hosts.claude_code.query_extraction;
    src.memu.hosts.claude_code.cli_prepare --> src.memu.hosts.claude_code.query_extraction;
    src.memu.hosts.instruction --> src.memu.hosts.claude_code.uninstall;
    src.memu.hosts.claude_code.hook_install --> src.memu.hosts.claude_code.uninstall;
    src.memu.hosts.hooks.admission --> src.memu.hosts.claude_code.uninstall { workspace_lock }
    src.memu.hosts.install_language --> src.memu.hosts.claude_code.uninstall { LANGUAGE }
    src.memu.hosts.codex.sessions --> src.memu.hosts.codex { CodexTranscriptSource }
    src.memu.hosts.cowork.sessions --> src.memu.hosts.cowork { CoworkTranscriptSource }
    src.memu.hosts.cursor.sessions --> src.memu.hosts.cursor { CursorTranscriptSource }
    src.memu.hosts.base --> src.memu.hosts.cursor.sessions { RecordKind, TranscriptSource }
    src.memu.hosts.cursor.sessions --> src.memu.hosts.cursor.cli {
        CursorTranscriptSource,
        SESSION_DIR,
    }
    src.memu.hosts.host_cli --> src.memu.hosts.cursor.cli { HostSpec, run }
    src.memu.hosts.hermes.sessions --> src.memu.hosts.hermes { HermesTranscriptSource }
    src.memu.hosts.openclaw.sessions --> src.memu.hosts.openclaw { OpenClawTranscriptSource }
    src.memu.hosts.base --> src.memu.hosts.openclaw.sessions {
        RecordKind,
        TranscriptRead,
        TranscriptReadError,
        TranscriptSource,
    }
    src.memu.hosts.host_cli --> src.memu.hosts.openclaw.cli { HostSpec, run }
    src.memu.hosts.openclaw.cron_identity --> src.memu.hosts.openclaw.cli;
    src.memu.hosts.openclaw.sessions --> src.memu.hosts.openclaw.cli {
        OpenClawTranscriptSource,
        SESSION_DIR,
    }
    src.memu.hosts.base --> src.memu.hosts.openclaw.cron_identity { TranscriptSource }
    src.memu.hosts.bridging.self_sessions --> src.memu.hosts.openclaw.cron_identity;
    src.memu.hosts.bridging.layout --> src.memu.hosts.openclaw.cron_identity { Layout }
    src.memu.hosts.openclaw.sessions --> src.memu.hosts.openclaw.cron_identity {
        OpenClawTranscriptSource,
    }
    src.memu.hosts.pi.sessions --> src.memu.hosts.pi { PiTranscriptSource }
    src.memu.hosts.workbuddy.sessions --> src.memu.hosts.workbuddy { WorkBuddyTranscriptSource }
    src.memu.hosts.base --> src.memu.hosts.workbuddy.sessions { RecordKind, TranscriptSource }
    src.memu.hosts.host_cli --> src.memu.hosts.workbuddy.cli { HostSpec, run }
    src.memu.hosts.workbuddy.sessions --> src.memu.hosts.workbuddy.cli {
        SESSION_DIR,
        WorkBuddyTranscriptSource,
    }
    tests.test_agentic --> tests.test_commit_concurrency;
    tests.test_agentic --> tests.test_commit_concurrency { FakeEmbeddingClient, make_service }
    tests.test_agentic --> tests.test_commit_thread_isolation { make_service }
}
