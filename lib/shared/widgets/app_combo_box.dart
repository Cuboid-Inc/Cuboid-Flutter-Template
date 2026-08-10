import 'dart:async';
import 'dart:ui';

import 'package:nemara_homes/core/models/paginated_result.dart';
import 'package:nemara_homes/core/errors/result.dart';
import 'package:nemara_homes/core/theme/app_colors.dart';
import 'package:nemara_homes/core/theme/ui_helpers.dart';
import 'package:nemara_homes/shared/widgets/app_bar_ios.dart';
import 'package:nemara_homes/shared/widgets/empty_state.dart';
import 'package:nemara_homes/shared/widgets/paginated_list/paginated_list_view.dart';
import 'package:nemara_homes/shared/widgets/paginated_list/pagination_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef ComboBoxFetchPage<T> =
    Future<Result<PaginatedResult<T>>> Function({
      required int pageNumber,
      int pageSize,
      String? search,
    });

class AppComboBox<T> extends StatelessWidget {
  const AppComboBox({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.filterFn,
    required this.onChanged,
    this.itemSubtitleBuilder,
    this.placeholder = 'Tap to select...',
    this.addLabel = 'Add New',
    this.onAddPressed,
  }) : fetchPage = null,
       fullScreen = false;

  const AppComboBox.async({
    super.key,
    required this.label,
    required this.value,
    required this.itemLabelBuilder,
    required this.onChanged,
    required this.fetchPage,
    this.itemSubtitleBuilder,
    this.placeholder = 'Tap to select...',
    this.addLabel = 'Add New',
    this.onAddPressed,
    this.fullScreen = false,
  }) : items = null,
       filterFn = null;

  final String label;
  final T? value;
  final List<T>? items;
  final String Function(T) itemLabelBuilder;
  final String Function(T)? itemSubtitleBuilder;
  final bool Function(T, String query)? filterFn;
  final void Function(T?) onChanged;
  final String placeholder;
  final String addLabel;
  final VoidCallback? onAddPressed;
  final ComboBoxFetchPage<T>? fetchPage;
  final bool fullScreen;

