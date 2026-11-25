"""Turn each prepared transcript into a self-evolve job-instruction file.

The middle step of the pipeline is not a script — it is real agent work (reading
transcripts, making judgement calls, writing markdown). These templates are how
prepare hands that work over: each emitted job is self-contained and already
carries the concrete paths it needs, so the agent does no path reasoning.
"""

import from __future__ { annotations }

import from pathlib { Path }

glob MEMORY_JOB_TEMPLATE: any = "You are the **self-evolve** pass for an agent's workspace. Your job is to mine\nwhat the agent recently *did* in one session into durable, reusable **user\nmemory** — small markdown files that record stable facts about the user, their\nprojects, and how they like to work.\n\n## The session to learn from\n\nThe transcript (the user/assistant messages of the session) is at:\n\n    {input_path}\n\nRead it with `bash` (e.g. `cat`).\n\n## Step 1 — read what already exists\n\nExisting user-memory files live under:\n\n    {track_dir}\n\nRead the **file names first**. Only read a memory's full body if its name looks\nrelated to what the session covers — skip the rest.\n\n## Step 2 — decide what (if anything) to do\n\nFor the session as a whole, pick ONE of:\n\n  a. **Do nothing.** The session records nothing durable worth keeping (it just\n     followed known preferences, or is too task-specific to reuse). Emit no files\n     and finish. A no-op is a perfectly good outcome — do not invent a memory to\n     justify the run.\n\n  b. **Patch existing memory file(s).** The session refines or extends something\n     an existing memory already covers. Rewrite that file in place with the\n     merged content.\n\n  c. **Create a new memory file.** The session surfaced a genuinely new, durable\n     fact no existing memory covers. Write a new file.\n\nYou may combine (b) and (c) if the session warrants it.\n\n## Step 3 — write the memory files\n\nUse prose or bullet points, not Markdown tables. Write each fact on one physical\nline as a complete statement with its subject, meaning, and necessary scope or\nconditions. Include dates only to establish validity or scope, or when the user\nneeds historical recall. Avoid bare values and references such as \"same as above\".\nWhen patching existing tables, express changed facts in this form and preserve\nunrelated content.\n\nWrite each memory file you create or patch to a path under `{track_dir}` with a\nmeaningful kebab-case name (last write wins when patching). Every file you write\nmust start with this front-matter head, followed by the memory body:\n\n    ---\n    name: <short kebab-case name>\n    description: <one-line summary of the memory>\n    ---\n    <the memory content>\n";

glob SKILL_JOB_TEMPLATE: any = "You are the **self-evolve** pass for an agent's workspace. Your job is to mine\nwhat the agent recently *did* in one session — including the tools it ran — into\ndurable, reusable **skills**: markdown files that capture a repeatable workflow\nfor a task family so the agent can do it better next time.\n\n## The session to learn from\n\nThe full transcript (user/assistant messages plus the tool calls the agent made)\nis at:\n\n    {input_path}\n\nRead it with `bash` (e.g. `cat`).\n\n## Step 1 — read what already exists\n\nExisting skill files live under:\n\n    {track_dir}\n\nRead the **file names first**. Only read a skill's full body if its name looks\nrelated to what the session covers — skip the rest.\n\n## Step 2 — decide what (if anything) to do\n\nFor the session as a whole, pick ONE of:\n\n  a. **Do nothing.** The session just followed an existing skill's instructions\n     and fulfilled the request — nothing new worth recording. Emit no files and\n     finish. A no-op is a perfectly good outcome — do not invent a skill to\n     justify the run.\n\n  b. **Patch existing skill(s).** The session introduces a new\n     solution/branch/edge-case within a task type an existing skill already\n     covers. Grow that skill in place (e.g. add a \"case X, do ...\" branch). A\n     skill is an organic collection for related tasks, not one rigid workflow —\n     branching it is preferred over spawning near-duplicate skills.\n\n  c. **Create a new skill.** The session developed a workflow for a genuinely new\n     task type no existing skill covers. Write a new file.\n\nYou may combine (b) and (c) if the session warrants it.\n\n## Step 3 — write the skills\n\nUse prose, bullet points, or numbered steps, not Markdown tables. Make each\ncondition, action, and outcome independently understandable. When patching\nexisting tables, express changed instructions in this form and preserve unrelated\ncontent.\n\nWrite each skill file you create or patch to a path under `{track_dir}` with a\nmeaningful kebab-case name that describes the task family — not a placeholder\n(last write wins when patching). Every file you write must start with this\nfront-matter head, followed by the skill body:\n\n    ---\n    name: <short kebab-case name>\n    description: <one-line summary of what the skill is for>\n    ---\n    <the skill instructions>\n\n## Step 4 — log the files the session touched\n\nThis step is separate from the skill work above and always runs, regardless of\nwhich choice you made in Step 2.\n\nScan the transcript for files the assistant itself **created or updated** during\nthe session (look at the tool calls it made — writes, edits, patches, etc.).\nFor each such file, append its full path as one line to this log:\n\n    {resource_log}\n\nAppend only — never overwrite or reorder it. One path per line. The simplest\nway is a shell append, e.g.:\n\n    echo \"<full path>\" >> {resource_log}\n\nIf the session created or updated no files, leave the log untouched.\n";

glob memory_template_default_: any;

glob skill_template_default_: any;

with entry {
    memory_template_default_ = MEMORY_JOB_TEMPLATE;
    skill_template_default_ = SKILL_JOB_TEMPLATE;
}

"""Write per-session job-instruction files under ``job_dir``.

    For each of the ``num_sessions`` transcripts, fill the templates with
    concrete paths: a user-memory job (mining ``<idx>.jsonl``) and a skill job
    (mining ``<idx>_full.jsonl``). Memory jobs are numbered first (1..N), skill
    jobs after them (N+1..2N) — ordering is load-bearing, since the skill jobs
    are what populate ``resource_log`` for the resource job that comes last.

    ``memory_template``/``skill_template`` default to the embedded constants and
    are overridden by :func:`~memu.hosts.bridging.pipeline.prepare` with the
    server's current copy when it is reachable (:mod:`memu.hosts.templates`).
    """
def prepare_instruction_jobs(
    job_dir: Path,
    session_dir: Path,
    memory_dir: Path,
    skill_dir: Path,
    resource_log: Path,
    num_sessions: int,
    *,
    memory_template: str = memory_template_default_,
    skill_template: str = skill_template_default_,
) -> None;
