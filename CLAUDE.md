# gymOS — Claude Code Guidance

> Pointers only. Rules → `.claude/rules/`. Skills → `.claude/skills/`.

## Skill Triggers
| Skill | Trigger | Mode |
|-------|---------|------|
| `/spec` | Manual | Interactive brainstorm → spec doc |
| `/plan` | Manual or pre-work | Worktree setup, flow selection |
| `/work` | After plan | Implement, then auto-chain pipeline |
| `/self-review` | Auto after work | Diff quality check, artifact output |
| `/verify` | Auto after self-review | Spec compliance + static analysis |
| `/test` | Auto after verify | Behavioral tests, evidence artifact |
| `/sync-docs` | Auto after test | Keep docs current |
| `/pr` | Auto after sync-docs | Create PR, archive plan, clean up |

## Rules Index
- `.claude/rules/exercise-safety.md` — fitness data safety, rep ranges, form constraints
- `.claude/rules/user-progression.md` — progressive overload, periodization logic
- `.claude/rules/data-integrity.md` — data validation, schema contracts
- `.claude/rules/code-style.md` — naming, structure, comment policy

## Key Constraints
- No AI-generated medical advice — redirect to qualified professionals
- All workout calculations must be explainable and cite source methodology
- User data is private by default — explicit opt-in for any sharing
- Fail loudly on data integrity errors — never silently swallow fitness data

## Evidence Requirement
Every `/verify`, `/test`, `/self-review` writes a dated markdown artifact:
`docs/reports/YYYY-MM-DD-<feature>-<stage>.md`
