# TODO

# TODO Governance (readonly)

- Keep only unresolved implementation work; Git tracks completed history.
- Register newly touched files in a migration row during implementation.
- Always update task progress upon completion.
- After completing a task, provide one short commit message for manual commit.

## Styles
- Forward-only migration, dev-only, fresh reinstall required.
- No backward compatibility – delete all legacy artifacts.
- No drift migrations, upgrade converters, or runtime legacy cleanup.
- Migration means removal, not preservation.
- Add `@Deprecated` annotation to legacy code when detected.

## Actions
- Delete obsolete: classes, models, state fields, APIs/providers, files, persistence, tests, fixtures, comments, docs.
- For uncertain ownership/contract → add to `Findings` with file refs + decision needed. Do not silently retain.

## New Task Template (readonly)

Use `T1`, `T2`, and so on for sequential tasks. For parallel work, use
`P1-A`, `P1-B`, and so on, followed by their dependent `P1-I` integration task.

```md
### T1 - Short task name

**Goal:** None
**Context:** None
**Depends on:** None
**Parallel with:** None
**SSOT:** `docs/business-docs/BUSINESS.md` `BR-*`; `WORKFLOWS.md` `WC-*`;
`ARCHITECTURE.md` §X.Y.
**Scope:** One bounded outcome.

- [ ] Implement the scoped behavior.
- [ ] Add focused replacement coverage.

**Gate**

- [ ] Targeted tests pass.
- [ ] Analyze and relevant audits pass.
- [ ] No changes outside mapped files.

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `path/file.dart` | Migrate | Intended result | T1 | Pending |
```

## Findings

- **F1 — resolved (button placement):** commit `efc79a14` moved the copy/share buttons
  inside the horizontal scroll of `CurlEntryItem._buildTitle`
  (`lib/src/ui/widgets/curl_entry_item.dart`), so on screens <360dp they scroll
  off-screen. Resolved in T4: restored the pinned layout
  (`Row([Expanded(SCSV(chips)), SizedBox(8), _buildActionButtons()])`) — `Expanded`
  absorbs the remaining width, so the row cannot overflow horizontally.

- **F2 — resolved (pre-existing analyze failures):** `dart analyze --fatal-infos`
  previously failed on 30 pre-existing issues outside the T1-T6 batch
  (`example/`, `lib/src/services`, `lib/src/sinks`, `lib/src/events`,
  `lib/src/ui/controllers`, `lib/src/dio_curl_interceptor.dart`, 2 test files).
  Fixed in a follow-up audit: removed unused/unnecessary imports (4); fixed
  example API/type errors — missing `config`, `chatIds` `int`→`String`, non-const
  `NullSink()` (6); removed unnecessary `!`/braces/dead `_replacementsEmbedField`
  and made `_stopwatchTtl` final (6); replaced `print` with
  `logger.warning`/`debugPrint` (14). `dart analyze --fatal-infos` now passes
  with no issues.

## Active Tasks

### T1 - Fix missing imports in `icon_styles.dart`

**Goal:** `lib/src/ui/widgets/icon_styles.dart` compiles — add the missing Flutter import.
**Context:** `efc79a14` added `ActionIconStyle` with no imports, yet it references
`EdgeInsets`, `Colors`, `BoxDecoration`, `BorderRadius`, `Border`, `LinearGradient`,
`Alignment`, `BoxShadow`, `Offset`, `Color`. The analyzer session reported clean
(likely stale) — verify with `dart analyze --fatal-infos`.
**Depends on:** None
**Parallel with:** T4
**SSOT:** `AGENTS.md` §Engineering Rules; review of `efc79a14` (blocking finding).
**Scope:** Add one import line; no behavior change.

- [x] Add `import 'package:flutter/material.dart';` to `icon_styles.dart`.
- [x] Verify with `dart analyze --fatal-infos`.

**Gate**

- [x] `dart analyze --fatal-infos` passes on the batch files (full-repo failures pre-existing — Findings F2).
- [x] No changes outside `lib/src/ui/widgets/icon_styles.dart`.

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `lib/src/ui/widgets/icon_styles.dart` | Fix | Compiles with Flutter import | T1 | Done |

