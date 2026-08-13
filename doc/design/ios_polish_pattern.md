# iOS list-row polish pattern

Use this treatment when polishing grouped-list screens such as menus, settings,
detail breakdowns, and other compact destination lists.

## The row shape

Every row in a grouped list follows this structure, wrapped together in one
section container with `padding: EdgeInsets.zero`, and `Divider(height: 1,
indent: 60)` between rows:

```dart
Row(
  children: [
    Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.tintBg,
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Icon(item.icon, color: item.tint, size: 18),
    ),
    const SizedBox(width: s12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            item.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    ),
    const Icon(
      CupertinoIcons.chevron_right,
      size: 16,
      color: AppColors.mutedLight,
    ),
  ],
)
```

## Rules

- **Icons**: use `CupertinoIcons` for iOS-style grouped rows. Prefer filled
  variants for leading tile icons when they read better at 18px.
- **Per-item tint, not one flat color**: give each row/category a distinct
  `tint`/`tintBg` pair pulled from `AppColors` so the list reads as categorized,
  not monochrome. Reuse the same tint for the same concept everywhere it appears.
- **Compaction over cards**: prefer a single-column grouped list with row
  dividers over bulky menu cards. Reserve grid layouts for genuinely visual
  choices or dashboards.
- **Plain data objects**: build row metadata in the ViewModel or a small
  feature-owned metadata object with `title`, `subtitle`, `icon`, `tint`,
  `tintBg`, and `onTap`. Do not create bespoke row widgets for the same repeated
  pattern.
- **Contextual value coloring**: when a trailing value has real semantic meaning,
  color it accordingly. Do not add new data plumbing only for color; derive the
  state from data already available to the row.
- **Empty state**: list-driven detail screens should show `EmptyState`
  (`lib/shared/widgets/empty_state.dart`) when there is nothing to display. Reuse
  the section's own icon/tint so the empty state feels connected to the screen.

## Where reusable pieces live

- `lib/shared/widgets/app_bar_ios.dart` — standard iOS-style app bars.
- `lib/shared/widgets/empty_state.dart` — empty states.
- `lib/shared/widgets/paginated_list/` — paginated list widgets.
- `lib/core/theme/app_colors.dart` — tint/tintBg tokens.
- `lib/core/theme/ui_helpers.dart` — shared spacing and radius constants.

Feature-specific row metadata and widgets belong under
`lib/features/<feature>/ui/`.
