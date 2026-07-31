#!/usr/bin/env bash
set -euo pipefail

target_root="${1:-.}"

if [[ ! -d "$target_root" ]]; then
  echo "error: repository root is not a directory: $target_root" >&2
  exit 2
fi

cd "$target_root"
resolved_root="$(pwd -P)"

candidate_pattern='(^|/)(AGENTS|CLAUDE|GEMINI|RULES|CONTRIBUTING|GOVERNANCE|ARCHITECTURE|DESIGN|BUSINESS|WORKFLOWS|LANG|TODO|ROADMAP|SECURITY|SUPPORT|README)(\.[^/]*)?$|(^|/)(ADR|RFC)[-_0-9]|(^|/)(docs?|documentation)/(decisions?|adrs?|rfcs?|architecture|design|specs?|research|runbooks?|policies)(/|$)'
document_pattern='\.(md|mdx|adoc|rst|txt|pdf|docx|odt|mmd|puml|ya?ml|toml|json)$'
authority_pattern='single source of truth|source of truth|\bSSOT\b|documentation authority|authoritative (document|record|source|specification|reference)|canonical (document|source|specification|reference)|conflict order|authority order|wins over|supersed(es|ed|ing)|replaced by|read[- ]only (document|file|directory|folder|reference|snapshot)|(do not|must not) (edit|modify)|generated (file|document|documentation)'
metadata_pattern='^(type|kind|status|authority|ssot|supersedes|supersededby|updated):'

print_header() {
  printf '\n## %s\n' "$1"
}

echo "documentation inventory root: $resolved_root"

if command -v rg >/dev/null 2>&1; then
  common_globs=(
    --hidden
    -g '!**/.git/**'
    -g '!**/.hg/**'
    -g '!**/.svn/**'
    -g '!**/node_modules/**'
    -g '!**/vendor/**'
    -g '!**/build/**'
    -g '!**/dist/**'
    -g '!**/.dart_tool/**'
    -g '!**/.gradle/**'
    -g '!**/.cache/**'
    -g '!**/.agents/skills/**'
    -g '!**/.claude/skills/**'
    -g '!**/.codex/skills/**'
  )

  print_header 'Candidate governance and documentation files'
  rg --files "${common_globs[@]}" \
    | awk -v candidate="$candidate_pattern" -v document="$document_pattern" \
        'BEGIN { IGNORECASE=1 } $0 ~ candidate && $0 ~ document' \
    | LC_ALL=C sort -fu

  print_header 'Explicit authority, precedence, and mutability declarations'
  rg -n -i "$authority_pattern" "${common_globs[@]}" \
    -g '*.md' -g '*.mdx' -g '*.adoc' -g '*.rst' -g '*.txt' \
    || true

  print_header 'Common frontmatter metadata signals'
  rg -n -i "$metadata_pattern" "${common_globs[@]}" \
    -g '*.md' -g '*.mdx' -g '*.adoc' -g '*.rst' \
    || true
else
  print_header 'Candidate governance and documentation files'
  find . -type f \
    ! -path '*/.git/*' \
    ! -path '*/.hg/*' \
    ! -path '*/.svn/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/vendor/*' \
    ! -path '*/build/*' \
    ! -path '*/dist/*' \
    ! -path '*/.dart_tool/*' \
    ! -path '*/.gradle/*' \
    ! -path '*/.cache/*' \
    ! -path '*/.agents/skills/*' \
    ! -path '*/.claude/skills/*' \
    ! -path '*/.codex/skills/*' \
    | sed 's#^\./##' \
    | awk -v candidate="$candidate_pattern" -v document="$document_pattern" \
        'BEGIN { IGNORECASE=1 } $0 ~ candidate && $0 ~ document' \
    | LC_ALL=C sort -fu

  print_header 'Explicit authority, precedence, and mutability declarations'
  find . -type f \
    \( -name '*.md' -o -name '*.mdx' -o -name '*.adoc' -o -name '*.rst' -o -name '*.txt' \) \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/vendor/*' \
    ! -path '*/build/*' \
    ! -path '*/dist/*' \
    -exec grep -nEi "$authority_pattern" {} + \
    || true

  print_header 'Common frontmatter metadata signals'
  find . -type f \
    \( -name '*.md' -o -name '*.mdx' -o -name '*.adoc' -o -name '*.rst' \) \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/vendor/*' \
    ! -path '*/build/*' \
    ! -path '*/dist/*' \
    -exec grep -nEi "$metadata_pattern" {} + \
    || true
fi
