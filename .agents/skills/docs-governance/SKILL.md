---
name: docs-governance
description: Discover documentation authorities in unfamiliar repositories and safely update the correct SSOT, ADR, specification, research, runbook, policy, or task document. Use when important docs must be reviewed or changed without duplicating rules, violating accepted architecture, or inventing repository conventions.
---

# Documentation Governance

## Non-Negotiable Rules

- Read every repository and directory instruction applicable to a target file.
- Treat filenames and conventional folders as hints, not proof of authority.
- Follow repository-declared precedence; never impose a universal hierarchy.
- Preserve accepted architecture. Do not document architectural drift as the
  new standard or introduce a boundary without an approved decision.
- Verify implemented claims against code, configuration, tests, or operations.
- Keep one authoritative owner per rule; link instead of copying.
- Preserve read-only snapshots, generated docs, and decision history.
- Touch only files approved by the user.

## Process

### 1. Explore

1. Resolve the repository/component in scope and read applicable instruction
   files such as `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and `RULES.md`.
2. Run the bundled read-only inventory when shell access is available:

   ```bash
   bash scripts/discover-docs.sh /path/to/repository
   ```

3. Identify authority, precedence, read-only/generated paths, ADR conventions,
   validation commands, and frontmatter conventions used by same-type docs.
4. Read the relevant architecture SSOT and related ADRs/RFCs. Inspect existing
   coverage and implementation; surface conflicts instead of normalizing them.
5. Classify facts by their repository-defined owner. As a fallback:
   - current invariant → architecture/SSOT;
   - decision and rationale → ADR/RFC;
   - evidence → research;
   - operational procedure → runbook;
   - remaining work/status → task tracker.

The discovery script finds candidates and metadata signals; it never assigns
authority.

### 2. Report and Stop

Before editing, send a concise pre-update report containing:

- authorities and precedence found;
- relevant accepted architecture and any implementation/doc conflict;
- proposed files, exact change per file, and why each file owns that fact;
- frontmatter to add/update/preserve for each proposed file;
- duplication, uncertainty, and planned validation.

Stop and wait for explicit user confirmation. Do not modify documentation unless
the user confirms the proposal or explicitly waived this checkpoint in the
current request.

### 3. Update After Confirmation

- Modify only confirmed files and facts; amend the existing owning section.
- Add only durable constraints that guide future work. Keep temporary detail in
  research, runbooks, or task trackers as appropriate.
- Use concise repository terminology and normative language. Consolidate stale
  text; do not append a parallel rule.
- For every touched doc, inspect local tooling and same-type siblings. Add or
  normalize frontmatter using the repository's field names and status values.
  If no convention exists, include a minimal proposed schema in the pre-update
  report and use it only after confirmation. Never mass-update untouched docs.
- Refine an existing ADR when the decision identity is unchanged. Create a new
  ADR only for an independent or explicitly superseding decision required by
  local convention; preserve status and history.

### 4. Validate and Report

Search the affected concept again for contradiction or duplication. Run the
repository-prescribed doc checks, tests, linters, or audits. Report files
changed, ownership rationale, frontmatter changes, validation results, and any
remaining manual gate or owner decision.
