# FleetGo

UAE transport-fleet operations & money app (Home / Work / Money / More) for a single pilot operator.
Flutter + Stacked MVVM + Supabase (no custom API). Package `fleetgo`, bundle id `com.cuboidinc.fleetgo`.

## Commands

```bash
flutter pub get
dart run build_runner build -d      # after any change to app/app.dart (routes/DI)
flutter analyze
flutter test
./scripts/run-app.sh
flutter run --dart-define-from-file=env/dev.json
flutter run --profile --dart-define-from-file=env/dev.json
flutter run --release --dart-define-from-file=env/prod.json
```

The script starts local Supabase and generates `env/dev.json`. Release builds throw at startup without config. Repositories never check `Env.isConfigured` themselves — `guard()` owns that check.

### Stacked CLI (team workflow)

`stacked.json` (repo root) redirects the CLI to this repo's feature-first layout — use the CLI as usual:

```bash
stacked create view invoices     # → lib/features/invoices/ + auto route in app/app.dart
stacked create service pricing   # → lib/core/services/ + auto DI registration
stacked create widget fuel_gauge # → lib/ui/widgets/
stacked generate                 # = dart run build_runner build -d
```

One rule: the CLI always creates a view as a NEW top-level feature folder. For a **sub-screen of an existing feature** (e.g. work detail), generate it, then move the two files into `lib/features/<feature>/ui/<screen>/` and fix the import path in `app/app.dart`. Repositories are not CLI-generated — hand-copy from the parties template.

## Documentation

Source-of-truth order (see RULES.md §1 for the full hierarchy): `PRD.md` for product goals/scope,
`doc/Transport_Fleet_MVP_Blueprint.md` for business rules/calculations, `doc/Transport_Fleet_MVP_Design_Brief.md`
for screen/interaction behavior, **`ARCHITECTURE.md`** for code structure — read it before adding features —
`DESIGN.md` for color/spacing/typography tokens, and `RULES.md` for implementation and AI agent standards.
When two sources disagree, stop and ask rather than guessing. Copy `lib/features/parties/` as the template slice.

Key conventions:

- **Feature-first**: `lib/features/<name>/{data,ui}`. A feature's `data/` is public (other features may import its models/repositories); its `ui/` is private — never import another feature's `ui/`. Cross-feature repositories via `locator<...>()` (singletons). A model used by 3+ features or causing an import cycle gets promoted to `lib/core/models/`. Full rules: RULES.md ARCH-06–09.
- **Result errors**: repositories return sealed `Result<T>` (`lib/core/result.dart`); every data call wrapped in `guard()` (`lib/core/supabase/supabase_guard.dart`); ViewModels `switch` exhaustively.
- **No dartz, no dio, no freezed** — deliberate (ADRs in ARCHITECTURE.md). One model class with `fromJson`/`toJson`; UseCases only for real business logic.
- **Centralized config**: locale/currency/date patterns in `lib/core/config/app_config.dart`; all money/date/time display via `Formatters` (`lib/core/config/formatters.dart`). Never format inline in widgets.
- **Money rules**: Postgres `numeric`, never float; half-up rounding to 2dp; financial transactions run in privileged Postgres functions, never client-side.
- **Issued documents are immutable**: invoices/settlements lock a snapshot at issue; corrections = void + reissue. Never write code that mutates an issued document. Master data archives, never hard-deletes.
- Package imports only (`package:cuboid_flutter_template/...`), no relative imports.
- Registered sheets and dialogs use Stacked services from ViewModels. No context-based presentation in ViewModels.
- **UI & Icon Preference**: Focus on Cupertino icons (`CupertinoIcons`) and iOS-style UI guidelines for a cleaner, more premium look. For polishing/compacting any grouped-list screen (menus, report breakdowns, settings), follow the row pattern documented in `doc/design/ios_polish_pattern.md` (tinted icon tile + title/subtitle + chevron, `ListCard` + `Divider`, per-category tint colors) instead of inventing a new layout.

## Design reference

Manrope, primary `#11B2F3`, navy `#101828`, bg `#F4F6F9` — full token set in `DESIGN.md`,
sourced from `lib/ui/common/`.
