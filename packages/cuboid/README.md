# Cuboid

A command-line tool for scaffolding and maintaining Flutter apps built on
Cuboid's own MVVM architecture -- no third-party MVVM framework, no
code-generation step. `cuboid` stamps out a new project from a built-in
starter template, then keeps growing it: features, views, services, storage,
and a Supabase-backed database all come from one consistent generator so a
team doesn't have to hand-wire dependency injection, routing, and boilerplate
for every new screen.

## Installation

```bash
dart pub global activate cuboid
```

This puts `cuboid` on your `PATH` at the same location `dart pub global
activate` always uses. Confirm it's installed:

```bash
cuboid --help
```

> If `cuboid` fails with a shell error like `[: too many arguments`, your
> `~/.pub-cache` path contains a space. That's a limitation in the shim
> `dart pub global activate` generates, not something specific to this
> package -- set `PUB_CACHE` to a space-free directory and reactivate.

## Creating a Flutter app

```bash
cuboid create app "My App" com.example.myapp
```

This creates a new project directory (in the current directory by default;
pass `-o/--output-dir` to choose another) from Cuboid's Flutter starter
template, renames it to your app's identity, runs `flutter pub get` and
`dart format`, and leaves you with a runnable Flutter app using Cuboid's
MVVM, dependency injection (get_it-based), and routing.

Package identifiers (`com.example.myapp`) may use letters and numbers; each
dot-separated segment must start with a letter.

Add `--dry-run` to preview what would be created without writing anything,
or `--post-steps=false` to skip `flutter pub get`/`dart format`.

## Scaffolding inside a generated project

Run these from the root of a project `cuboid create app` generated:

```text
cuboid create feature <name>           # view, view model, repository; registers its route
cuboid create service <name>           # a core service, registered with the locator
cuboid create bottomsheet <name>       # patches app.bottomsheets.dart itself
cuboid create dialog <name>            # patches app.dialogs.dart itself
cuboid create storage                  # local key-value/secure storage wrapper
cuboid create database supabase        # Supabase example model, repository, migration
cuboid create view <name> <feature>    # additional view in an existing feature; registers its route
cuboid create view <name>              # shared view
cuboid create model <name>             # a bare model
cuboid create widget <name>            # shared widget, under lib/shared/widgets/<name>/
cuboid create widget <name> <feature>  # feature-scoped widget
```

There is no separate `route` or `repository` command: `cuboid create
feature` generates and registers a feature's repository, and creating a
feature or view registers its route, automatically. Every command supports
`--dry-run`, and none require a code-generation step afterward --
`app.locator.dart`, `app.router.dart`, `app.bottomsheets.dart`, and
`app.dialogs.dart` are plain Dart files each command patches directly.

Reverse most of the above with `cuboid delete <artifact>`:

```text
cuboid delete service <name>
cuboid delete feature <name>           # also removes its route(s) and repository
cuboid delete bottomsheet <name>       # removes app.bottomsheets.dart too if it was the last bottom sheet
cuboid delete dialog <name>            # removes app.dialogs.dart too if it was the last dialog
cuboid delete storage
cuboid delete database supabase
cuboid delete view <name> <feature>    # also removes the view's route
cuboid delete widget <name>            # shared or feature-scoped, matching create
cuboid delete route <name>             # router entry only; does not touch View files
```

`cuboid delete` never removes `app.locator.dart` or `app.router.dart`
themselves -- only the entries a matching `create` command added. Deleting
the last dialog or bottom sheet also tears down its owning service; deleting
an earlier one leaves that shared infrastructure in place. There is no
`cuboid delete model` or `cuboid delete app`. Deleting something that was
never created is an error, not a silent no-op, matching how every `create`
command treats unexpected state.

## Example workflow

```bash
cuboid create app "Acme" com.acme.app
cd acme
cuboid create feature profile
cuboid create view edit_profile profile
cuboid create service analytics
cuboid create storage
cuboid create database supabase
flutter run
```

## Generated architecture

Every generated project is feature-first:

```text
lib/
|-- app/       Locator, router, app root -- CLI-patched, hand-editable
|-- core/      Constants, errors, formatters, forms, models, services,
|              storage, theme, and validators
|-- features/  One directory per feature, each with its own ui/ and,
|              once it has persistent data, repository
`-- shared/    Reusable widgets
```

The base template is technology-neutral: no backend or storage technology is
installed until you ask for one with `cuboid create database <provider>` or
`cuboid create storage`.

## Template and runtime architecture

`cuboid create app` doesn't read from a template directory on disk at
runtime -- the Flutter app template is embedded directly in the compiled
`cuboid` binary, so project creation works identically whether `cuboid` runs
from source or as an installed executable, with no dependency on any
particular checkout.

Cuboid's MVVM runtime (`CuboidView`/`CuboidViewModel`, get_it-based service
location, dialog/bottom-sheet services) lives in a separate framework
package, `cuboid_flutter`, rather than inside a generated app's own `lib/`
tree. On first use, `cuboid` vendors `cuboid_flutter` into a machine-global
cache and points the generated project's `pubspec.yaml` at it via a `path:`
dependency -- keeping that implementation detail out of the generated
project's visible source tree while still resolving `package:cuboid_flutter/...`
as an ordinary local package.

## Development

This package is developed inside the
[Cuboid-Flutter-Template](https://github.com/Cuboid-Inc/Cuboid-Flutter-Template)
monorepo, alongside the `cuboid_flutter` runtime and the starter template
itself. From a checkout:

```bash
dart pub get
dart analyze
dart test
```
