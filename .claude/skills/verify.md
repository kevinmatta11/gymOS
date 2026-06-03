# Skill: /verify

## Purpose
Confirm the implementation matches the spec and passes static analysis. Produce evidence.

## Process
1. Run linter / type checker (whichever applies to the stack)
2. Run `scripts/verify.sh` if it exists
3. Check spec acceptance criteria one by one — mark pass/fail with evidence
4. Check fitness calculation correctness for any math-heavy changes
5. Write artifact to `docs/reports/YYYY-MM-DD-<feature>-verify.md`

## Artifact Template
```markdown
# Verify: <Feature>
**Date:** YYYY-MM-DD
**Branch:** <branch>
**Result:** PASS | FAIL

## Static Analysis
- Linter: PASS / FAIL — <output or "clean">
- Type check: PASS / FAIL — <output or "clean">

## Acceptance Criteria
- [x] Criterion 1 — verified by: <how>
- [ ] Criterion 2 — FAIL: <reason>

## Fitness Math Checks
- [ ] Calorie calculations: <method used, sample result>
- [ ] 1RM estimates: <method used, sample result>
- [ ] Progressive overload logic: <verified | n/a>

## Blockers
- (Anything that must be fixed before merge)
```

## Rules
- A FAIL result blocks `/pr`
- Every criterion needs an explicit pass/fail, not just "looks good"
