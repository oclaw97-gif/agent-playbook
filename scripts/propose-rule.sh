#!/bin/bash
# propose-rule.sh - Create a PR proposing a new codebible rule.
# Usage: propose-rule.sh <language> <filename> <rule-file-path> <source-url> <source-comment>
#
# Example:
#   propose-rule.sh general prefer-early-returns.md /tmp/rule.md \
#     "https://github.com/yuv-labs/baduk/pull/33#comment-123" \
#     "Use early returns to reduce nesting"
#
# The rule file should already be written in _template.md format.
# This script handles: branch creation, file copy, commit, push, PR creation.

set -euo pipefail

LANGUAGE="${1:?Usage: propose-rule.sh <language> <filename> <rule-file-path> <source-url> <source-comment>}"
FILENAME="${2:?}"
RULE_FILE="${3:?}"
SOURCE_URL="${4:?}"
SOURCE_COMMENT="${5:?}"

REPO_ROOT=$(git rev-parse --show-toplevel)
BRANCH="codebible/${FILENAME%.md}"
TARGET_DIR="codebible/$LANGUAGE"
TARGET_PATH="$TARGET_DIR/$FILENAME"

# Extract title from first ## heading
TITLE=$(grep '^## ' "$RULE_FILE" | head -1 | sed 's/^## //')

# Create branch from main
git checkout main
git pull --ff-only origin main 2>/dev/null || true
git checkout -b "$BRANCH"

# Copy rule file
mkdir -p "$REPO_ROOT/$TARGET_DIR"
cp "$RULE_FILE" "$REPO_ROOT/$TARGET_PATH"

# Commit and push
git add "$TARGET_PATH"
git commit -m "$(cat <<EOF
codebible: add rule — $TITLE

Source: $SOURCE_URL
EOF
)"
git push -u origin "$BRANCH"

# Create PR
gh pr create --title "codebible: $TITLE" --body "$(cat <<EOF
## Proposed rule

**Source:** $SOURCE_URL

**Original comment:**
> $SOURCE_COMMENT

---
- **Merge** to accept this rule into the codebible.
- **Close** to reject.
EOF
)"

# Return to main
git checkout main
