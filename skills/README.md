# Prepackaged skills

Each subdirectory here is one skill that `dcc create` can offer to copy into
a new instance's `~/.claude/skills`. A skill is recognized by the presence
of a `SKILL.md` file:

```
skills/
  my-skill/
    SKILL.md      # required – name + description frontmatter, then instructions
    ...           # any supporting files the skill needs
```

Drop new skills in here (or remove ones you no longer want offered) and
they'll show up next time someone runs `dcc create`. Nothing here is copied
automatically – it's just the catalog `create` prompts against.

A skill's `SKILL.md` frontmatter can declare `requires: other-skill, another`
when it orchestrates other skills (see `flow`, which chains `recon` → `spec`
→ `implement` → `review`). Picking such a skill one by one during `dcc
create` auto-includes its dependencies too, without asking about each of
them separately.
