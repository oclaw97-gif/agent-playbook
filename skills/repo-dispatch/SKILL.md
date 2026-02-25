---
name: repo-dispatch
description: Check issues for pending work and execute the highest-priority task.
user-invocable: true
---

# repo-dispatch

Run the dispatch script, then execute the top task.

## Input

Repo(s) (`owner/repo` or comma-separated list `owner/repo1,owner/repo2`).

## Steps

1. Pull latest: `git -C agent-playbook pull origin main`
2. Run `bash agent-playbook/scripts/dispatch.sh <repos> <your-github-username>`
3. Parse the output:
   - If the first line starts with `RUN` → extract skill name, repo, and issue number, then execute it.
   - If no `RUN` lines (only `WAIT` or "Nothing to do") → report "Nothing to do" and stop.
4. Execute only the **first** RUN line. One task per dispatch.

### Parsing example

```
RUN   repo-plan   baduk #23  Fix mobile UI layout
```
→ run `repo-plan baduk 23`

```
RUN   repo-execute baduk #24  Touch placement
```
→ run `repo-execute baduk 24`

## Decision matrix

The script determines RUN vs WAIT using this logic:

| Label       | Last actor | Output             |
|-------------|-----------|---------------------|
| agent:plan  | user      | RUN repo-plan       |
| agent:plan  | agent     | WAIT (user turn)    |
| agent:wip   | user      | RUN repo-execute    |
| agent:wip   | agent     | WAIT (user turn)    |
| agent:done  | -         | (not scanned)       |
| no label    | -         | (not scanned)       |

- Bot accounts are ignored when determining last actor.
- RUN items are sorted by user action timestamp (oldest first = longest wait).

## Rules

- Execute only ONE task per dispatch run.
- Do NOT change any labels.
- If the executed skill fails, report failure. Do not retry or run the next task.
- If you notice yourself repeating the same text or action, stop immediately and report failure.
