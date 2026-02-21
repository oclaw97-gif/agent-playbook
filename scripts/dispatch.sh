#!/bin/bash
# dispatch.sh - Check issues with agent labels and determine which skills to run.
# Usage: dispatch.sh <owner/repo> <agent-username>
#
# ## How it works
#
# Scans open issues with `agent:plan` or `agent:wip` labels.
# For each issue, finds the most recent actor across:
#   1. Issue comments (last author)
#   2. Issue label events (last label change)
#   3. Linked PR review comments (if PR exists)
#   4. Linked PR reviews (if PR exists)
#   5. Linked PR general comments (if PR exists)
# PR is found by agent branch pattern: agent/{issue-number}-*
#
# ## Decision matrix
#
# | Label       | Last actor | PR   | Output             |
# |-------------|-----------|------|--------------------|
# | agent:plan  | user      | no   | RUN repo-plan      |
# | agent:plan  | user      | yes  | RUN repo-plan      |
# | agent:plan  | agent     | -    | WAIT (user turn)   |
# | agent:wip   | user      | no   | RUN repo-execute   |
# | agent:wip   | user      | yes  | RUN repo-execute   |
# | agent:wip   | agent     | -    | WAIT (user turn)   |
# | agent:done  | -         | -    | (not scanned)      |
# | no label    | -         | -    | (not scanned)      |
#
# ## TODO
# - [ ] Turn this into a proper skill (repo-dispatch) so the agent can run it
# - [ ] When it becomes a skill, provide the decision matrix above as context
#       in SKILL.md so the agent understands the logic it's executing
# - [ ] Add dry-run vs execute mode (currently output-only)

set -euo pipefail

REPO="${1:?Usage: dispatch.sh <owner/repo> <agent-username>}"
AGENT="${2:?Usage: dispatch.sh <owner/repo> <agent-username>}"

# Find the most recent actor on an issue (and its linked PR).
last_actor() {
  local number="$1"
  local latest=""

  # Issue: comments
  local comment
  comment=$(gh api "repos/$REPO/issues/$number/comments" \
    --jq 'if length > 0 then .[-1] | "\(.created_at) \(.user.login)" else empty end' 2>/dev/null || true)
  [[ -n "$comment" && "$comment" > "$latest" ]] && latest="$comment"

  # Issue: label events
  local label_event
  label_event=$(gh api "repos/$REPO/issues/$number/events" \
    --jq '[.[] | select(.event == "labeled" or .event == "unlabeled")] |
      if length > 0 then .[-1] | "\(.created_at) \(.actor.login)" else empty end' 2>/dev/null || true)
  [[ -n "$label_event" && "$label_event" > "$latest" ]] && latest="$label_event"

  # Find linked PR (agent branch pattern: agent/{number}-*)
  local pr_number
  pr_number=$(gh pr list --repo "$REPO" --state open --json number,headRefName \
    --jq ".[] | select(.headRefName | startswith(\"agent/$number-\")) | .number" 2>/dev/null | head -1)

  if [[ -n "$pr_number" ]]; then
    # PR: review comments
    local pr_comment
    pr_comment=$(gh api "repos/$REPO/pulls/$pr_number/comments" \
      --jq 'if length > 0 then .[-1] | "\(.created_at) \(.user.login)" else empty end' 2>/dev/null || true)
    [[ -n "$pr_comment" && "$pr_comment" > "$latest" ]] && latest="$pr_comment"

    # PR: reviews
    local review
    review=$(gh api "repos/$REPO/pulls/$pr_number/reviews" \
      --jq 'if length > 0 then .[-1] | "\(.submitted_at) \(.user.login)" else empty end' 2>/dev/null || true)
    [[ -n "$review" && "$review" > "$latest" ]] && latest="$review"

    # PR: issue-style comments (general PR comments)
    local pr_issue_comment
    pr_issue_comment=$(gh api "repos/$REPO/issues/$pr_number/comments" \
      --jq 'if length > 0 then .[-1] | "\(.created_at) \(.user.login)" else empty end' 2>/dev/null || true)
    [[ -n "$pr_issue_comment" && "$pr_issue_comment" > "$latest" ]] && latest="$pr_issue_comment"
  fi

  echo "$latest" | awk '{print $2}'
}

echo "=== $REPO ==="

has_tasks=false

# agent:plan issues
while IFS=$'\t' read -r number title; do
  [[ -z "$number" ]] && continue
  actor=$(last_actor "$number")
  if [[ "$actor" != "$AGENT" ]]; then
    echo "RUN   repo-plan   #$number  $title"
    has_tasks=true
  else
    echo "WAIT  repo-plan   #$number  $title  (user turn)"
  fi
done <<< "$(gh issue list --repo "$REPO" --label "agent:plan" --state open --json number,title --jq '.[] | "\(.number)\t\(.title)"' 2>/dev/null)"

# agent:wip issues
while IFS=$'\t' read -r number title; do
  [[ -z "$number" ]] && continue
  actor=$(last_actor "$number")
  if [[ "$actor" != "$AGENT" ]]; then
    echo "RUN   repo-execute #$number  $title"
    has_tasks=true
  else
    echo "WAIT  repo-execute #$number  $title  (user turn)"
  fi
done <<< "$(gh issue list --repo "$REPO" --label "agent:wip" --state open --json number,title --jq '.[] | "\(.number)\t\(.title)"' 2>/dev/null)"

if [[ "$has_tasks" == false ]]; then
  echo "Nothing to do."
fi
