---
name: flow
description: "Run the full recon → spec → implement → review pipeline for one task, each step in its own subagent to keep the main conversation's context small, pausing when a step needs input and stopping cleanly if one fails."
disable-model-invocation: true
requires: recon, spec, implement, review, grill-me
---

# Flow

Use this skill only when the user explicitly invokes it.

Run the task through the pipeline: `recon` → `spec` → `implement` → `review`. Run each step in its own subagent (the `Agent` tool) instead of inline — that step's exploration and reasoning then stay out of this conversation's context, and only short summaries (or a genuine question) come back here. `flow`'s job is to orchestrate, not to duplicate any step's own logic.

## Running a step

For each step, in order:

1. Tell the user, in one short line, which step is starting (e.g. "Spouštím recon…"). This is the only visibility they get while a step's subagent is working, since its own reasoning stays isolated from this conversation.
2. Spawn a subagent with `Agent` (`general-purpose` type; `run_in_background: false`, since the next step depends on this one finishing and there's nothing else useful to do meanwhile). Give it a self-contained prompt: the task description, which step it's running, that it's running **as a `flow` subagent** (so it follows that skill's "running as a flow subagent" branch instead of trying to ask you directly), and to call the Skill tool for that step's name to get its actual instructions. Don't restate that skill's instructions yourself — the subagent loads them on its own.
3. Classify what comes back:
   - **Needs input** — the entire output starts with `NEEDS INPUT:`. Relay the question(s) to the user yourself — verbatim, or via `AskUserQuestion` when they're a multiple-choice round — and wait for the answer. Once you have it, resume the **same** subagent with `SendMessage` (addressed to its agent id) carrying the answer, and re-classify its next output the same way — a step may need several rounds before it's actually done.
   - **Failed** — the subagent errored, stalled, or returned something that's neither a finished result nor a well-formed `NEEDS INPUT:` block. Don't guess your way past this or invent a next step. Stop the pipeline, tell the user which step failed and what the subagent actually returned (or the error), and ask whether to retry that step, adjust the task, or stop here.
   - **Finished** — anything else. Tell the user in one short line that the step is done, then pull out only what the next step actually needs (a file path, a one-line summary) and carry that forward as input to its prompt — don't keep a finished subagent's full report in your own context beyond that; that defeats the point of running it as a subagent.

## Skipping the review step

If the invocation includes `--skip-rev` (or the user otherwise says to skip review, e.g. "bez review", "no review this time"), run only recon → spec → implement and stop there — don't spawn a `review` step.

## Result

After the last step that actually ran, give one short wrap-up: whether recon was reused or refreshed, the spec file written, what implement changed, and (if it ran) review's findings and whether they were addressed. Don't repeat each step's full output verbatim — that's exactly what running them as subagents was for.