### T2 - Remove dead `ActionIconStyle` members

**Goal:** Delete unused `radiusLG`, `paddingMD`, `paddingLG`, `headerButtonDecoration()`,
`chipDecoration()`.
**Context:** Grep confirms zero usages. Do NOT wire `chipDecoration()` into
`curl_entry_item._buildInfoChip` — existing chips use radius 8, `chipDecoration` uses
`radiusSM` (6), so reuse would change visuals. Removing `chipDecoration()` also drops the
`ColorPalette` dependency.
**Depends on:** T1
**Parallel with:** T4
**SSOT:** Review of `efc79a14` (dead-code finding); TODO §Actions (delete obsolete).
**Scope:** Delete 5 dead members; no behavior change.

- [x] Remove `radiusLG`, `paddingMD`, `paddingLG`, `headerButtonDecoration()`,
      `chipDecoration()`.
- [x] Confirm no remaining references (`grep ActionIconStyle`).
- [x] `dart analyze --fatal-infos` passes.

**Gate**

- [x] Targeted grep + analyze pass.
- [x] No changes outside `lib/src/ui/widgets/icon_styles.dart`.

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `lib/src/ui/widgets/icon_styles.dart` | Delete | Dead members removed | T2 | Done |

### T3 - Unify icon-size constants (single source of truth)

**Goal:** Remove duplicated `CurlViewerStyle.iconSize`; `ActionIconStyle` becomes the only
icon-size source.
**Context:** `CurlViewerStyle.iconSize` (16.0) still used in 10 places in `curl_viewer.dart`
(7 plain `iconSize`, 3 `iconSize * 1.5` = 24). Add `ActionIconStyle.sizeXL = 24`, migrate
all 10 usages, then delete `CurlViewerStyle.iconSize` (migration = removal per TODO
§Styles). Values stay identical — no visual change.
**Depends on:** T2
**Parallel with:** T4
**SSOT:** Review of `efc79a14` (constant duplication); TODO §Actions.
**Scope:** Icon sizes in `curl_viewer.dart` only.

- [x] Add `sizeXL = 24` to `ActionIconStyle`.
- [x] Replace 10 `CurlViewerStyle.iconSize` usages in `curl_viewer.dart`
      (`sizeSM` / `sizeXL`).
- [x] Remove `iconSize` from `CurlViewerStyle`.
- [x] `dart analyze --fatal-infos` and `flutter test` pass.

**Gate**

- [x] No `CurlViewerStyle.iconSize` references remain.
- [x] No changes outside `lib/src/ui/curl_viewer.dart`,
      `lib/src/ui/widgets/icon_styles.dart`.

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `lib/src/ui/curl_viewer.dart` | Migrate | Uses `ActionIconStyle` sizes | T3 | Done |
| `lib/src/ui/widgets/icon_styles.dart` | Migrate | Adds `sizeXL` | T3 | Done |
| `lib/src/ui/curl_viewer.dart` | Delete | `CurlViewerStyle.iconSize` removed | T3 | Done |

### T4 - Restore pinned copy/share buttons in curl entry item

**Goal:** Copy/share buttons always visible on narrow screens; only chips scroll.
**Context:** `efc79a14` moved `_buildActionButtons()` inside the horizontal scroll of
`CurlEntryItem._buildTitle`, so on <360dp the buttons scroll off-screen. Pre-image pinned
them right; the root overflow cause was never proven — verify instead of hiding actions.
Keep the `InkWell`+`Container` styling and `ActionIconStyle` constants introduced by the
commit. See Findings F1.
**Depends on:** None
**Parallel with:** T1-T3
**SSOT:** Review of `efc79a14` (UX tradeoff); `AGENTS.md` §Engineering Rules.
**Scope:** `CurlEntryItem._buildTitle` only.

