# Agent Playbook

Operational skills for autonomous AI agents working on continuous and delicate tasks.

## Agent Behavior Principles

- **Don't repeat yourself**: If something failed, try a different approach or escalate. Never retry the same action.
- **Escalate fast**: Being stuck is worse than asking for help.
- **Don't guess tooling**: If you don't know the exact CLI flags, run `--help` first.

## Skills

See [`skills/README.md`](skills/README.md).

## Setup Modes

The agent can work in two modes:

### Fork-based (recommended)

The agent forks the target repo and pushes branches to its fork. PRs are created against the base repo. The owner merges.

Scripts like `propose-rule.sh` automatically sync the fork with the upstream repo via `gh repo sync` before branching.

### Direct push

The agent has push access to the base repo. No fork or sync needed — `git pull origin main` is sufficient.

Both modes are supported by all scripts without extra configuration.

## Tutorial

Setup and example workflow using OpenClaw via Discord.

### 1. Setup

```
# Have the agent clone this repo
Can you fetch https://github.com/yuv-labs/agent-playbook?

# Have the agent install the skills
Can you transplant agent-playbook/skills into your skill-set?

# Clone the target repo and scan it
fetch https://github.com/yuv-labs/baduk
repo-scan baduk
```

### 2. Workflow

Add `agent:plan` label to an issue, then:

```
repo-plan baduk 29          # Agent posts a plan comment on the issue
```

Review the plan. If good, change label to `agent:wip`, then:

```
repo-execute baduk 29       # Agent implements and creates a PR
```

After reviewing the PR and leaving feedback, run again:

```
repo-execute baduk 29       # Agent addresses review feedback
```

If re-discussion is needed, change label back to `agent:plan`:

```
repo-plan baduk 29          # Back to planning
```

### 3. Reference

- [yuv-labs/baduk#18](https://github.com/yuv-labs/baduk/issues/18) → [PR #28](https://github.com/yuv-labs/baduk/pull/28)
- [yuv-labs/baduk#29](https://github.com/yuv-labs/baduk/issues/29) → [PR #30](https://github.com/yuv-labs/baduk/pull/30)
- [yuv-labs/baduk#17](https://github.com/yuv-labs/baduk/issues/17) → [PR #31](https://github.com/yuv-labs/baduk/pull/31)
