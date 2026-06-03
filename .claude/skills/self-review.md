# Skill: /self-review

## Purpose
Review the current diff for correctness, safety, and quality — producing an evidence artifact.

## Process
1. `git diff main...HEAD` (or diff against base branch)
2. Review against: spec acceptance criteria, `.claude/rules/`, fitness safety constraints
3. Categorize all findings
4. Write artifact to `docs/reports/YYYY-MM-DD-<feature>-self-review.md`

## Finding Severity
| Severity | Definition | Blocks merge? |
|----------|-----------|--------------|
| `critical` | Incorrect fitness data, security hole, data loss risk | Yes |
| `major` | Logic error, spec violation, broken user flow | Yes |
| `minor` | Code quality, style, missing edge case | No |
| `nit` | Naming, formatting, trivial cleanup | No |

## Artifact Template
```markdown
# Self-Review: <Feature>
**Date:** YYYY-MM-DD
**Diff range:** <base>..<head>
**Merge recommendation:** APPROVE | REQUEST_CHANGES

## Findings
### Critical
- (none) | <finding with file:line reference>

### Major
- (none) | <finding>

### Minor
- <finding>

## Fitness Safety Check
- [ ] No medical advice generated
- [ ] Rep ranges within safe bounds
- [ ] Calorie/1RM calculations verified
- [ ] User data privacy preserved

## Known Gaps
- (What this review did NOT cover)
```

## Rules
- Never output "LGTM" without a findings section
- A clean review still requires the artifact with explicit "none" for each severity
