# Code Style Rules

## General
- No comments unless the WHY is non-obvious (hidden constraint, workaround, subtle invariant)
- No docstrings explaining WHAT the code does — well-named identifiers do that
- No TODO comments in committed code — open an issue or make a plan
- No backwards-compatibility shims unless explicitly required

## Naming
- Names must be grep-able and explicit — avoid abbreviations except universal ones (id, url, db)
- Boolean variables: `is_`, `has_`, `can_`, `should_` prefixes
- Event handlers: `handle_` prefix (e.g., `handle_workout_complete`)
- Async functions: suffix `_async` only if sync version also exists

## Error Handling
- Only validate at system boundaries (user input, external APIs, file I/O)
- Trust internal function contracts — no defensive null-checks inside pure logic
- Errors must be actionable — include context about what failed and what to do

## Testing
- Test behavior, not implementation
- One assertion concept per test (multiple assert lines fine if they test the same thing)
- Test names: `test_<what>_<condition>_<expected_outcome>`
- No mocking internal modules — mock only external I/O

## Structure
- Functions do one thing
- Files group by feature domain, not by type (not `models/`, `controllers/` — instead `workout/`, `user/`)
- No premature abstraction — three similar lines before extracting a helper
