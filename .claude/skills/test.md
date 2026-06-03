# Skill: /test

## Purpose
Run behavioral tests and produce an evidence artifact. Not a substitute for /verify.

## Process
1. Run the test suite: `npm test`, `pytest`, or whatever applies
2. For any new feature, confirm tests exist covering the acceptance criteria
3. Record results — pass count, fail count, coverage if available
4. Write artifact to `docs/reports/YYYY-MM-DD-<feature>-test.md`

## Writing Tests (when needed)
- Follow `.claude/rules/code-style.md` test naming: `test_<what>_<condition>_<expected>`
- Test behavior, not implementation
- For fitness features: always include an edge case test (zero reps, max weight, invalid input)
- For data persistence: always include a round-trip test (save → load → compare)

## Artifact Template
```markdown
# Test: <Feature>
**Date:** YYYY-MM-DD
**Branch:** <branch>
**Result:** PASS | FAIL | PARTIAL

## Suite Results
- Total: X passed, Y failed, Z skipped
- Coverage: N% (if measured)

## New Tests Added
- `test_<name>` — covers: <acceptance criterion>

## Failures
- `test_<name>`: <failure message>

## Fitness Edge Cases Covered
- [ ] Zero/empty workout
- [ ] Maximum load boundary
- [ ] Invalid input rejection
- [ ] User with no history (first session)
```

## Rules
- Any test failure blocks `/pr` unless explicitly marked as pre-existing and filed as an issue
