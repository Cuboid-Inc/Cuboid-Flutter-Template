# FleetGo — UAE Transport Fleet MVP

This repo contains the FleetGo Flutter app plus the product and system blueprint for a small UAE transport operator.

## App

FleetGo is a fleet operations & money app (Home / Work / Money / More): work orders, invoicing, supplier settlements, payments, and operational profit for a single pilot operator. Flutter + Stacked MVVM + Supabase.

```bash
flutter pub get
dart run build_runner build -d      # codegen (routes, locator)
flutter analyze
flutter test
./scripts/run-app.sh
flutter run --dart-define-from-file=env/dev.json
flutter run --profile --dart-define-from-file=env/dev.json
flutter run --release --dart-define-from-file=env/prod.json
```

The script starts local Supabase and writes its public settings to `env/dev.json`. Run the script before launching a debug or profile build.

## Documentation

Root docs, in source-of-truth order (full hierarchy: [RULES.md](RULES.md) §1):

- [PRD.md](PRD.md) — product goals, users, scope, and success measures
- [ARCHITECTURE.md](ARCHITECTURE.md) — current vs. production system, folder structure, conventions, feature checklist
- [DESIGN.md](DESIGN.md) — color, spacing, typography, and shared UI-primitive tokens
- [RULES.md](RULES.md) — development and AI agent standards, definition of done
- [PHASE.md](PHASE.md) — delivery phases and current status
- [MEMORY.md](MEMORY.md) — local setup, Supabase configuration, and auth decisions

Supporting docs:

- [MVP blueprint](doc/Transport_Fleet_MVP_Blueprint.md) — business flow, MVP boundary, records, calculations, security model, acceptance scenarios
- [MVP product design brief](doc/Transport_Fleet_MVP_Design_Brief.md) — screen behavior, wording, accessibility
- [Business flow diagram](doc/Transport_Fleet_MVP_Flow.svg)
- [Research index](doc/research/README.md)