- [x] Move `_buildActionButtons()` back outside the scroll view (sibling of `Expanded`).
- [x] Keep `SizedBox(width: 8)` gap, `InkWell` styling, `ActionIconStyle` constants.
- [ ] Verify no overflow at 320dp in the example app (manual, on-device).
- [x] `flutter test` passes.

**Gate**

- [x] Layout overflow-safe by construction (`Expanded` absorbs width; 173 tests pass).
- [x] No changes outside `lib/src/ui/widgets/curl_entry_item.dart`.

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `lib/src/ui/widgets/curl_entry_item.dart` | Migrate | Buttons pinned, chips scroll | T4 | Done |

### T5 - Revert unrelated import churn in `curl_viewer.dart`

**Goal:** Restore minimal import block; drop redundant `../ui/` prefixes.
**Context:** `efc79a14` rewrote 6 sibling imports (`'bubble_overlay.dart'` →
`'../ui/bubble_overlay.dart'`, etc.) — redundant since the file lives in `lib/src/ui/` and
inconsistent with other widgets. Register `icon_styles.dart` with the local style
(`'widgets/icon_styles.dart'`).
**Depends on:** T3 (same file)
**Parallel with:** T4
**SSOT:** Review of `efc79a14` (scope creep); `AGENTS.md` §Engineering Rules.
**Scope:** Import block of `curl_viewer.dart` only.

- [x] Restore `'bubble_overlay.dart'`, `'controllers/curl_viewer_controller.dart'`,
      `'widgets/curl_entry_item.dart'`, `'widgets/status_summary.dart'`,
      `'widgets/curl_viewer_header.dart'`, `'widgets/filter_rule_editor.dart'`,
      `'widgets/icon_styles.dart'`.
- [x] `dart analyze --fatal-infos` passes.

**Gate**

- [x] No changes outside `lib/src/ui/curl_viewer.dart`.

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `lib/src/ui/curl_viewer.dart` | Migrate | Minimal import block | T5 | Done |

### T6 - Formatting & class hygiene

**Goal:** Batch files `dart format`-clean; `ActionIconStyle` non-instantiable; trailing newline.
**Context:** Lines >80 chars in `curl_viewer_header.dart` (terminal/refresh/close icons,
e.g. line 121); `icon_styles.dart` missing trailing newline; `ActionIconStyle` is
instantiable — match the codebase convention (`CurlViewerStyle._()` private constructor,
`curl_viewer.dart` L24-28) or use `abstract final class` (Dart 3 already required by
`sealed` types). Format scope is the 5 files of this batch only — `dart format .` on the
whole package could touch unrelated pre-existing files; if it does, raise a new finding
instead of silently formatting them.
**Depends on:** T3, T5 (format all touched files)
**Parallel with:** T4
**SSOT:** `AGENTS.md` §Formatting; review of `efc79a14` (minor findings).
**Scope:** Formatting of batch files + one class declaration change.

- [x] Make `ActionIconStyle` non-instantiable (private constructor, matching `CurlViewerStyle._()`).
- [x] Add trailing newline to `icon_styles.dart`.
- [x] Run `dart format` on the 5 batch files and keep the formatted result.
- [x] `flutter test` passes (full suite after formatting).

**Gate**

- [x] `dart format --output=none --set-exit-if-changed` passes on the 5 batch files.
- [x] `dart analyze --fatal-infos` passes on the batch files (full-repo failures pre-existing — Findings F2).
- [x] No changes outside the mapped files (other flagged files → Findings F2).

**Migration File Table**

| Current File | Action | Final Result | Phase | Status |
|---|---|---|---|---:|
| `lib/src/ui/widgets/icon_styles.dart` | Migrate | Non-instantiable, trailing newline | T6 | Done |
| `lib/src/ui/widgets/curl_viewer_header.dart` | Migrate | Long lines wrapped | T6 | Done |
| `lib/src/ui/curl_viewer.dart` | Format | Clean | T6 | Done |
| `lib/src/ui/widgets/curl_entry_item.dart` | Format | Clean | T6 | Done |
| `lib/src/ui/widgets/filter_rule_editor.dart` | Format | Clean — no changes needed | T6 | Done |
