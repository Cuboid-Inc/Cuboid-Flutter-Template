import 'package:flutter/material.dart';

/// Base class for Cuboid views.
///
/// Creates and owns a [T] view model, rebuilding [builder] whenever the view
/// model notifies listeners. Replaces Stacked's `StackedView`.
abstract class CuboidView<T extends ChangeNotifier> extends StatefulWidget {
  const CuboidView({super.key});

  /// Creates the view model instance for this view.
  T viewModelBuilder(BuildContext context);

  /// Called once, immediately after the view model is created.
  void onViewModelReady(T viewModel) {}

  /// Builds the widget tree for the current [viewModel] state.
  Widget builder(BuildContext context, T viewModel, Widget? child);

  @override
  State<CuboidView<T>> createState() => _CuboidViewState<T>();
}

class _CuboidViewState<T extends ChangeNotifier> extends State<CuboidView<T>> {
  late final T viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.viewModelBuilder(context);
    widget.onViewModelReady(viewModel);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => widget.builder(context, viewModel, child),
    );
  }
}
