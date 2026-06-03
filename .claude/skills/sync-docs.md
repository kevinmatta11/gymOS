# Skill: /sync-docs

## Purpose
Keep documentation current with what was just built. Brief and honest — not marketing.

## What to Update
- `README.md` — if setup steps, env vars, or feature list changed
- `docs/specs/<feature>.md` — mark status `implemented`
- Any API docs or data model docs if the schema changed
- AGENTS.md or CLAUDE.md if a new rule or skill was introduced

## What NOT to Do
- Don't create new docs files unless asked
- Don't write comprehensive feature docs unprompted — minimal, accurate updates only
- Don't mark a spec `implemented` if `/verify` result was FAIL

## Process
1. Diff what changed in this feature branch
2. Identify which docs are now stale
3. Make minimal accurate updates
4. Commit with `docs:` prefix

## Output
A commit with updated docs. No separate artifact required — the diff is the evidence.