  bool get _hasValue => value != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row — shows a clear (×) button inline when a value is selected
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_hasValue) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => onChanged(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clear_thick,
                        size: 10,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSearchSheet(context),
          borderRadius: BorderRadius.circular(radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              // Tinted background when a value is selected
              color: _hasValue
                  ? AppColors.primary.withValues(alpha: 0.01)
                  : AppColors.white,
              border: Border.all(
                color: _hasValue
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
                width: _hasValue ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(radiusMd),
              boxShadow: _hasValue
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x05101828),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _hasValue
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemLabelBuilder(value as T),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (itemSubtitleBuilder != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                itemSubtitleBuilder!(value as T),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          placeholder,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                Icon(
                  _hasValue
                      ? CupertinoIcons.pencil
                      : CupertinoIcons.chevron_down,
                  color: _hasValue
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.mutedLight,
                  size: _hasValue ? 20 : 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchSheet(BuildContext context) {
    final sheet = _SearchSheet<T>(
      label: label,
      selectedValue: value,
      items: items,
      itemLabelBuilder: itemLabelBuilder,
      itemSubtitleBuilder: itemSubtitleBuilder,
      filterFn: filterFn,
      fetchPage: fetchPage,
      fullScreen: fullScreen,
      onChanged: onChanged,
      addLabel: addLabel,
      onAddPressed: onAddPressed,
    );
    if (fullScreen) {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute<void>(builder: (_) => sheet));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => sheet,
    );
  }
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.label,
    required this.selectedValue,
    this.items,
    required this.itemLabelBuilder,
    this.filterFn,
    this.fetchPage,
    required this.fullScreen,
    required this.onChanged,
    required this.addLabel,
    this.itemSubtitleBuilder,
    this.onAddPressed,
  });

  final String label;
  final T? selectedValue;
  final List<T>? items;
  final String Function(T) itemLabelBuilder;
  final String Function(T)? itemSubtitleBuilder;
  final bool Function(T, String query)? filterFn;
  final ComboBoxFetchPage<T>? fetchPage;
  final bool fullScreen;
  final void Function(T?) onChanged;
  final String addLabel;
  final VoidCallback? onAddPressed;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  final _searchController = TextEditingController();
  late final PaginationController<T> _pagination;
  Timer? _debounce;
  String _query = '';

  bool get _isAsync => widget.fetchPage != null;

  @override
  void initState() {
    super.initState();
    if (_isAsync) {
      _pagination = PaginationController<T>(
        callback: (page, size) => widget.fetchPage!(
          pageNumber: page,
          pageSize: size,
          search: _query.isEmpty ? null : _query,
        ),
        onStateChanged: () {
          if (mounted) setState(() {});
        },
      );
      unawaited(_pagination.loadInitial());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    if (_isAsync) _pagination.dispose();
    super.dispose();
  }

  bool _isSelected(T item) {
    if (widget.selectedValue == null) return false;
    if (_isAsync) return item == widget.selectedValue;
    return widget.itemLabelBuilder(item) ==
        widget.itemLabelBuilder(widget.selectedValue as T);
  }

  void _onQueryChanged(String query) {
    if (!_isAsync) {
      setState(() => _query = query);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = query);
      unawaited(_pagination.refresh());
    });
  }

  void _onAddPressed(BuildContext context) {
    Navigator.pop(context);
    widget.onAddPressed!();
  }

  Widget _row(BuildContext context, T item) {
    final selected = _isSelected(item);
    return ListTile(
      onTap: () {
        widget.onChanged(item);
        Navigator.pop(context);
      },
      tileColor: selected ? AppColors.primary.withValues(alpha: 0.06) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: selected
          ? Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.checkmark_alt,
                size: 14,
                color: Colors.white,
              ),
            )
          : Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                shape: BoxShape.circle,
              ),
            ),
      title: Text(
        widget.itemLabelBuilder(item),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.primary : AppColors.ink,
        ),
      ),
      subtitle: widget.itemSubtitleBuilder == null
          ? null
          : Text(
              widget.itemSubtitleBuilder!(item),
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : AppColors.muted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
      trailing: selected
          ? null
          : const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.mutedLight,
              size: 14,
            ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    return EmptyState(
      title: hasQuery
          ? 'No results for "${_searchController.text}"'
          : 'Nothing yet!',
      actionLabel: widget.addLabel,
      onAction: widget.onAddPressed == null
          ? null
          : () => _onAddPressed(context),
    );
  }

  Widget _syncEmptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 44,
            color: AppColors.muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            _searchController.text.trim().isEmpty
                ? 'Nothing yet!'
                : 'No results for "${_searchController.text}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          if (widget.onAddPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () => _onAddPressed(context),
              icon: const Icon(CupertinoIcons.plus, size: 16),
              label: Text(widget.addLabel),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _body({ScrollController? scrollController}) {
    final filteredItems = _isAsync
        ? null
        : widget.items!
              .where((item) => widget.filterFn!(item, _query))
              .toList();
    if (filteredItems != null &&
        _query.isEmpty &&
        widget.selectedValue != null) {
      filteredItems.sort(
        (a, b) => _isSelected(a) ? -1 : (_isSelected(b) ? 1 : 0),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(CupertinoIcons.search, size: 20),
              hintText: 'Search ${widget.label.toLowerCase()}...',
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onQueryChanged('');
                      },
                      child: const Icon(CupertinoIcons.clear_thick, size: 14),
                    )
                  : null,
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _isAsync
              ? PaginatedListView<T>(
                  controller: _pagination,
                  scrollController: scrollController,
                  separator: const Divider(height: 1, color: AppColors.border),
                  emptyWidget: _emptyState(context),
                  itemBuilder: (context, item, _) => _row(context, item),
                )
              : filteredItems!.isEmpty
              ? _syncEmptyState(context)
              : ListView.separated(
                  controller: scrollController,
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) =>
                      _row(context, filteredItems[index]),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return Scaffold(
        appBar: AppBarIOS(title: widget.label),
        body: _body(),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.white.withValues(alpha: 0.95),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Select ${widget.label}',
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: AppColors.mutedLight,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _body(scrollController: scrollController)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
