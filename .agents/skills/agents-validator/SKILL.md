---
name: agents-validator
description: Use when validating CLAUDE.md and AGENTS.md hierarchies across directories, checking that every CLAUDE.md contains @AGENTS.md on its own line, and content meets minimum word counts before using agent teams.
compatibility: Requires bash, find, grep, wc (standard Unix tools).
---

# Agents Validator

Validates that CLAUDE.md and AGENTS.md are properly structured for agent team workflows.

## Rule: CLAUDE.md Contains ONLY @AGENTS.md

```
✅ CORRECT
@AGENTS.md

❌ WRONG
# Module Name
@AGENTS.md

❌ WRONG
Follow @AGENTS.md

❌ WRONG
[missing @AGENTS.md entirely]
```

CLAUDE.md is thin: just the import line. Everything else goes in AGENTS.md.

## Minimum Standards

| Level | CLAUDE.md | AGENTS.md |
|-------|-----------|-----------|
| Root | Only: `@AGENTS.md` | 200-300 words |
| Module | Only: `@AGENTS.md` | 80-150 words |

Both files must have valid Markdown. AGENTS.md must have `#` heading and substantive content.

## Workflow

1. Point to project: `--path /project` or current directory
2. Choose depth: Root only / Root+modules / Full hierarchical (buttons)
3. Choose ignore: .gitignore / defaults / custom
4. Get report: ✅ PASS | ⚠️  WARN | ❌ FAIL

## Quick Start

```bash
claude --path /home/user/project
# Answers prompts, runs audit, shows violations
```

## Common Issues

**Missing @AGENTS.md**
→ Add it to every CLAUDE.md, on its own line

**@AGENTS.md embedded in text**
→ Must be standalone: `@AGENTS.md` only

**AGENTS.md too short**
→ Root: 200 words min. Module: 80 words min.

**Orphaned AGENTS.md**
→ Create paired CLAUDE.md in same directory

**@../AGENTS.md or @root/AGENTS.md**
→ Not supported. Same directory only: `@AGENTS.md`

## Correct Minimal CLAUDE.md

```markdown
@AGENTS.md
```

That's it. Nothing else. AGENTS.md contains everything (heading, content, standards).

---

Run before starting agent teams. Re-run quarterly as standard practice.