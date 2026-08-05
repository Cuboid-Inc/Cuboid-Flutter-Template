class PaginatedResult<T> {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;

  const PaginatedResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
  });

  int get totalPages => pageSize <= 0 ? 0 : (totalRecords / pageSize).ceil();
}
