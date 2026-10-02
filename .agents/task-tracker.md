# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments` (always specify `--json` fields to bypass the GitHub GraphQL `projectCards` deprecation failure). Pass `--repo <owner>/<repo>` if run outside clone root or across multiple remotes.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`
- **Number space**: GitHub shares one number space across issues and PRs. If `#42` is ambiguous, resolve with `gh pr view <number> --json number,title,body,state` and fall back to `gh issue view <number> --json number,title,body,labels,comments`.

Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone, or pass `--repo <owner>/<repo>` explicitly.

## When a skill says "publish to the issue tracker"

Create a GitHub issue via `gh issue create`.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --json number,title,body,labels,comments` (with `--repo <owner>/<repo>` when explicit).

## Task Decomposition & Execution Operations

Used by `/to-tasks` and `/forge`:

- **Publish Task**: `gh issue create --title "<NN>: <Task Title>" --body "..."` with embedded changeset and acceptance criteria.
- **Blocking Dependencies**: GitHub's **native issue dependencies**, the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, *not* the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only, the live gate). Where native dependencies aren't available, fall back to a `**Blocked by**: #<n>` line at the top of the issue body. A ticket is unblocked when every blocker is closed.
- **Frontier Query**: List open issues (`gh issue list --state open ...`), filter for unblocked issues (no open blockers in `issue_dependencies_summary.blocked_by` or in `Blocked by` line). First in sequence order is the active frontier.
- **Claim**: `gh issue edit <number> --add-assignee @me`.
- **Resolve**: Ensure all acceptance criteria are verified `[x]`, post resolution comment, and close: `gh issue close <number> --comment "<resolution summary>"`.
