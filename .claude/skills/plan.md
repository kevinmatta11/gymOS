# Skill: /plan

## Purpose
Turn an approved spec into a concrete, scoped task plan with a clean git worktree.

## When to Use
- Before any non-trivial implementation
- After `/spec` produces an approved spec doc

## Process
1. **Read** the spec in `docs/specs/`
2. **Assess scope** — Standard flow or Loop (parallel) flow?
   - Standard: single coherent feature, one dev thread
   - Loop: 3+ independent slices that can be parallelized
3. **Create plan doc** → `docs/plans/active/YYYY-MM-DD-<feature-name>.md`
4. **Set up worktree** (if using git worktrees for isolation)
5. **Confirm with user** before starting work

## Plan Document Template
```markdown
# Plan: <Feature Name>
**Date:** YYYY-MM-DD
**Spec:** docs/specs/YYYY-MM-DD-<feature-name>.md
**Flow:** standard | loop
**Status:** active | complete

## Slices (Loop flow only)
- [ ] Slice 1: <name> — <scope>
- [ ] Slice 2: <name> — <scope>

## Task Breakdown
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Definition of Done
- All acceptance criteria from spec pass
- /verify artifact exists in docs/reports/
- /test artifact exists in docs/reports/
- No open critical/major findings from /self-review

## Risks
- (Known unknowns, dependencies, blockers)
```

## Output
A saved plan in `docs/plans/active/`. Triggers `/work` to proceed.
