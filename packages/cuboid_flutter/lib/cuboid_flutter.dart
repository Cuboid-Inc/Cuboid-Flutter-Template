/// Cuboid's in-house MVVM runtime: `CuboidView` and `CuboidViewModel`.
///
/// Every generated Cuboid application depends on this package (vendored via
/// a path dependency) instead of shipping the framework implementation
/// inside its own `lib/` folder.
library;

export 'src/cuboid_view.dart';
export 'src/cuboid_view_model.dart';
