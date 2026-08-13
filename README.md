# Cuboid Flutter Template

Reusable Flutter starter for Cuboid applications.

## App

This template is built with Stacked MVVM and Supabase. Use `tool/bootstrap.dart` to create an application-specific project identity before product development.

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

Root docs:

- [ARCHITECTURE.md](ARCHITECTURE.md) — current vs. production system, folder structure, conventions, feature checklist
- [RULES.md](RULES.md) — development and AI agent standards, definition of done

Supporting docs:

- [MVP blueprint](doc/Transport_Fleet_MVP_Blueprint.md) — business flow, MVP boundary, records, calculations, security model, acceptance scenarios
- [MVP product design brief](doc/Transport_Fleet_MVP_Design_Brief.md) — screen behavior, wording, accessibility
- [Business flow diagram](doc/Transport_Fleet_MVP_Flow.svg)
- [Research index](doc/research/README.md)
