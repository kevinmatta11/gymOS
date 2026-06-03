# Skill: /pr

## Purpose
Create a pull request, archive the plan, and clean up worktrees.

## Pre-conditions (all must be true)
- `/self-review` artifact exists with APPROVE recommendation
- `/verify` artifact exists with PASS result
- `/test` artifact exists with PASS or PARTIAL (with filed issues for failures)
- No open critical or major findings unresolved

## Process
1. Final commit for any sync-docs changes
2. Push branch: `git push -u origin <branch>`
3. Create PR via GitHub MCP tools with structured body (see template)
4. Move plan: `docs/plans/active/<plan>.md` → `docs/plans/archive/<plan>.md`
5. Update plan status to `complete`

## PR Body Template
```markdown
## Summary
- <bullet: what was built>
- <bullet: key decision made>

## Evidence
- Self-review: docs/reports/YYYY-MM-DD-<feature>-self-review.md — APPROVE
- Verify: docs/reports/YYYY-MM-DD-<feature>-verify.md — PASS
- Test: docs/reports/YYYY-MM-DD-<feature>-test.md — PASS

## Fitness Safety
- [ ] No medical advice
- [ ] Calculations verified
- [ ] User data privacy preserved

## Test Plan
- [ ] <manual check 1>
- [ ] <manual check 2>
```

## Rules
- Never create a PR with unresolved critical/major findings
- Never create a PR if `/verify` result is FAIL
- Always include evidence links in the PR body
