---
name: repo-scan
description: Read a repo's docs and conventions. Run this when you lack context about a repo.
user-invocable: true
---

# repo-scan

Read the target repo and report its conventions. No code changes. No label changes.

## Input

Repo name or path.

## Steps

1. Read `README.md` and project guide (`CLAUDE.md`, `CONTRIBUTING.md`, etc.) — purpose, setup, rules
2. Read package manifest (`package.json`, `pyproject.toml`, `go.mod`, etc.) — deps, scripts
3. Read linter/formatter config (biome.json, .eslintrc, pyproject.toml, etc.) — verify exact CLI flags
4. Read CI config (`.github/workflows/`, etc.) — required checks
5. Check project structure (`ls` top-level dirs, `ls src/` or equivalent) — understand layout
6. Skim recent commits (`git log --oneline -10`) — infer conventions

## Output

Save results to `memory/scans/{owner}-{repo}.md`:

```
# {owner}/{repo} scan
Updated: {date}
HEAD: {commit-hash}

- Language/framework: ...
- Structure: [top-level layout]
- Build: [command]
- Test: [command]
- Lint: [command]
- Format: [command]
- CI checks: ...
- Conventions: [branch pattern, commit format, etc.]
```

Also report the same to user.

## Rules

- Do NOT modify any repo files or labels.
- If a command or tool version is unclear, run `--help` or `--version` to confirm — do not guess.
- Overwrite the existing scan file if it already exists.
