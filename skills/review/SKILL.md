---
name: review
description: "Review the change made for a task against its specification's acceptance criteria — not a generic code review, but a check that the diff actually satisfies what the spec asked for."
---

# Review

Use this skill when the user explicitly invokes it, or when `flow` invokes it as the last step of its pipeline.

Review is read-only: report findings, don't fix them. If the user wants fixes applied, that's a follow-up `/implement` invocation, or an explicit request to make a specific change.

## Find the specification to review against

- If the user pointed you to a specific spec file, use that.
- Otherwise, look at `.dcc/specs/*.done.md` — specs `implement` has already marked done.
  - None found: ask the user which spec (or which diff) to review, or whether to run `/implement` first.
  - Exactly one, or one that was clearly just completed in this session: use it, and tell the user which one.
  - Several plausible candidates: ask the user which one.

Read the specification in full, especially its **Acceptance criteria** and **Verification plan** sections.

## Review the actual change

Identify the diff this specification produced — the commits or working-tree changes made for this task, using the repository's version control (e.g. comparing against the spec's `recon_commit`, or whatever the repository shows as the relevant change; ask if it's genuinely ambiguous which changes belong to this task).

For each acceptance criterion, check whether the change actually satisfies it — don't just check that the code looks reasonable in isolation. Also check, at the altitude the task warrants:

- **Correctness**: logic errors, edge cases the acceptance criteria call out, integration points the spec identified.
- **Consistency**: does the implementation follow the approach and files the spec described, or did it quietly diverge in a way that matters?
- **Simplification/reuse**: only flag genuine over-engineering or missed reuse — don't nitpick style.

Don't re-review unrelated pre-existing code the task didn't touch, and don't repeat verification the spec's plan already covers unless you have reason to doubt it passed.

## Ask when genuinely unclear

If you can't tell whether a criterion is met without a decision only the user can make, stop and ask.

- **Running standalone** (invoked directly by the user, not as a `flow` subagent): check whether a skill named `grill-me` is available; if so, use it to run the clarifying question(s). If it isn't available, ask directly and wait for the answer.
- **Running as a `flow` subagent** (your invocation says so): you have no interactive question tool here. Stop immediately and make your entire remaining output a single line `NEEDS INPUT:` followed by the question(s), numbered, each with your recommended answer — don't call `grill-me` or `AskUserQuestion`, and don't mix in a partial progress report. `flow` will relay it to the user and resume you with the answer; continue exactly where you left off when that happens.

Either way, once answered, continue the review.

## Result

Report findings against each acceptance criterion (met / not met / unclear), most important first. Don't modify code yourself.
