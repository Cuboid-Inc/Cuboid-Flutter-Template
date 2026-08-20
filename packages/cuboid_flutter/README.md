# cuboid_flutter

`cuboid_flutter` is the small Flutter runtime used by Cuboid-generated apps.
It provides the base MVVM building blocks that generated views import at
runtime:

- `CuboidView`
- `CuboidViewModel`

## Usage

Add the package to a Flutter app:

```yaml
dependencies:
  cuboid_flutter: ^0.1.0
```

Then import the public API:

```dart
import 'package:cuboid_flutter/cuboid_flutter.dart';
```

Create a view model by extending `CuboidViewModel`:

```dart
class CounterViewModel extends CuboidViewModel {
  int count = 0;

  void increment() {
    count += 1;
    notifyListeners();
  }
}
```

Create a view by extending `CuboidView`:

```dart
class CounterView extends CuboidView<CounterViewModel> {
  const CounterView({super.key});

  @override
  CounterViewModel viewModelBuilder(BuildContext context) => CounterViewModel();

  @override
  Widget builder(
    BuildContext context,
    CounterViewModel viewModel,
    Widget? child,
  ) {
    return Text('Count: ${viewModel.count}');
  }
}
```

## Runtime Scope

This package does not depend on the Cuboid CLI, repository-local paths, or a
machine-local Cuboid installation. Flutter apps can consume it from pub.dev or
from a local path dependency.
