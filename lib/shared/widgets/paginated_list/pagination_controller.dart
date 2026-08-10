import 'package:nemara_homes/core/models/paginated_result.dart';
import 'package:nemara_homes/core/errors/result.dart';
import 'package:flutter/foundation.dart';

/// Controller to manage pagination state and logic for REST API.
class PaginationController<T> {
  final int pageSize;
  final Future<Result<PaginatedResult<T>>> Function(
    int pageNumber,
    int pageSize,
  )
  callback;
  final VoidCallback? onStateChanged;

  List<T> _items = [];
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalRecords = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  _PaginationFailure? _failure;
  bool _isDisposed = false;

  PaginationController({
    required this.callback,
    this.pageSize = 50,
    this.onStateChanged,
  });

  List<T> get items => _items;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalRecords => _totalRecords;
  bool get hasMore => _currentPage < _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get failureMessage => _error;
  bool get hasInitialFailure => _failure == _PaginationFailure.initial;
  bool get hasLoadMoreFailure => _failure == _PaginationFailure.loadMore;
  bool get hasItemsFailure => _failure != null && _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty && !_isLoading;
  bool get isGenuinelyEmpty => isEmpty && !hasInitialFailure;

  void _notify() {
    if (!_isDisposed) onStateChanged?.call();
  }

  Future<void> loadInitial() async {
    _isLoading = true;
    _currentPage = 0;
    _totalPages = 1;
    _totalRecords = 0;
    _items = [];
    _error = null;
    _failure = null;
    _notify();

    final result = await callback(1, pageSize);
    switch (result) {
      case Success<PaginatedResult<T>>(:final value):
        _items = value.items;
        _currentPage = value.pageNumber;
        _totalPages = value.totalPages;
        _totalRecords = value.totalRecords;
        _isLoading = false;
      case Failure<PaginatedResult<T>>(:final failure):
        _error = failure.message;
        _failure = _PaginationFailure.initial;
        _isLoading = false;
    }
    _notify();
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore || _isLoading) return;
    _isLoadingMore = true;
    _error = null;
    _failure = null;
    _notify();

    final result = await callback(_currentPage + 1, pageSize);
    switch (result) {
      case Success<PaginatedResult<T>>(:final value):
        _items.addAll(value.items);
        _currentPage = value.pageNumber;
        _totalPages = value.totalPages;
        _totalRecords = value.totalRecords;
        _isLoadingMore = false;
      case Failure<PaginatedResult<T>>(:final failure):
        _error = failure.message;
        _failure = _PaginationFailure.loadMore;
        _isLoadingMore = false;
    }
    _notify();
  }

  Future<void> refresh() async {
    if (_items.isEmpty) {
      await loadInitial();
      return;
    }
    _isLoading = true;
    _error = null;
    _failure = null;
    _notify();

    final result = await callback(1, pageSize);
    switch (result) {
      case Success<PaginatedResult<T>>(:final value):
        _items = value.items;
        _currentPage = value.pageNumber;
        _totalPages = value.totalPages;
        _totalRecords = value.totalRecords;
        _isLoading = false;
      case Failure<PaginatedResult<T>>(:final failure):
        _error = failure.message;
        _failure = _PaginationFailure.refresh;
        _isLoading = false;
    }
    _notify();
  }

  Future<void> retry() async {
    switch (_failure) {
      case _PaginationFailure.initial:
        await loadInitial();
      case _PaginationFailure.loadMore:
        await loadMore();
      case _PaginationFailure.refresh:
        await refresh();
      case null:
        return;
    }
  }

  void setItems(List<T> newItems) {
    _items = newItems;
    _notify();
  }

  void removeItem(T item) {
    _items.remove(item);
    _totalRecords = (_totalRecords - 1).clamp(0, _totalRecords);
    _notify();
  }

  void updateItem(int index, T newItem) {
    if (index >= 0 && index < _items.length) {
      _items[index] = newItem;
      _notify();
    }
  }

  void prependItem(T item) {
    _items.insert(0, item);
    _totalRecords++;
    _notify();
  }

  void appendItem(T item) {
    _items.add(item);
    _totalRecords++;
    _notify();
  }

  void dispose() {
    _isDisposed = true;
  }
}

enum _PaginationFailure { initial, loadMore, refresh }
