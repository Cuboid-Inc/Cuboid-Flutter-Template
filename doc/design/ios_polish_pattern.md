# iOS list-row polish pattern

Applied to Reports (`lib/features/reports/`) and More (`lib/features/more/`). Use this
same treatment when polishing any other grouped-list screen (menus, report/detail
breakdowns, settings-style screens).

## The row shape

Every row in a grouped list follows this structure, wrapped together in one
`ListCard(padding: EdgeInsets.zero, ...)` per section, with `Divider(height: 1, indent: 60)`
between rows (no divider after the last row):

```dart
Row(
  children: [
    Container(                                   // icon tile
      width: 36, height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.tintBg,                      // e.g. AppColors.chipBg / successBg / warningBg / dangerBg / neutralChipBg
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Icon(item.icon, color: item.tint, size: 18),
    ),
    const SizedBox(width: s12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
          Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    ),
    const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.mutedLight),
  ],
)
```

## Rules

- **Icons**: `CupertinoIcons` only, never Material `Icons.*`. Prefer the `_fill`/`_solid` variants for leading tile icons — they read
  better at 18px than the outline variants.
- **Per-item tint, not one flat color**: give each row/category a distinct
  `tint`/`tintBg` pair pulled from `AppColors` so the list reads as categorized, not
  monochrome. Reuse the same tint across a concept everywhere it appears (e.g. Reports'
  "unpaid invoices" tile and any other unpaid-invoice affordance both use
  `AppColors.danger` / `dangerBg`).
  - `primary` / `chipBg` — default/neutral-positive (money, primary actions)
  - `success` / `successBg` — fleet/operational, staff, positive money
  - `warning` / `warningBg` — attention-needed but not urgent (drivers, expenses)
  - `danger` / `dangerBg` — overdue, expiring, urgent
  - `muted` / `neutralChipBg` — administrative/config, no urgency
- **Compaction over cards**: prefer a single-column grouped list (`ListCard` + row +
  `Divider`) over a 2-column grid of bulky cards. It's denser, scans faster, and matches
  native iOS Settings-style screens — reserve grid layouts for things that are genuinely
  visual (e.g. a metric dashboard), not a menu of destinations.
  - Everything is a `MoreMenuItem`/tuple-style plain data object (`title`, `subtitle`,
    `icon`, `tint`, `tintBg`, `onTap`) built in the ViewModel — no per-screen bespoke
    widget classes for what's fundamentally the same row.
- **Contextual value coloring**: when a row's trailing value has real semantic meaning
  (overdue amount, money in vs. money out), color it accordingly instead of leaving it
  default ink — but don't invent data plumbing just for this; derive it from data already
  on hand (e.g. switch on the known report `type`, or a fixed label already in the row).
- **Empty state**: any list-driven detail screen shows `EmptyState` (`lib/ui/widgets/empty_state.dart`)
  when there's nothing to display — reuse the section's own icon/tint so the empty state
  doesn't look like a generic fallback.

## Where the reusable pieces live

- `lib/ui/widgets/list_card.dart` — the white rounded card wrapper.
- `lib/ui/widgets/app_bar_ios.dart` — `AppBarIOS`/`AppBarTextAction`/`AppBarIconAction`.
- `lib/ui/widgets/empty_state.dart` — `EmptyState`.
- `lib/ui/common/app_colors.dart` — tint/tintBg tokens.
- `lib/ui/common/ui_helpers.dart` — `s4..s32` spacing scale, `radiusSm/Md/Lg/Pill`.

See `lib/features/reports/ui/report_type_meta.dart` and
`lib/features/more/ui/more_viewmodel.dart` (`MoreMenuItem`) for worked examples of the
per-item `icon`/`tint`/`tintBg` extension/class pattern.
