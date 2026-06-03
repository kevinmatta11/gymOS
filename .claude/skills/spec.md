# Skill: /spec

## Purpose
Refine a vague idea into a concrete, actionable specification document.

## When to Use
- Manual trigger only
- When a feature idea is abstract or underspecified
- Before writing a plan for anything non-trivial

## Process
1. **Explore** — Ask 3–5 clarifying questions to understand user goal, constraints, and success criteria
2. **Research** — Search codebase for related patterns; check `.claude/rules/` for domain constraints that apply
3. **Draft** — Write a spec doc to `docs/specs/YYYY-MM-DD-<feature-name>.md`
4. **Iterate** — Review with user; refine until both parties agree on scope

## Spec Document Template
```markdown
# Spec: <Feature Name>
**Date:** YYYY-MM-DD
**Status:** draft | approved

## Problem
What real problem does this solve? Who has it?

## Solution
What we're building. What we're explicitly NOT building.

## User Stories
- As a <user type>, I want <action> so that <outcome>

## Acceptance Criteria
- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)

## Fitness Domain Constraints
- (Reference relevant rules from .claude/rules/)

## Open Questions
- (Unresolved decisions that need answers before work starts)

## Out of Scope
- (Explicit exclusions to prevent scope creep)
```

## Output
A saved spec file in `docs/specs/`. No work begins until spec status = `approved`.
