import 'dart:async';

import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_loading_indicator.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:cuboid_flutter_template/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

// ponytail: controller-only, ListView-only. Add a sliver variant when a
// CustomScrollView screen needs one.
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.onRefresh,
    this.emptyWidget,
    this.loadingWidget,
    this.padding,
    this.scrollController,
    this.separator,
  });

  final PaginationController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onRefresh;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final Widget? separator;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;
  bool _ownsScrollController = false;
  DateTime? _lastLoadMore;

  @override
  void initState() {
    super.initState();
    _attachScrollController(widget.scrollController);
  }

  void _attachScrollController(ScrollController? controller) {
    _scrollController = controller ?? ScrollController();
    _ownsScrollController = controller == null;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _scrollController.removeListener(_onScroll);
      if (_ownsScrollController) _scrollController.dispose();
      _attachScrollController(widget.scrollController);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (widget.controller.hasItemsFailure) return;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset < maxScrollExtent * .9) return;

    final now = DateTime.now();
    if (_lastLoadMore != null &&
        now.difference(_lastLoadMore!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastLoadMore = now;
    unawaited(widget.controller.loadMore());
  }

  Future<void> _refresh() =>
      widget.onRefresh?.call() ?? widget.controller.refresh();

  Widget get _loadingWidget =>
      widget.loadingWidget ?? const AppLoadingIndicator();

  Widget get _emptyWidget =>
      widget.emptyWidget ?? const EmptyState(title: 'No items found');

  Widget _failureWidget({bool compact = false}) => EmptyState(
    title: "Couldn't load items",
    subtitle: widget.controller.failureMessage,
    icon: CupertinoIcons.exclamationmark_triangle_fill,
    iconColor: AppColors.danger,
    compact: compact,
    actionLabel: 'Try again',
    actionIcon: CupertinoIcons.arrow_clockwise,
    onAction: () => unawaited(widget.controller.retry()),
  );

  Widget _refreshableEmpty(Widget child) => RefreshIndicator(
    onRefresh: _refresh,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    ),
  );

  Widget _list() => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount:
          widget.controller.items.length +
          (widget.controller.hasMore || widget.controller.hasItemsFailure
              ? 1
              : 0),
      separatorBuilder: (_, _) => widget.separator ?? const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index >= widget.controller.items.length) {
          if (widget.controller.hasItemsFailure) {
            return _failureWidget(compact: true);
          }
          return _loadingWidget;
        }
        return widget.itemBuilder(
          context,
          widget.controller.items[index],
          index,
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    if (state.isLoading && state.items.isEmpty) return _loadingWidget;
    if (state.hasInitialFailure) return _refreshableEmpty(_failureWidget());
    if (state.isGenuinelyEmpty) return _refreshableEmpty(_emptyWidget);
    return _list();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }
}
