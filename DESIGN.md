# FleetGo Design Language

Single source of truth for visual style. Pulled from actual tokens in the codebase —
if this ever disagrees with `lib/ui/common/`, the code wins; fix this file.

Style target: **iOS-native** (Cupertino icons, grouped Settings-style lists, centered
app bar titles, chevron navigation) rendered with Material widgets. `lib/ui/common/`
is the pixel reference — this file documents its tokens.

## Typography

Font: **Manrope** via `google_fonts` (`AppTheme.light`, `lib/ui/common/app_theme.dart`).
Base text color `AppColors.ink`.

| Use | Size | Weight |
|---|---|---|
| App bar title (`AppBarIOS`) | 16 | w800 |
| Row title | 14.5 | w700 |
| Row subtitle / caption | 12 | regular, `AppColors.muted` |
| Body | 15 | regular |
| Button label | 15 | w800 |
| App bar text action | 15 | w600 |
| Empty state title | default | w800 |

No custom `TextStyle`s scattered per-screen beyond these — reuse the row/app-bar
patterns below instead of inventing new sizes.

## Color (`lib/ui/common/app_colors.dart`)

```
primary       #11B2F3   primaryDark  #0E57C1
ink #0F1728  navy #101828  body #334155  muted #64748B  mutedLight #98A2B3
bg #F4F6F9   border #E5E9F0   white #FFFFFF   rowHover #F8FAFC
neutralChipBg #EEF1F6   chipBg (info/selected) #EFF4FE
success #16A34A / successText #16803C / successBg #E9F9EF
danger  #DC2626 / dangerDark  #B91C1C / dangerBg  #FDECEC
warning #B45309 / warningDark #92400E / warningBg #FEF3E2
```

**Semantic tint pairs** — each `tint`/`tintBg` pair means the same thing everywhere it
appears (reuse across screens, never invent a new tint for the same concept):

- `primary` / `chipBg` — default / neutral-positive (money, primary actions)
- `success` / `successBg` — fleet/operational, staff, positive money
- `warning` / `warningBg` — attention-needed but not urgent (drivers, expenses)
- `danger` / `dangerBg` — overdue, expiring, urgent
- `muted` / `neutralChipBg` — administrative/config, no urgency

Never hardcode hex in a widget — always `AppColors.*`.

## Spacing & radius (`lib/ui/common/ui_helpers.dart`)

```
s4 s8 s12 s16 s20 s24 s32       — spacing scale, px
radiusSm 12  radiusMd 16  radiusLg 20  radiusPill 999
cardShadow                       — subtle shadow behind dark hero cards
```

Always use these constants, never a raw `EdgeInsets`/`BorderRadius` number.

## Core primitives (`lib/ui/widgets/`)

- **`ListCard`** — white rounded container (`radiusMd`, `AppColors.border` outline,
  `AppColors.white` fill), optional `onTap`. The base wrapper for every row/section
  group in the app.
- **`AppBarIOS`** — centered w800 16px title, `CupertinoIcons.chevron_back` leading,
  no default elevation. Use instead of raw `AppBar` everywhere.
  - `AppBarTextAction` — text button, w600 15px, `AppColors.primary`.
  - `AppBarIconAction` — plain `IconButton`.
- **`EmptyState`** — centered icon (42px, `mutedLight`) + w800 title + muted subtitle.
  Reuse the section's own icon/tint instead of falling back to a generic inbox glyph.

## Icons

`CupertinoIcons` only — never Material `Icons.*` (hard rule, see CLAUDE.md). Prefer the
`_fill`/`_solid` variant for leading tile icons; outline variants read too thin at 18px.

## Grouped-list row pattern

The house pattern for any menu/report-breakdown/settings-style screen. Full narrative
version: `doc/design/ios_polish_pattern.md`. One `ListCard(padding: EdgeInsets.zero)`
per section, rows separated by `Divider(height: 1, indent: 60)` (no divider after the
last row):

```dart
Row(
  children: [
    Container(                                   // icon tile, 36x36
      width: 36, height: 36,
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
          Text(item.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
          Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    ),
    const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.mutedLight),
  ],
)
```

Rules:

- Build rows as plain data objects (title, subtitle, icon, tint, tintBg, onTap) in the
  ViewModel — no bespoke per-screen row widget class.
- Prefer a single-column grouped list over a 2-column card grid; reserve grids for
  genuinely visual content (metric dashboards), not menus.
- Color a trailing value semantically (overdue amount → danger, money in/out) only
  when the meaning already exists on the data — don't add plumbing just for color.

## Theme wiring (`lib/ui/common/app_theme.dart`)

`AppTheme.light` is the only `ThemeData`. Scaffold background `AppColors.bg`, cards
`AppColors.white` with `radiusMd` + `border` outline, elevated buttons flat
(`elevation: 0`) with `radiusSm`, inputs filled white with `radiusSm` borders
(`border` → `primary` @ 1.5px on focus), chips `chipBg`/`primary` pill-shaped
(`radiusPill`).

## Formatting

Money/date/time are never formatted inline in widgets — always via `Formatters`
(`lib/core/config/formatters.dart`) driven by `AppConfig` (`lib/core/config/app_config.dart`,
locale `en_AE`, currency `AED`, date `dd MMM yyyy`).
