# Skill: /work

## Purpose
Implement the current active plan, then automatically chain the post-work pipeline.

## Process
1. **Load context** — Read active plan from `docs/plans/active/`, read relevant `.claude/rules/`
2. **Implement** — Build the feature per the plan's task breakdown
3. **Commit incrementally** — Commit logical units, not one giant commit at the end
4. **Auto-chain** (subagents run sequentially after implementation):
   - `/self-review`
   - `/verify`
   - `/test`
   - `/sync-docs`
   - `/pr` (creates PR, archives plan)

## Implementation Standards
- Follow `.claude/rules/code-style.md` throughout
- Check `.claude/rules/exercise-safety.md` for any fitness data touched
- Check `.claude/rules/data-integrity.md` for any persistence layer touched
- Never claim a task done without actually running it

## Commit Message Format
```
<type>(<scope>): <short summary>

<body if needed>
```
Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

## Escalate to Human When
- Irreversible data operations (schema drops, bulk deletes)
- External API credentials needed
- Design decision not covered by spec or rules
- Genuine ambiguity that could go multiple valid ways
