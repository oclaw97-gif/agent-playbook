---
name: codebible-collect
description: Scrape PR review comments from target repos and propose new codebible rules via PR.
user-invocable: true
---

# codebible-collect

Collect coding feedback from closed PR review comments and propose a new rule to the codebible.

## Input

None. Target repos are defined in `codebible/_last_collected.yaml`.

## Steps

1. Pull latest: `git -C agent-playbook pull origin main`
2. Run `bash agent-playbook/scripts/collect-comments.sh` — outputs one JSON object per comment.
3. For each comment, decide: does this teach a **reusable coding rule** (HOW to code)?
   - **Yes** → candidate. Continue to step 4.
   - **No** → skip. (Approvals, LGTMs, project-specific logic, questions — all skip.)
4. Check if this candidate is already covered:
   - Existing rules in `codebible/general/` and `codebible/{language}/` — skip if covered.
   - Open PRs on agent-playbook with `codebible:` title prefix — skip if already proposed.
   - If the candidate **improves** an existing rule (better example, clearer explanation) → treat as an update, not a duplicate.
5. Pick the **first** uncovered candidate. Write the rule to a temp file:
   ```markdown
   ## Rule title (imperative, one-line)

   Why this matters.

   **Bad:**
   ```code
   // example
   ```

   **Good:**
   ```code
   // example
   ```
   ```
6. Run `bash agent-playbook/scripts/propose-rule.sh <language> <filename> <rule-file> <source-url> <source-comment>` — creates a branch and PR.
7. **Checkpoint**: Only update `codebible/_last_collected.yaml` if **no candidates remain** (all processed or skipped). Otherwise leave the date unchanged so the next run re-fetches the same comments.

## One rule per run

Each run proposes at most one rule. Remaining candidates are picked up in subsequent runs. This keeps git operations simple and PRs reviewable.

## Rules

- One rule per run. Stop after proposing one.
- Do NOT merge the PRs — only the user merges or closes.
- If you notice yourself repeating the same text or action, stop immediately and report failure.
