# gymOS — Agent Operational Map

> Keep this file short. Detail lives in `.claude/rules/`. Workflows live in `.claude/skills/`.

## Mission
Build gymOS: a fitness platform that solves a real human problem with safety-first, evidence-backed engineering.

## Source of Truth Hierarchy
1. Repo files beat memory
2. Versioned docs beat chat history
3. Deterministic scripts beat informal promises
4. Evidence beats confidence statements

## Standard Feature Flow
```
/spec → /plan → /work → /self-review → /verify → /test → /sync-docs → /pr
```
- `/spec` and `/release` are manual-trigger only
- All other skills auto-chain after `/work`
- Never claim "done" without a dated artifact in `docs/reports/`

## Hard Rules
- AGENTS.md and CLAUDE.md stay concise — move growing guidance to `.claude/rules/`
- Every review produces findings with severity: `critical | major | minor | nit`
- Fitness data safety rules in `.claude/rules/exercise-safety.md` are non-negotiable
- No user-facing calorie, 1RM, or progression math ships without a verify artifact
- Human escalation required for: irreversible data ops, external API keys, schema migrations

## Repo Layout
```
.claude/rules/      — domain-scoped guidance
.claude/skills/     — workflow playbooks
.claude/hooks/      — deterministic runtime controls
.claude/agents/     — subagent definitions
docs/specs/         — feature specifications
docs/plans/active/  — in-progress task plans
docs/plans/archive/ — completed plans
docs/reports/       — evidence artifacts (verify, test, review)
scripts/            — reusable shell scripts
```

## Parallel (Loop) Flow
For large features with independent slices, each slice runs:
```
implement → self-review → verify → test → sync-docs → cross-review
```
Then all slices merge to an integration branch before PR.
